import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:impostor_ar/layers/data/repositories/auth_repository.dart';
import 'package:impostor_ar/layers/data/repositories/game_repository.dart';
import 'package:impostor_ar/core/services/room_session_service.dart';
import 'package:impostor_ar/layers/presentation/shared/widgets/user_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCreatingRoom = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final roomSessionService = GetIt.I<RoomSessionService>();
    if (roomSessionService.isInRoom && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && roomSessionService.isInRoom) {
          context.go('/room/${roomSessionService.currentRoomCode}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = GetIt.I<AuthRepository>();
    final currentUser = authRepository.currentUser;
    final displayName = currentUser?.displayName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostor AR'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: _buildDrawer(context, authRepository, displayName, currentUser),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Impostor AR',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.door_front_door),
                    label: const Text('ENTRAR EM SALA'),
                    onPressed: () => context.go('/home/join'),
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: _isCreatingRoom
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_box_rounded),
                    label: const Text('CRIAR SALA'),
                    onPressed: _isCreatingRoom ? null : _createRoomDirectly,
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createRoomDirectly() async {
    setState(() => _isCreatingRoom = true);
    try {
      final gameRepository = GetIt.I<GameRepository>();
      final authRepository = GetIt.I<AuthRepository>();
      final user = authRepository.currentUser;

      if (user != null) {
        final roomId = await gameRepository.createRoom(
          hostId: user.uid,
          hostName: user.displayName ?? 'Jogador',
          hostPhoto: user.photoURL,
          maxPlayers: 8,
          numImpostors: 2,
        );

        if (roomId.isNotEmpty && mounted) {
          try {
            final room = await gameRepository.getRoomStream(roomId).first;
            if (mounted && room != null && room.code.isNotEmpty) {
              context.go('/room/${room.code}');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao carregar sala: $e')),
              );
              setState(() => _isCreatingRoom = false);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar sala: $e')));
        setState(() => _isCreatingRoom = false);
      }
    }
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthRepository authRepository,
    String displayName,
    dynamic currentUser,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                UserAvatar(
                  displayName: displayName,
                  photoUrl: currentUser?.photoURL,
                  radius: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentUser?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Sair',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              authRepository.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
