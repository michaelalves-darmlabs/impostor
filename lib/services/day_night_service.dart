import 'dart:async';

/// Serviço que calcula dia/noite baseado em hora local e publica mudanças.
/// MVP: considera dia entre 06:00 e 17:59 e noite fora desse intervalo.
/// TODO: No futuro, substituir por lógica baseada em nascer/pôr do sol via geolocalização.
class DayNightService {
  final _controller = StreamController<bool>.broadcast();
  Timer? _timer;

  DayNightService() {
    _emitNow();
    // Checa a cada 1 minuto para atualizar o período.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _emitNow());
  }

  /// Retorna true se [now] está no período do dia.
  bool isDayNow(DateTime now, {int dayStartHour = 6, int nightStartHour = 18}) {
    final h = now.hour;
    return h >= dayStartHour && h < nightStartHour;
  }

  /// Stream que emite true (dia) ou false (noite) quando detecta mudanças.
  Stream<bool> get isDayStream => _controller.stream;

  void _emitNow() {
    final isDay = isDayNow(DateTime.now());
    _controller.add(isDay);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
