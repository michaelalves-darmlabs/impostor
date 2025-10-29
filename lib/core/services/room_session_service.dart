import 'package:flutter/foundation.dart';

class RoomSessionService extends ChangeNotifier {
  String? _currentRoomCode;

  String? get currentRoomCode => _currentRoomCode;

  void setRoomCode(String? code) {
    _currentRoomCode = code;
    notifyListeners();
  }

  void clearRoomCode() {
    _currentRoomCode = null;
    notifyListeners();
  }

  bool get isInRoom => _currentRoomCode != null;
}
