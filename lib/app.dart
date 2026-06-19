import 'package:flutter/material.dart';

import 'package:robo_control_app/ui/core/theme.dart';
import 'package:robo_control_app/ui/features/connection/views/connection_screen.dart';
import 'package:robo_control_app/ui/features/control/views/control_screen.dart';
import 'package:robo_control_app/ui/features/pid/views/pid_screen.dart';

/// Root widget do app com tema e navegação.
class RoboControlApp extends StatelessWidget {
  const RoboControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robô Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppNavigator(),
    );
  }
}

/// Navegador principal que gerencia o fluxo:
/// Connection → Control → PID
class _AppNavigator extends StatelessWidget {
  const _AppNavigator();

  @override
  Widget build(BuildContext context) {
    return ConnectionScreen(
      onConnected: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ControlScreen(
              onNavigateToPid: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PidScreen()),
                );
              },
              onDisconnect: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const _AppNavigator(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
