import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

import 'package:robo_control_app/ui/core/theme.dart';

/// Joystick virtual analógico com visual customizado.
///
/// Converte os eixos (x, y) do widget em saída para o ViewModel.
/// O callback [onStickUpdate] é chamado com (x, y) em [-1, 1].
/// O callback [onStickRelease] é chamado ao soltar.
class JoystickPad extends StatelessWidget {
  final void Function(double x, double y) onStickUpdate;
  final VoidCallback onStickRelease;
  final double size;

  const JoystickPad({
    super.key,
    required this.onStickUpdate,
    required this.onStickRelease,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gamepad, color: AppTheme.accent, size: 14),
            SizedBox(width: 6),
            Text(
              'JOYSTICK',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Joystick com visual customizado
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.08),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Joystick(
            mode: JoystickMode.all,
            period: const Duration(milliseconds: 50),
            listener: (details) {
              // flutter_joystick: x = horizontal, y = vertical
              // y é invertido no widget (cima = negativo), corrigimos aqui
              onStickUpdate(details.x, -details.y);
            },
            onStickDragEnd: onStickRelease,
            base: _JoystickBase(size: size),
            stick: _JoystickStick(size: size * 0.35),
          ),
        ),
      ],
    );
  }
}

/// Base visual do joystick.
class _JoystickBase extends StatelessWidget {
  final double size;
  const _JoystickBase({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.surfaceLight,
            AppTheme.surface,
          ],
        ),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CrosshairPainter(),
      ),
    );
  }
}

/// Stick (bolinha) do joystick.
class _JoystickStick extends StatelessWidget {
  final double size;
  const _JoystickStick({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.accent.withOpacity(0.9),
            AppTheme.accent.withOpacity(0.6),
          ],
          center: const Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Pintor de crosshair na base do joystick.
class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Linhas cruzadas
    canvas.drawLine(
      Offset(size.width * 0.2, center.dy),
      Offset(size.width * 0.8, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, size.height * 0.2),
      Offset(center.dx, size.height * 0.8),
      paint,
    );

    // Círculos concêntricos
    canvas.drawCircle(center, size.width * 0.25, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
