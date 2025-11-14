import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

Future<void> exportDevicesAndSpaces(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Devices
  List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
  List<Map<String, dynamic>> deviceList = [];
  for (String deviceJson in savedDevices) {
    try {
      deviceList.add(jsonDecode(deviceJson));
    } catch (_) {}
  }

  // 2. Spaces per room
  Map<String, List<String>> allSpaces = {};
  for (String key in prefs.getKeys()) {
    if (key.startsWith('saved_spaces_')) {
      String room = key.replaceFirst('saved_spaces_', '');
      allSpaces[room] = prefs.getStringList(key) ?? [];
    }
  }

// 3. Topics per room (publish + subscribe)
  Map<String, Map<String, dynamic>> roomTopics = {};
  for (String key in prefs.getKeys()) {
    if (key.startsWith('saved_topic_')) {
      String room = key.replaceFirst('saved_topic_', '');
      String? pubTopic = prefs.getString(key);
      String? subTopic = prefs.getString("saved_subscribeTopic_$room");

      if (pubTopic != null && subTopic != null) {
        // also try to detect base topic if following /in + /out rule
        String baseTopic = pubTopic.endsWith('/in')
            ? pubTopic.replaceFirst(RegExp(r'/in$'), '')
            : pubTopic;

        roomTopics[room] = {
          "base": baseTopic,
          "publish": pubTopic,
          "subscribe": subTopic,
        };
      }
    }
  }

  // 4. Main Rooms
  List<String> mainRooms = prefs.getStringList('main_rooms') ?? [];

// Combine everything
  final exportData = {
    'devices': deviceList,
    'spaces': allSpaces,
    'topics': roomTopics,
    'rooms': mainRooms,
  };


  final formattedJson = const JsonEncoder.withIndent('  ').convert(exportData);

  try {
    // Ask user for filename
    final fileName = await _askFileName(context) ?? 'swaja_backup';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.json');
    await file.writeAsString(formattedJson);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📦 Swaja Backup (Devices + Spaces + Topics + Rooms )',
    );
  } catch (e) {
    debugPrint("❌ Export failed: $e");
  }
}

Future<String?> _askFileName(BuildContext context) async {
  String fileName = '';
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Enter backup file name'),
        content: TextField(
          onChanged: (value) => fileName = value,
          decoration: const InputDecoration(hintText: "backup_name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (fileName.trim().isEmpty) {
                fileName = 'swaja_backup';
              }
              Navigator.of(context).pop(fileName.trim());
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

