import 'package:flutter/material.dart';

class ProviderLoader extends ChangeNotifier {
  List<String> _rooms = [];

  List<String> get rooms => _rooms;

  void setRooms(List<String> newRooms) {
    _rooms = newRooms;
    notifyListeners();
  }

  void addRoom(String room) {
    if (!_rooms.contains(room)) {
      _rooms.add(room);
      notifyListeners();
    }
  }

  void removeRoom(String room) {
    _rooms.remove(room);
    notifyListeners();
  }
}



