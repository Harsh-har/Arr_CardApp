import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadTopics() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();

  Map<String, String> pubMap = {};
  Map<String, String> subMap = {};

  for (String key in keys) {
    if (key.startsWith("saved_topic_")) {
      final room = key.replaceFirst("saved_topic_", "");
      pubMap[room] = prefs.getString(key) ?? '';
    }
    if (key.startsWith("saved_subscribeTopic_")) {
      final room = key.replaceFirst("saved_subscribeTopic_", "");
      subMap[room] = prefs.getString(key) ?? '';
    }
  }

  debugPrint("✅ Loaded global topics:");
  debugPrint("Publish: $pubMap");
  debugPrint("Subscribe: $subMap");
}
