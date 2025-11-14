import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';
import 'Topic_Load.dart';

class PublishTopicEdit extends StatefulWidget {
  const PublishTopicEdit({super.key});

  @override
  State<PublishTopicEdit> createState() => _PublishTopicEditState();
}

class _PublishTopicEditState extends State<PublishTopicEdit> {
  Map<String, String> _publishTopics = {};
  Map<String, String> _subscribeTopics = {};
  String _searchQuery = "";
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    await loadTopics(); // 🟢 Ensure defaults are saved
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

    setState(() {
      _publishTopics = pubMap;
      _subscribeTopics = subMap;
    });
  }

  Future<void> _editTopic({
    required String room,
    required String type,
    required String currentTopic,
  }) async {
    final controller = TextEditingController(text: currentTopic);
    final mqttService = Provider.of<MQTTService>(context, listen: false);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $type Topic for $room"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new topic"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newTopic = controller.text.trim();
              if (newTopic.isNotEmpty) {
                Navigator.pop(context, newTopic);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result != null && result != currentTopic) {
      final prefs = await SharedPreferences.getInstance();
      final keyBase = type == "publish" ? "saved_topic_" : "saved_subscribeTopic_";
      final listKeyBase = type == "publish" ? "saved_topics_" : "saved_subscribeTopics_";

      await prefs.setString("$keyBase$room", result);
      await prefs.setStringList("$listKeyBase$room", [result]);

      // ✅ Update saved devices
      List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
      List<String> updatedDevices = [];
      int updatedCount = 0;

      for (var deviceJson in savedDevices) {
        try {
          final deviceMap = Map<String, dynamic>.from(jsonDecode(deviceJson));
          if (deviceMap['roomName'] == room) {
            if (type == 'publish') {
              deviceMap['topic'] = result;
            } else {
              deviceMap['subscribeTopic'] = result;
            }
            updatedCount++;
          }
          updatedDevices.add(jsonEncode(deviceMap));
        } catch (_) {
          updatedDevices.add(deviceJson);
        }
      }

      await prefs.setStringList('saved_devices', updatedDevices);

      // ✅ MQTT update if subscribe topic changes
      if (type == 'subscribe' && mqttService.isConnected) {
        mqttService.unsubscribe(currentTopic);
        mqttService.subscribe(result);
      }

      setState(() {
        if (type == "publish") {
          _publishTopics[room] = result;
        } else {
          _subscribeTopics[room] = result;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ $type topic updated for $room\nUpdated $updatedCount device(s)"),
        backgroundColor: Colors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRooms = {..._publishTopics.keys, ..._subscribeTopics.keys}.toList()..sort();

    // 🔍 Apply search filter
    final filteredRooms = allRooms.where((room) {
      return room.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search Room...",
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text("Edit Topics", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = "";
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
          icon: Icon(
            _isSearching ? Icons.close : Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      backgroundColor: Colors.black87,
      body: ListView.builder(
        itemCount: filteredRooms.length,
        itemBuilder: (context, index) {
          final room = filteredRooms[index];
          final pub = _publishTopics[room] ?? "Not Set";
          final sub = _subscribeTopics[room] ?? "Not Set";

          return Card(
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Room: $room", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text("📤 ", style: TextStyle(color: Colors.yellow)),
                      Expanded(
                        child: Text(pub, style: const TextStyle(color: Colors.yellow), softWrap: true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.yellow),
                        tooltip: "Edit Publish Topic",
                        onPressed: () => _editTopic(room: room, type: "publish", currentTopic: pub),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text("📥 ", style: TextStyle(color: Colors.lightBlueAccent)),
                      Expanded(
                        child: Text(sub, style: const TextStyle(color: Colors.lightBlueAccent), softWrap: true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.lightBlue),
                        tooltip: "Edit Subscribe Topic",
                        onPressed: () => _editTopic(room: room, type: "subscribe", currentTopic: sub),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
