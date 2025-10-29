import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:impostor_ar/core/routers/router.dart';
import 'package:impostor_ar/firebase_options.dart';
import 'package:impostor_ar/core/di/injection.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:impostor_ar/themes/light_theme.dart';
import 'package:impostor_ar/themes/dark_theme.dart';
import 'package:impostor_ar/services/day_night_service.dart';
import 'package:impostor_ar/controllers/theme_controller.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupLocator();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final DayNightService _dayNightService;
  late final ThemeController _themeController;
  late final router;

  @override
  void initState() {
    super.initState();
    _dayNightService = DayNightService();
    _themeController = ThemeController(_dayNightService);
    globalThemeController = _themeController; // expõe para MVP
    router = createRouter();
  }

  @override
  void dispose() {
    _themeController.dispose();
    _dayNightService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Impostor AR',
          debugShowCheckedModeBanner: false,
          debugShowMaterialGrid: false,
          showPerformanceOverlay: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeController.mode,
          routerConfig: router,
        );
      },
    );
  }
}
