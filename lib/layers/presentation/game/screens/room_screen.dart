import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/layers/domain/models/game_room_model.dart';
import 'package:impostor_ar/layers/presentation/game/screens/room_screen_host.dart';
import 'package:impostor_ar/layers/presentation/game/screens/room_screen_guest.dart';

class RoomScreen extends StatelessWidget {
  final String roomCode;
  const RoomScreen({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    final gameRepository = GetIt.I<GameRepository>();
    final currentUser = GetIt.I<AuthRepository>().currentUser;

    return FutureBuilder<String?>(
      future: gameRepository.getRoomIdByCode(roomCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Sala não encontrada')),
          );
        }

        final roomId = snapshot.data!;
        return FutureBuilder<GameRoom?>(
          future: gameRepository.getRoomStream(roomId).first,
          builder: (context, roomSnapshot) {
            if (roomSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final room = roomSnapshot.data;
            if (room == null) {
              return const Scaffold(
                body: Center(child: Text('Sala não encontrada')),
              );
            }

            final isHost = room.hostId == currentUser?.uid;
            return isHost
                ? RoomScreenHost(roomCode: roomCode)
                : RoomScreenGuest(roomCode: roomCode);
          },
        );
      },
    );
  }
}
