/// Modo de operação do robô.
enum RobotMode {
  manual,   // Mode=0
  autonomous, // Mode=1
}

/// Dados de telemetria recebidos do robô a cada ~1 segundo.
///
/// Formato da linha:
/// ```
/// X=0.12 Y=-0.03 Th=0.45 V=0.20 Vavg=0.18 Dist=1.34 Bat=87% Mode=0 Calib=1
/// ```
class Telemetry {
  final double x;
  final double y;
  final double theta;
  final double velocity;
  final double velocityAvg;
  final double distance;
  final int battery;
  final RobotMode mode;
  final bool calibrated;

  const Telemetry({
    required this.x,
    required this.y,
    required this.theta,
    required this.velocity,
    required this.velocityAvg,
    required this.distance,
    required this.battery,
    required this.mode,
    required this.calibrated,
  });

  /// Valores padrão (tudo zerado, desconectado).
  static const Telemetry empty = Telemetry(
    x: 0,
    y: 0,
    theta: 0,
    velocity: 0,
    velocityAvg: 0,
    distance: 0,
    battery: 0,
    mode: RobotMode.manual,
    calibrated: false,
  );

  /// Tenta parsear uma linha de telemetria.
  /// Retorna `null` se a linha não casar com o formato esperado.
  ///
  /// Parsing robusto: separa por espaços e por `=`, ignora campos ausentes
  /// usando valores padrão.
  static Telemetry? tryParse(String line) {
    final trimmed = line.trim();
    // Verifica presença mínima de campos-chave
    if (!trimmed.contains('X=') || !trimmed.contains('Y=')) return null;

    final fields = <String, String>{};
    for (final token in trimmed.split(RegExp(r'\s+'))) {
      final eqIdx = token.indexOf('=');
      if (eqIdx > 0 && eqIdx < token.length - 1) {
        fields[token.substring(0, eqIdx)] = token.substring(eqIdx + 1);
      }
    }

    double f(String key) =>
        double.tryParse(fields[key] ?? '') ?? 0.0;

    int i(String key) {
      final raw = fields[key] ?? '0';
      // Remove trailing '%' se presente (ex.: "87%")
      return int.tryParse(raw.replaceAll('%', '')) ?? 0;
    }

    return Telemetry(
      x: f('X'),
      y: f('Y'),
      theta: f('Th'),
      velocity: f('V'),
      velocityAvg: f('Vavg'),
      distance: f('Dist'),
      battery: i('Bat'),
      mode: (fields['Mode'] == '1') ? RobotMode.autonomous : RobotMode.manual,
      calibrated: fields['Calib'] == '1',
    );
  }

  @override
  String toString() =>
      'Telemetry(x=$x, y=$y, θ=$theta, v=$velocity, bat=$battery%, '
      'mode=$mode, calib=$calibrated)';
}
