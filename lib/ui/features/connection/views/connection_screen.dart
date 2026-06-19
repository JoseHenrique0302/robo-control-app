import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:robo_control_app/domain/models/connection_state.dart';
import 'package:robo_control_app/ui/core/theme.dart';
import 'package:robo_control_app/ui/core/widgets/status_badge.dart';
import 'package:robo_control_app/ui/features/connection/view_models/connection_view_model.dart';

/// Tela de conexão Bluetooth.
///
/// Lista dispositivos pareados e permite conectar ao HC-05.
class ConnectionScreen extends StatefulWidget {
  /// Callback chamado após conexão bem-sucedida.
  final VoidCallback onConnected;

  const ConnectionScreen({super.key, required this.onConnected});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Auto-scan ao entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionViewModel>().scanDevices();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Consumer<ConnectionViewModel>(
            builder: (context, vm, _) {
              // Navega para a tela de controle ao conectar
              if (vm.connectionState == BtConnectionState.connected) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onConnected();
                });
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(vm)),
                  SliverToBoxAdapter(child: _buildStatus(vm)),
                  if (vm.error != null)
                    SliverToBoxAdapter(child: _buildError(vm.error!)),
                  if (vm.isScanning)
                    const SliverToBoxAdapter(child: _ScanningIndicator()),
                  if (vm.devices.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _DeviceCard(device: vm.devices[index], vm: vm),
                          childCount: vm.devices.length,
                        ),
                      ),
                    ),
                  if (!vm.isScanning && vm.devices.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyState()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ConnectionViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone do robô com glow
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withOpacity(0.2),
                  AppTheme.accent.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.bluetooth,
              color: AppTheme.accent,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Conectar ao Robô',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione o módulo HC-05 na lista de dispositivos pareados.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  vm.connectionState == BtConnectionState.connecting
                      ? null
                      : () => vm.scanDevices(),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('PROCURAR DISPOSITIVOS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(ConnectionViewModel vm) {
    final (label, icon, color, pulse) = switch (vm.connectionState) {
      BtConnectionState.disconnected => (
          'Desconectado',
          Icons.bluetooth_disabled,
          AppTheme.textDim,
          false,
        ),
      BtConnectionState.connecting => (
          'Conectando…',
          Icons.bluetooth_searching,
          AppTheme.manualOrange,
          true,
        ),
      BtConnectionState.connected => (
          'Conectado',
          Icons.bluetooth_connected,
          AppTheme.calibrateGreen,
          true,
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          StatusBadge(label: label, icon: icon, color: color, pulse: pulse),
          if (vm.selectedDevice != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vm.selectedDevice!.name ?? vm.selectedDevice!.address,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (vm.connectionState == BtConnectionState.connected) ...[
            const Spacer(),
            TextButton(
              onPressed: () => vm.disconnect(),
              child: const Text(
                'DESCONECTAR',
                style: TextStyle(color: AppTheme.stopRed, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.stopRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.stopRed.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.stopRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: AppTheme.stopRed, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de um dispositivo Bluetooth pareado.
class _DeviceCard extends StatelessWidget {
  final dynamic device; // BluetoothDevice
  final ConnectionViewModel vm;

  const _DeviceCard({required this.device, required this.vm});

  @override
  Widget build(BuildContext context) {
    final isConnecting =
        vm.connectionState == BtConnectionState.connecting &&
            vm.selectedDevice?.address == device.address;
    final isConnected =
        vm.connectionState == BtConnectionState.connected &&
            vm.selectedDevice?.address == device.address;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isConnecting || isConnected
              ? null
              : () => vm.connectToDevice(device),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.calibrateGreen.withOpacity(0.08)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected
                    ? AppTheme.calibrateGreen.withOpacity(0.3)
                    : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isConnected
                            ? AppTheme.calibrateGreen
                            : AppTheme.accent)
                        .withOpacity(0.12),
                  ),
                  child: Icon(
                    isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                    color:
                        isConnected ? AppTheme.calibrateGreen : AppTheme.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name ?? 'Dispositivo desconhecido',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.address,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  )
                else if (isConnected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.calibrateGreen,
                    size: 22,
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textDim,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador de scanning.
class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.accent,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Buscando dispositivos…',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio quando não há dispositivos.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.textDim.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.bluetooth_disabled,
                color: AppTheme.textDim,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum dispositivo encontrado',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Certifique-se de que o HC-05 está pareado\nnas configurações do Android.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textDim, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
