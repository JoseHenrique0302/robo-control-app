// Smoke test: garante que o app inicializa sem erros e exibe a tela
// de conexão Bluetooth, que é a tela inicial do RoboControlApp.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:robo_control_app/app.dart';
import 'package:robo_control_app/data/repositories/robot_repository.dart';
import 'package:robo_control_app/data/services/bluetooth_service.dart';
import 'package:robo_control_app/ui/features/connection/view_models/connection_view_model.dart';
import 'package:robo_control_app/ui/features/control/view_models/control_view_model.dart';
import 'package:robo_control_app/ui/features/pid/view_models/pid_view_model.dart';

void main() {
  testWidgets('App inicia exibindo a tela de conexão', (tester) async {
    final robotRepository = RobotRepository(btService: BluetoothService());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RobotRepository>.value(value: robotRepository),
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
    // Não usa pumpAndSettle: o auto-scan da ConnectionScreen chama os
    // plugins de Bluetooth/permissão, que não têm mock de platform channel
    // neste teste e por isso nunca respondem. Alguns pumps bastam para
    // renderizar o conteúdo estático da tela.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Conectar ao Robô'), findsOneWidget);
    expect(find.text('PROCURAR DISPOSITIVOS'), findsOneWidget);
  });
}
