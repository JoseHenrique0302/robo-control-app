import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:robo_control_app/data/repositories/robot_repository.dart';
import 'package:robo_control_app/domain/models/connection_state.dart';
import 'package:robo_control_app/domain/models/telemetry.dart';

/// ViewModel para a tela de controle (joystick + botões + telemetria).
///
/// Gerencia:
///  - Envio de comandos de motor via joystick (com throttle de ~100 ms)
///  - Botões de modo: MANUAL, AUTO, STOP, CALIBRATE
///  - Recepção e exposição da telemetria
class ControlViewModel extends ChangeNotifier {
  final RobotRepository _repository;

  ControlViewModel({required RobotRepository repository})
      : _repository = repository {
    _telemetrySub = _repository.telemetryStream.listen((t) {
      _telemetry = t;
      notifyListeners();
    });
    _connectionSub = _repository.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  // ── Estado ─────────────────────────────────────────────────────────

  Telemetry _telemetry = Telemetry.empty;
  Telemetry get telemetry => _telemetry;

  BtConnectionState _connectionState = BtConnectionState.disconnected;
  BtConnectionState get connectionState => _connectionState;

  bool _isManualMode = false;
  bool get isManualMode => _isManualMode;

  bool _joystickActive = false;
  bool get joystickActive => _joystickActive;

  StreamSubscription<Telemetry>? _telemetrySub;
  StreamSubscription<BtConnectionState>? _connectionSub;
  Timer? _motorThrottle;

  double _lastLeft = 0;
  double _lastRight = 0;

  // ── Joystick ───────────────────────────────────────────────────────

  /// Atualiza os valores do joystick e envia MOTOR com throttle ~100 ms.
  ///
  /// [x] = eixo horizontal (-1 esquerda, +1 direita)
  /// [y] = eixo vertical (-1 baixo, +1 cima)
  ///
  /// Mistura diferencial:
  ///   esq  = clamp(y + x, -1, 1)
  ///   dir  = clamp(y - x, -1, 1)
  void updateJoystick(double x, double y) {
    // Garante modo manual antes do primeiro envio
    if (!_joystickActive) {
      _joystickActive = true;
      if (!_isManualMode) {
        sendManual();
      }
    }

    _lastLeft = (y + x).clamp(-1.0, 1.0);
    _lastRight = (y - x).clamp(-1.0, 1.0);

    // Throttle: envia no máximo a cada 100 ms
    _motorThrottle ??= Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _sendMotor(),
    );
  }

  void _sendMotor() {
    _repository.sendMotor(_lastLeft, _lastRight);
  }

  /// Chamado quando o joystick é solto.
  void releaseJoystick() {
    _joystickActive = false;
    _motorThrottle?.cancel();
    _motorThrottle = null;
    _lastLeft = 0;
    _lastRight = 0;
    _repository.sendStop();
    notifyListeners();
  }

  // ── Botões de modo ────────────────────────────────────────────────

  void sendManual() {
    _isManualMode = true;
    _repository.sendManual();
    notifyListeners();
  }

  void sendAuto() {
    _isManualMode = false;
    // Cancela joystick se ativo
    if (_joystickActive) {
      _motorThrottle?.cancel();
      _motorThrottle = null;
      _joystickActive = false;
    }
    _repository.sendAuto();
    notifyListeners();
  }

  void sendStop() {
    _repository.sendStop();
    // Cancela joystick
    _motorThrottle?.cancel();
    _motorThrottle = null;
    _joystickActive = false;
    notifyListeners();
  }

  void sendCalibrate() {
    _repository.sendCalibrate();
  }

  // ── Limpeza ────────────────────────────────────────────────────────

  @override
  void dispose() {
    _motorThrottle?.cancel();
    _telemetrySub?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }
}
