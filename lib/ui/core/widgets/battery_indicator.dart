import 'package:flutter/material.dart';
import 'package:robo_control_app/ui/core/theme.dart';

/// Indicador visual de nível de bateria.
///
/// Exibe ícone de bateria + porcentagem com cor baseada no nível:
/// - ≥60% → verde
/// - ≥30% → amarelo
/// - <30% → vermelho
class BatteryIndicator extends StatelessWidget {
  final int level;

  const BatteryIndicator({super.key, required this.level});

  Color get _color {
    if (level >= 60) return AppTheme.batteryGreen;
    if (level >= 30) return AppTheme.batteryYellow;
    return AppTheme.batteryRed;
  }

  IconData get _icon {
    if (level >= 90) return Icons.battery_full;
    if (level >= 60) return Icons.battery_5_bar;
    if (level >= 40) return Icons.battery_4_bar;
    if (level >= 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 18),
          const SizedBox(width: 4),
          Text(
            '$level%',
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
