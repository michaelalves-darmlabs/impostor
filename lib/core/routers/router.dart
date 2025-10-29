import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/layers/presentation/auth/screens/login_screen.dart';

import 'package:impostor_ar/layers/presentation/game/screens/room_screen.dart';
import 'package:impostor_ar/layers/presentation/home/screens/home_screen.dart';
import 'package:impostor_ar/layers/presentation/room/screens/join_room_screen.dart';
import 'package:impostor_ar/layers/presentation/room/screens/qr_scanner_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter() {
  final authRepo = GetIt.I<AuthRepository>();
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = authRepo.currentUser != null;
      final bool onLoginScreen = state.matchedLocation == '/';

      if (!loggedIn) {
        return onLoginScreen ? null : '/';
      }
      if (onLoginScreen) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        routes: <GoRoute>[
          GoRoute(
            path: '/join',
            builder: (context, state) {
              final roomCode = state.extra as Map<String, dynamic>?;
              return JoinRoomScreen(
                initialRoomCode: roomCode?['roomCode'] as String?,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/room/:roomCode',
        builder: (context, state) {
          final roomCode = state.pathParameters['roomCode']!;
          return RoomScreen(roomCode: roomCode);
        },
      ),
    ],
  );
}
