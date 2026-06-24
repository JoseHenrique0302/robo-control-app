import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:robo_control_app/data/repositories/robot_repository.dart';
import 'package:robo_control_app/data/services/bluetooth_service.dart';
import 'package:robo_control_app/domain/models/connection_state.dart';

/// ViewModel para a tela de conexão Bluetooth.
///
/// Gerencia scan de dispositivos pareados, conexão/desconexão e estado.
class ConnectionViewModel extends ChangeNotifier {
  final RobotRepository _repository;

  ConnectionViewModel({required RobotRepository repository})
      : _repository = repository {
    _connectionSub =
        _repository.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  // ── Estado ─────────────────────────────────────────────────────────

  BtConnectionState _connectionState = BtConnectionState.disconnected;
  BtConnectionState get connectionState => _connectionState;

  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> get devices => List.unmodifiable(_devices);

  BluetoothDevice? _selectedDevice;
  BluetoothDevice? get selectedDevice => _selectedDevice;

  String? _error;
  String? get error => _error;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  StreamSubscription<BtConnectionState>? _connectionSub;

  // ── Ações ──────────────────────────────────────────────────────────

  /// Lista os dispositivos Bluetooth já pareados no Android.
  Future<void> scanDevices() async {
    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      // Permissões de runtime (BT + localização) e GPS ligado — exigidos pelo
      // plugin/ Android antes de listar dispositivos Bluetooth.
      final BtPermissionResult perm =
          await _repository.requestBluetoothPermissions();
      if (!perm.isReady) {
        _error = perm.errorMessage;
        return;
      }

      // Verifica se o BT está ligado
      final enabled = await _repository.isBluetoothEnabled;
      if (!enabled) {
        await _repository.requestEnable();
      }

      _devices = await _repository.getBondedDevices();
    } catch (e) {
      _error = 'Erro ao listar dispositivos: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Conecta ao dispositivo selecionado.
  Future<void> connectToDevice(BluetoothDevice device) async {
    _selectedDevice = device;
    _error = null;
    notifyListeners();

    try {
      await _repository.connect(device);
    } catch (e) {
      _error = 'Falha ao conectar: $e';
      notifyListeners();
    }
  }

  /// Desconecta do dispositivo atual.
  Future<void> disconnect() async {
    await _repository.disconnect();
    _selectedDevice = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }
}
