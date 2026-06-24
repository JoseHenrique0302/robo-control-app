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

  /// Solicita as permissões de runtime necessárias para usar Bluetooth
  /// no Android 12+ (BLUETOOTH_CONNECT, BLUETOOTH_SCAN e localização).
  ///
  /// Retorna true apenas se [Permission.bluetoothConnect] for concedida,
  /// que é a permissão exigida antes de chamar [requestEnable] ou
  /// [getBondedDevices] em dispositivos com Android 12+.
  Future<bool> requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    return statuses[Permission.bluetoothConnect]?.isGranted ?? false;
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

/// Alias para facilitar acesso à instância singleton do plugin.
typedef FluetoothInstance = FlutterBluetoothSerial;
