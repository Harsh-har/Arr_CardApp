import 'package:flutter/material.dart';

class ActiveRoomProvider extends ChangeNotifier {
  String? _activeRoom;

  String? get activeRoom => _activeRoom;

  void setActiveRoom(String? room) {
    _activeRoom = room;
    notifyListeners();
  }
}

