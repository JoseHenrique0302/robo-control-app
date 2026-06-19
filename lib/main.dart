// App Android para controle do robô seguidor de linha via Bluetooth Clássico SPP.
//
// Protocolo (ASCII + '\n'):
//   Envia: MANUAL | AUTO | MOTOR <esq> <dir> | STOP |
//          CALIBRATE | SET_PID <kp> <ki> <kd> | GET_PID
//   Recebe (1/s): X=.. Y=.. Th=.. V=.. Vavg=.. Dist=.. Bat=..% Mode=.. Calib=..
//
// Stack: Flutter + flutter_bluetooth_serial (SPP) + flutter_joystick + provider

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:robo_control_app/app.dart';
import 'package:robo_control_app/data/repositories/robot_repository.dart';
import 'package:robo_control_app/data/services/bluetooth_service.dart';
import 'package:robo_control_app/ui/features/connection/view_models/connection_view_model.dart';
import 'package:robo_control_app/ui/features/control/view_models/control_view_model.dart';
import 'package:robo_control_app/ui/features/pid/view_models/pid_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar transparente para visual premium
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1117),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Injeção de dependências ────────────────────────────────────────
  final bluetoothService = BluetoothService();
  final robotRepository = RobotRepository(btService: bluetoothService);

  runApp(
    MultiProvider(
      providers: [
        // Repositório compartilhado
        Provider<RobotRepository>.value(value: robotRepository),

        // ViewModels
        ChangeNotifierProvider(
          create: (_) => ConnectionViewModel(repository: robotRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ControlViewModel(repository: robotRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => PidViewModel(repository: robotRepository),
        ),
      ],
      child: const RoboControlApp(),
    ),
  );
}
