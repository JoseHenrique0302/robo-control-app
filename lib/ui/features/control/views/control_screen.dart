import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:robo_control_app/ui/core/theme.dart';
import 'package:robo_control_app/ui/features/control/view_models/control_view_model.dart';
import 'package:robo_control_app/ui/features/control/views/widgets/joystick_pad.dart';
import 'package:robo_control_app/ui/features/control/views/widgets/telemetry_panel.dart';

/// Tela principal de controle do robô.
///
/// Layout:
///  - Portrait: telemetria no topo, botões no meio, joystick embaixo
///  - Landscape: telemetria à esquerda, joystick + botões à direita
class ControlScreen extends StatelessWidget {
  final VoidCallback onNavigateToPid;
  final VoidCallback onDisconnect;

  const ControlScreen({
    super.key,
    required this.onNavigateToPid,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle'),
        leading: IconButton(
          icon: const Icon(Icons.bluetooth_disabled, size: 20),
          tooltip: 'Desconectar',
          onPressed: onDisconnect,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: 'Configurar PID',
            onPressed: onNavigateToPid,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > 600;
            return isLandscape
                ? _LandscapeLayout(
                    onNavigateToPid: onNavigateToPid,
                  )
                : _PortraitLayout(
                    onNavigateToPid: onNavigateToPid,
                  );
          },
        ),
      ),
    );
  }
}

// ── Portrait Layout ─────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  final VoidCallback onNavigateToPid;

  const _PortraitLayout({required this.onNavigateToPid});

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlViewModel>(
      builder: (context, vm, _) {
        return Column(
          children: [
            // Telemetria
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TelemetryPanel(telemetry: vm.telemetry),
            ),

            // Botões de modo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ModeButtons(vm: vm),
            ),

            const Spacer(),

            // Joystick
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: JoystickPad(
                size: 180,
                onStickUpdate: vm.updateJoystick,
                onStickRelease: vm.releaseJoystick,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Landscape Layout ────────────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  final VoidCallback onNavigateToPid;

  const _LandscapeLayout({required this.onNavigateToPid});

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlViewModel>(
      builder: (context, vm, _) {
        return Row(
          children: [
            // Lado esquerdo: telemetria + botões
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TelemetryPanel(telemetry: vm.telemetry),
                    const SizedBox(height: 12),
                    _ModeButtons(vm: vm),
                  ],
                ),
              ),
            ),

            // Divider vertical
            Container(
              width: 1,
              color: AppTheme.border,
            ),

            // Lado direito: joystick
            Expanded(
              flex: 4,
              child: Center(
                child: JoystickPad(
                  size: 200,
                  onStickUpdate: vm.updateJoystick,
                  onStickRelease: vm.releaseJoystick,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Botões de modo ──────────────────────────────────────────────────

class _ModeButtons extends StatelessWidget {
  final ControlViewModel vm;

  const _ModeButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // STOP (emergência) — sempre grande e visível
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: vm.sendStop,
            icon: const Icon(Icons.power_settings_new, size: 22),
            label: const Text(
              'PARADA DE EMERGÊNCIA',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.stopRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: AppTheme.stopRed.withOpacity(0.3),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // MANUAL, AUTO, CALIBRAR
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'MANUAL',
                icon: Icons.gamepad,
                color: AppTheme.manualOrange,
                isActive: vm.isManualMode,
                onPressed: vm.sendManual,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeButton(
                label: 'AUTO',
                icon: Icons.smart_toy,
                color: AppTheme.autoBlue,
                isActive: !vm.isManualMode,
                onPressed: vm.sendAuto,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeButton(
                label: 'CALIBRAR',
                icon: Icons.tune,
                color: AppTheme.calibrateGreen,
                isActive: false,
                onPressed: vm.sendCalibrate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color.withOpacity(0.5) : AppTheme.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? color : AppTheme.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? color : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
