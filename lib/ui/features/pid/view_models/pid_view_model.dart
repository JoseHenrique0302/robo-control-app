import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:robo_control_app/data/repositories/robot_repository.dart';
import 'package:robo_control_app/domain/models/pid_gains.dart';

/// ViewModel para a tela de configuração PID.
///
/// Gerencia leitura (GET_PID) e escrita (SET_PID) dos ganhos do controlador.
class PidViewModel extends ChangeNotifier {
  final RobotRepository _repository;

  PidViewModel({required RobotRepository repository})
      : _repository = repository {
    _pidSub = _repository.pidStream.listen((gains) {
      _currentGains = gains;
      _kp = gains.kp;
      _ki = gains.ki;
      _kd = gains.kd;
      _isLoading = false;
      notifyListeners();
    });
  }

  // ── Estado ─────────────────────────────────────────────────────────

  PidGains? _currentGains;
  PidGains? get currentGains => _currentGains;

  double _kp = 0.50;
  double get kp => _kp;

  double _ki = 0.00;
  double get ki => _ki;

  double _kd = 0.10;
  double get kd => _kd;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _sent = false;
  bool get sent => _sent;

  StreamSubscription<PidGains>? _pidSub;

  // ── Ações ──────────────────────────────────────────────────────────

  void setKp(double value) {
    _kp = value;
    _sent = false;
    notifyListeners();
  }

  void setKi(double value) {
    _ki = value;
    _sent = false;
    notifyListeners();
  }

  void setKd(double value) {
    _kd = value;
    _sent = false;
    notifyListeners();
  }

  /// Envia `SET_PID <kp> <ki> <kd>\n`.
  void sendPid() {
    _repository.sendSetPid(_kp, _ki, _kd);
    _sent = true;
    notifyListeners();

    // Reset feedback visual após 2s
    Future.delayed(const Duration(seconds: 2), () {
      _sent = false;
      notifyListeners();
    });
  }

  /// Envia `GET_PID\n` e aguarda a resposta via stream.
  void readPid() {
    _isLoading = true;
    notifyListeners();
    _repository.sendGetPid();

    // Timeout de 3s se o robô não responder
    Future.delayed(const Duration(seconds: 3), () {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _pidSub?.cancel();
    super.dispose();
  }
}
