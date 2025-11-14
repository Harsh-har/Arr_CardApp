import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../../Main_Screens/Card_Map_Base_Screen_Widget/Provider_Loader.dart';
import 'package:provider/provider.dart';

Future<void> importDevicesAndSpaces(BuildContext context, MQTTService mqttService) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) {
      print("❌ File picking was cancelled or failed");
      return;
    }

    print("📁 Picked file: ${result.files.single.name}");
    print("📂 Path: ${result.files.single.path}");

    if (result.files.single.path == null) {
      print("❌ File path is null");
      return;
    }

    final file = File(result.files.single.path!);

    if (!await file.exists()) {
      print("❌ File does not actually exist at path");
      return;
    }

    String content = await file.readAsString();
    final jsonData = jsonDecode(content);
    print("✅ JSON content parsed: $jsonData");

    final prefs = await SharedPreferences.getInstance();

    // ✅ Devices
    if (jsonData['devices'] is List) {
      List<String> encodedDevices = (jsonData['devices'] as List)
          .map((device) => jsonEncode(device))
          .toList();
      await prefs.setStringList('saved_devices', encodedDevices);
    }

    // ✅ Spaces
    if (jsonData['spaces'] is Map<String, dynamic>) {
      for (var entry in (jsonData['spaces'] as Map<String, dynamic>).entries) {
        if (entry.value is List) {
          await prefs.setStringList('saved_spaces_${entry.key}', List<String>.from(entry.value));
        }
      }
    }

    // ✅ Rooms
    if (jsonData['rooms'] is List) {
      final importedRooms = List<String>.from(jsonData['rooms']);
      await prefs.setStringList('main_rooms', importedRooms);

      // Update ProviderLoader
      final roomsProvider = Provider.of<ProviderLoader>(context, listen: false);
      roomsProvider.setRooms(importedRooms);
    }

    // ✅ Topics per room (publish + subscribe)
    if (jsonData['topics'] is Map<String, dynamic>) {
      for (var entry in (jsonData['topics'] as Map<String, dynamic>).entries) {
        String room = entry.key;
        var topicData = entry.value;

        if (topicData is Map<String, dynamic>) {
          String? pub = topicData['publish'];
          String? sub = topicData['subscribe'];

          if (pub != null) {
            await prefs.setString("saved_topic_$room", pub);
            await prefs.setStringList("saved_topics_$room", [pub]);
          }

          if (sub != null) {
            await prefs.setString("saved_subscribeTopic_$room", sub);
            await prefs.setStringList("saved_subscribeTopics_$room", [sub]);

            // Immediately subscribe via MQTT
            mqttService.subscribe(sub);
          }
        }
      }
    }

    // ❌ Removed Scenes import logic

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Import successful (Devices, Spaces, Rooms, Topics)!')),
    );
  } catch (e, stack) {
    print("❌ Import failed: $e");
    print(stack);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Import failed: $e')),
    );
  }
}
