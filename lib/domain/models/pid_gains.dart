/// Ganhos do controlador PID do robô.
///
/// Parse da resposta do robô: `PID:0.50 0.00 0.10\r\n`
class PidGains {
  final double kp;
  final double ki;
  final double kd;

  const PidGains({
    required this.kp,
    required this.ki,
    required this.kd,
  });

  /// Tenta parsear uma linha `PID:<kp> <ki> <kd>`.
  /// Retorna `null` se a linha não casar com o formato.
  static PidGains? tryParse(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('PID:')) return null;

    final parts = trimmed.substring(4).trim().split(RegExp(r'\s+'));
    if (parts.length < 3) return null;

    final kp = double.tryParse(parts[0]);
    final ki = double.tryParse(parts[1]);
    final kd = double.tryParse(parts[2]);

    if (kp == null || ki == null || kd == null) return null;

    return PidGains(kp: kp, ki: ki, kd: kd);
  }

  @override
  String toString() => 'PidGains(kp=$kp, ki=$ki, kd=$kd)';
}
