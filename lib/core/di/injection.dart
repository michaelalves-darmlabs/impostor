import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/core/services/room_session_service.dart';
import 'package:impostor_ar/core/services/notification_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupLocator() async {
  // Firebase core singletons
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(firebaseAuth: sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<GameRepository>(
    () => GameRepository(firestore: sl<FirebaseFirestore>()),
  );

  // Services
  sl.registerLazySingleton<RoomSessionService>(() => RoomSessionService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
}
