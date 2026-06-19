import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:robo_control_app/ui/core/theme.dart';
import 'package:robo_control_app/ui/features/pid/view_models/pid_view_model.dart';

/// Tela de configuração dos ganhos PID do controlador do robô.
///
/// Permite ler os valores atuais (GET_PID) e definir novos (SET_PID).
class PidScreen extends StatelessWidget {
  const PidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração PID'),
      ),
      body: SafeArea(
        child: Consumer<PidViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: glassDecoration(opacity: 0.06),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent.withOpacity(0.12),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: AppTheme.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ganhos do PID',
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ajuste Kp, Ki e Kd do controlador de linha.',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kp
                  _PidSliderField(
                    label: 'Kp (Proporcional)',
                    value: vm.kp,
                    color: AppTheme.accent,
                    min: 0,
                    max: 5.0,
                    onChanged: vm.setKp,
                  ),
                  const SizedBox(height: 16),

                  // Ki
                  _PidSliderField(
                    label: 'Ki (Integral)',
                    value: vm.ki,
                    color: AppTheme.autoBlue,
                    min: 0,
                    max: 2.0,
                    onChanged: vm.setKi,
                  ),
                  const SizedBox(height: 16),

                  // Kd
                  _PidSliderField(
                    label: 'Kd (Derivativo)',
                    value: vm.kd,
                    color: AppTheme.calibrateGreen,
                    min: 0,
                    max: 2.0,
                    onChanged: vm.setKd,
                  ),
                  const SizedBox(height: 28),

                  // Botões Enviar + Ler
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: vm.sendPid,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: vm.sent
                                  ? const Icon(Icons.check, key: ValueKey('check'))
                                  : const Icon(Icons.send, key: ValueKey('send'), size: 18),
                            ),
                            label: Text(vm.sent ? 'ENVIADO!' : 'ENVIAR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vm.sent
                                  ? AppTheme.calibrateGreen
                                  : AppTheme.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: vm.isLoading ? null : vm.readPid,
                            icon: vm.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.accent,
                                    ),
                                  )
                                : const Icon(Icons.download, size: 18),
                            label: Text(
                              vm.isLoading ? 'LENDO…' : 'LER ATUAIS',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Valores atuais do robô
                  if (vm.currentGains != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: glassDecoration(opacity: 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppTheme.textDim, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'VALORES ATUAIS NO ROBÔ',
                                style: TextStyle(
                                  color: AppTheme.textDim,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _ReadonlyGain(
                                  label: 'Kp',
                                  value: vm.currentGains!.kp,
                                  color: AppTheme.accent),
                              const SizedBox(width: 10),
                              _ReadonlyGain(
                                  label: 'Ki',
                                  value: vm.currentGains!.ki,
                                  color: AppTheme.autoBlue),
                              const SizedBox(width: 10),
                              _ReadonlyGain(
                                  label: 'Kd',
                                  value: vm.currentGains!.kd,
                                  color: AppTheme.calibrateGreen),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Campo de ajuste PID com slider + input numérico.
class _PidSliderField extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _PidSliderField({
    required this.label,
    required this.value,
    required this.color,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) * 100).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Exibição readonly de um ganho PID.
class _ReadonlyGain extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ReadonlyGain({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
