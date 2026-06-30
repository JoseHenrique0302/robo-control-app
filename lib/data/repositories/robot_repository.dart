import 'dart:async';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:robo_control_app/data/services/bluetooth_service.dart';
import 'package:robo_control_app/domain/models/connection_state.dart';
import 'package:robo_control_app/domain/models/pid_gains.dart';
import 'package:robo_control_app/domain/models/telemetry.dart';

/// Repositório de alto nível para comunicação com o robô.
///
/// Consome [BluetoothService] e expõe:
///  - Comandos tipados (motor, modo, PID, etc.)
///  - Streams de telemetria e resposta PID
///  - Estado da conexão
class RobotRepository {
  final BluetoothService _btService;

  RobotRepository({required BluetoothService btService})
      : _btService = btService;

  BluetoothConnection? _connection;
  StreamSubscription<String>? _lineSubscription;

  // ── Streams de saída ──────────────────────────────────────────────

  final _telemetryController = StreamController<Telemetry>.broadcast();
  final _pidController = StreamController<PidGains>.broadcast();
  final _connectionStateController =
      StreamController<BtConnectionState>.broadcast();
  final _rawLineController = StreamController<String>.broadcast();

  /// Stream de telemetria parseada (a cada ~1 s do robô).
  Stream<Telemetry> get telemetryStream => _telemetryController.stream;

  /// Stream de respostas PID (após `GET_PID`).
  Stream<PidGains> get pidStream => _pidController.stream;

  /// Stream do estado da conexão Bluetooth.
  Stream<BtConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream de todas as linhas recebidas (para debug).
  Stream<String> get rawLineStream => _rawLineController.stream;

  /// Se há uma conexão ativa.
  bool get isConnected => _connection != null;

  // ── Conexão ───────────────────────────────────────────────────────

  /// Lista dispositivos pareados.
  Future<List<BluetoothDevice>> getBondedDevices() =>
      _btService.getBondedDevices();

  /// Verifica se o Bluetooth está ligado.
  Future<bool> get isBluetoothEnabled => _btService.isEnabled;

  /// Solicita ligar Bluetooth.
  Future<bool?> requestEnable() => _btService.requestEnable();

  /// Solicita as permissões de runtime necessárias para usar Bluetooth.
  Future<BtPermissionResult> requestBluetoothPermissions() =>
      _btService.requestBluetoothPermissions();

  /// Conecta a um dispositivo. Emite estado via [connectionStateStream].
  Future<void> connect(BluetoothDevice device) async {
    _connectionStateController.add(BtConnectionState.connecting);
    try {
      _connection = await _btService.connect(device);
      _connectionStateController.add(BtConnectionState.connected);
      _startListening();
    } catch (e) {
      _connectionStateController.add(BtConnectionState.disconnected);
      rethrow;
    }
  }

  /// Desconecta e limpa recursos.
  Future<void> disconnect() async {
    await _lineSubscription?.cancel();
    _lineSubscription = null;
    try {
      await _connection?.finish();
    } catch (_) {}
    _connection = null;
    _connectionStateController.add(BtConnectionState.disconnected);
  }

  void _startListening() {
    if (_connection == null) return;

    _lineSubscription = _btService.listenLines(_connection!).listen(
      (line) {
        _rawLineController.add(line);
        _parseLine(line);
      },
      onError: (e) {
        disconnect();
      },
      onDone: () {
        disconnect();
      },
    );
  }

  /// Parse robusto: tenta telemetria e PID, ignora lixo.
  void _parseLine(String line) {
    // Tenta PID primeiro (resposta ao GET_PID)
    final pid = PidGains.tryParse(line);
    if (pid != null) {
      _pidController.add(pid);
      return;
    }

    // Tenta telemetria
    final telemetry = Telemetry.tryParse(line);
    if (telemetry != null) {
      _telemetryController.add(telemetry);
      return;
    }

    // Linha desconhecida — ignora (pode ser lixo parcial)
  }

  // ── Comandos ──────────────────────────────────────────────────────

  void _send(String command) {
    if (_connection == null) return;
    unawaited(_btService.send(_connection!, command));
  }

  /// Envia `MANUAL\n` — entra em modo manual.
  void sendManual() => _send('MANUAL');

  /// Envia `AUTO\n` — entra em modo autônomo (seguir linha).
  void sendAuto() => _send('AUTO');

  /// Envia `STOP\n` — para os motores imediatamente.
  void sendStop() => _send('STOP');

  /// Envia `CALIBRATE\n` — inicia calibração dos sensores.
  void sendCalibrate() => _send('CALIBRATE');

  /// Envia `MOTOR <esq> <dir>\n`.
  ///
  /// [left] e [right] devem estar em [-1.0, 1.0].
  void sendMotor(double left, double right) {
    final l = left.clamp(-1.0, 1.0).toStringAsFixed(2);
    final r = right.clamp(-1.0, 1.0).toStringAsFixed(2);
    _send('MOTOR $l $r');
  }

  /// Envia `SET_PID <kp> <ki> <kd>\n`.
  void sendSetPid(double kp, double ki, double kd) {
    _send(
        'SET_PID ${kp.toStringAsFixed(2)} ${ki.toStringAsFixed(2)} ${kd.toStringAsFixed(2)}');
  }

  /// Envia `GET_PID\n`.
  void sendGetPid() => _send('GET_PID');

  // ── Limpeza ───────────────────────────────────────────────────────

  /// Libera todos os recursos. Chamar ao sair do app.
  Future<void> dispose() async {
    await disconnect();
    await _telemetryController.close();
    await _pidController.close();
    await _connectionStateController.close();
    await _rawLineController.close();
  }
}
