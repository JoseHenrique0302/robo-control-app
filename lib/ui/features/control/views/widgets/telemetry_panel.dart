import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:robo_control_app/domain/models/telemetry.dart';
import 'package:robo_control_app/ui/core/theme.dart';
import 'package:robo_control_app/ui/core/widgets/battery_indicator.dart';
import 'package:robo_control_app/ui/core/widgets/status_badge.dart';

/// Painel compacto de telemetria recebida do robô.
///
/// Exibe X, Y, θ, V, bateria, modo, calibração com layout em grid.
class TelemetryPanel extends StatelessWidget {
  final Telemetry telemetry;

  const TelemetryPanel({super.key, required this.telemetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassDecoration(opacity: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header com modo + calibração + bateria
          Row(
            children: [
              const Icon(Icons.sensors, color: AppTheme.accent, size: 16),
              const SizedBox(width: 6),
              const Text(
                'TELEMETRIA',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: telemetry.mode == RobotMode.autonomous
                    ? 'AUTO'
                    : 'MANUAL',
                icon: telemetry.mode == RobotMode.autonomous
                    ? Icons.smart_toy
                    : Icons.gamepad,
                color: telemetry.mode == RobotMode.autonomous
                    ? AppTheme.autoBlue
                    : AppTheme.manualOrange,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dados em grid
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'X',
                  value: telemetry.x.toStringAsFixed(3),
                  unit: 'm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Y',
                  value: telemetry.y.toStringAsFixed(3),
                  unit: 'm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'θ',
                  value: _formatAngle(telemetry.theta),
                  unit: '°',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Vel',
                  value: telemetry.velocity.toStringAsFixed(2),
                  unit: 'm/s',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Dist',
                  value: telemetry.distance.toStringAsFixed(2),
                  unit: 'm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'V̄',
                  value: telemetry.velocityAvg.toStringAsFixed(2),
                  unit: 'm/s',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bateria + Calibração
          Row(
            children: [
              BatteryIndicator(level: telemetry.battery),
              const SizedBox(width: 10),
              StatusBadge(
                label: telemetry.calibrated ? 'Calibrado' : 'Não calibrado',
                icon: telemetry.calibrated
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: telemetry.calibrated
                    ? AppTheme.calibrateGreen
                    : AppTheme.batteryYellow,
                pulse: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Converte radianos para graus formatados.
  String _formatAngle(double radians) {
    return (radians * 180 / math.pi).toStringAsFixed(1);
  }
}

/// Tile individual de métrica.
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
