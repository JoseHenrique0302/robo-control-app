import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço de baixo nível para Bluetooth Clássico SPP.
///
/// Stateless wrapper em torno do `flutter_bluetooth_serial`.
/// Responsabilidades:
///  - Listar dispositivos pareados
///  - Conectar/desconectar via RFCOMM
///  - Enviar strings ASCII (com terminação \n)
///  - Receber e acumular bytes até \n, emitindo linhas completas
class BluetoothService {
  FlutterBluetoothSerial get _bt => FlutterBluetoothSerial.instance;

  /// Retorna a lista de dispositivos Bluetooth já **pareados** no Android.
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await _bt.getBondedDevices();
  }

  /// Verifica se o Bluetooth está ligado.
  Future<bool> get isEnabled async => (await _bt.isEnabled) ?? false;

  /// Solicita ligar o Bluetooth (abre dialog do sistema).
  Future<bool?> requestEnable() => _bt.requestEnable();

  /// Solicita as permissões de runtime necessárias para usar Bluetooth.
  ///
  /// O plugin flutter_bluetooth_serial (antigo) exige ACCESS_FINE_LOCATION em
  /// runtime mesmo no Android 12+ — por isso pedimos location além de
  /// bluetoothConnect/Scan. Retorna um [BtPermissionResult] com o que faltou,
  /// para a UI dar uma mensagem precisa.
  Future<BtPermissionResult> requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    final connectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationOk =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    // O Android exige o SERVIÇO de localização (GPS) ligado para varrer/usar BT,
    // além da permissão concedida.
    final locationServiceOn =
        await Permission.location.serviceStatus.isEnabled;

    return BtPermissionResult(
      bluetoothGranted: connectOk,
      locationGranted: locationOk,
      locationServiceOn: locationServiceOn,
    );
  }

  /// Conecta a um dispositivo via RFCOMM SPP.
  ///
  /// Retorna a [BluetoothConnection] ou lança exceção.
  Future<BluetoothConnection> connect(BluetoothDevice device) async {
    return await BluetoothConnection.toAddress(device.address);
  }

  /// Envia um comando ASCII para a conexão aberta.
  ///
  /// Adiciona `\n` automaticamente se [appendNewline] for true (padrão).
  void send(BluetoothConnection connection, String command,
      {bool appendNewline = true}) {
    final data = appendNewline ? '$command\n' : command;
    connection.output.add(Uint8List.fromList(utf8.encode(data)));
  }

  /// Retorna um stream de linhas completas (terminadas em \n) recebidas
  /// via Bluetooth.
  ///
  /// Acumula bytes parciais até encontrar `\n`, depois emite a linha
  /// completa (sem \r\n). Linhas vazias são ignoradas.
  Stream<String> listenLines(BluetoothConnection connection) {
    final controller = StreamController<String>.broadcast();
    final buffer = StringBuffer();

    connection.input?.listen(
      (Uint8List data) {
        final chunk = utf8.decode(data, allowMalformed: true);
        for (int i = 0; i < chunk.length; i++) {
          final char = chunk[i];
          if (char == '\n') {
            final line = buffer.toString().replaceAll('\r', '').trim();
            if (line.isNotEmpty) {
              controller.add(line);
            }
            buffer.clear();
          } else {
            buffer.write(char);
          }
        }
      },
      onError: (error) => controller.addError(error),
      onDone: () => controller.close(),
      cancelOnError: false,
    );

    return controller.stream;
  }
}

/// Resultado do pedido de permissões de Bluetooth, detalhado para a UI.
class BtPermissionResult {
  final bool bluetoothGranted;
  final bool locationGranted;
  final bool locationServiceOn;

  const BtPermissionResult({
    required this.bluetoothGranted,
    required this.locationGranted,
    required this.locationServiceOn,
  });

  /// Tudo pronto para listar/conectar.
  bool get isReady => bluetoothGranted && locationGranted && locationServiceOn;

  /// Mensagem de erro específica, ou null se estiver tudo OK.
  String? get errorMessage {
    if (!bluetoothGranted) {
      return 'Permissão de Bluetooth negada. Conceda nas configurações do app.';
    }
    if (!locationGranted) {
      return 'Conceda a permissão de Localização — o Bluetooth Clássico exige '
          'isso no Android para listar dispositivos.';
    }
    if (!locationServiceOn) {
      return 'Ligue a Localização (GPS) do aparelho. O Android precisa dela '
          'ligada para usar o Bluetooth Clássico.';
    }
    return null;
  }
}

/// Alias para facilitar acesso à instância singleton do plugin.
typedef FluetoothInstance = FlutterBluetoothSerial;
