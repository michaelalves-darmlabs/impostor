import 'dart:async';
import 'package:flutter/material.dart';
import '../services/day_night_service.dart';

/// Controlador de tema com suporte a modo automático e manual.
class ThemeController extends ChangeNotifier {
  final DayNightService _svc;
  ThemeMode _mode;
  bool _auto = true; // por padrão automático ligado
  late final StreamSubscription<bool> _sub;

  ThemeController(this._svc)
    : _mode = _svc.isDayNow(DateTime.now()) ? ThemeMode.light : ThemeMode.dark {
    // Ouve mudanças de dia/noite e aplica quando auto estiver ligado.
    _sub = _svc.isDayStream.listen((isDay) {
      if (_auto) {
        _mode = isDay ? ThemeMode.light : ThemeMode.dark;
        notifyListeners();
      }
    });
  }

  ThemeMode get mode => _mode;
  bool get isAuto => _auto;

  /// Alterna manualmente entre claro/escuro e desliga o automático.
  void toggleManual() {
    _auto = false;
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Reativa o automático e sincroniza imediatamente com o horário atual.
  void enableAuto() {
    _auto = true;
    final isDay = _svc.isDayNow(DateTime.now());
    _mode = isDay ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// Acesso global simples (MVP) para telas chamarem toggleManual/enableAuto
// sem depender de pacotes de injeção. Em produção, prefira um escopo/injetor.
ThemeController? globalThemeController;
