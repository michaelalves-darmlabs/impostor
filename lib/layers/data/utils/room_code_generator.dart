import 'dart:math';

const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

String generateRoomCode() {
  final random = Random();
  return List.generate(6, (_) => _chars[random.nextInt(_chars.length)]).join();
}
