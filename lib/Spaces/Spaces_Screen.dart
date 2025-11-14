import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Devices_Structure/Devices_Structure_Json.dart';
import '../space_devices /Inside_InsertBox.dart';

class SpacesBody extends StatefulWidget {
  final String roomName;

  const SpacesBody({super.key, required this.roomName});

  @override
  State<SpacesBody> createState() => _SpacesBodyState();
}

class _SpacesBodyState extends State<SpacesBody> {
  List<String> spaces = [];
  late String selectedRoom;

  @override
  void initState() {
    super.initState();
    selectedRoom = widget.roomName;
    _loadSpaces();
  }

  Future<List<Device>> _getDevicesForSpace(String spaceName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];

    List<Device> filteredDevices = [];

    for (String item in savedDevices) {
      try {
        Map<String, dynamic> json = Map<String, dynamic>.from(await Future.value(
            jsonDecode(item)));
        Device device = Device.fromJson(json);

        if (device.roomName == spaceName) {
          filteredDevices.add(device);
        }
      } catch (e) {
        print("❌ Failed to load device: $e");
      }
    }

    return filteredDevices;
  }

  Future<void> _loadSpaces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String roomKey = 'saved_spaces_$selectedRoom';
    List<String> savedSpaces = prefs.getStringList(roomKey) ?? [];

    if (!mounted) return;

    setState(() {
      spaces = savedSpaces;
    });

    print("✅ Loaded Spaces for $selectedRoom: $savedSpaces");
  }

  Future<void> _saveSpaces() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String roomKey = 'saved_spaces_$selectedRoom';
    await prefs.setStringList(roomKey, spaces);
    print("💾 Saved Spaces for $selectedRoom: $spaces");
  }

  void _showAddSpaceDialog() {
    final TextEditingController spaceController = TextEditingController();
    bool isDuplicate = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Space'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: spaceController,
                    decoration: const InputDecoration(hintText: 'Enter Space Name'),
                    onChanged: (value) {
                      setStateDialog(() {
                        isDuplicate = spaces.any((space) =>
                        space.toLowerCase().trim() == value.toLowerCase().trim());
                      });
                    },
                  ),
                  if (isDuplicate)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "⚠️ Space with this name already exists!",
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String spaceName = spaceController.text.trim();
                    if (spaceName.isEmpty || isDuplicate) {
                      return;
                    }

                    spaces.add(spaceName);  // Modify list directly
                    await _saveSpaces();

                    Navigator.pop(context);

                    setState(() {});  // Trigger rebuild after closing dialog
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String spaceName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Space"),
          content: Text("Are you sure you want to delete '$spaceName'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  spaces.remove(spaceName);
                });
                _saveSpaces();
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: spaces.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "No Spaces Added",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showAddSpaceDialog,
              child: const Text(
                "Create Your Own Space",
                style: TextStyle(
                  color: Color(0xff00A1F1),
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                return GestureDetector(


                  onLongPress: () => _confirmDelete(spaces[index]),
                  child: _spaceCard(spaces[index]),
                );
              },
            ),
          ),
          Center(
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 60),
              onPressed: _showAddSpaceDialog,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _spaceCard(String spaceName) {
    return FutureBuilder<List<Device>>(
      future: _getDevicesForSpace(spaceName),
      builder: (context, snapshot) {
        int bulbCount = 0;
        int fanCount = 0;
        int acCount = 0;
        int relayCount = 0;

        if (snapshot.hasData) {
          for (var device in snapshot.data!) {
            String name = device.listItemName.toLowerCase();

            // Group similar devices by shared icon
            if (name.contains("subnode supply") || name.contains("strip light") ||
                name.contains("individual subnode") || name.contains("individual strip") ||
                name.contains("dimmer")) {
              bulbCount++;
            }
            if (name.contains("fan") || name.contains("exhaust")) fanCount++;
            if (name.contains("ac")) acCount++;
            if (name.contains("relay")) relayCount++;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  spaceName,
                  style: TextStyle(
                    color: Colors.grey[200],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  if (bulbCount > 0) ...[
                    SvgPicture.asset('assets/Spaces_Cards_Icons/bulb.svg', height: 20, width: 20),
                    const SizedBox(width: 4),
                    Text("$bulbCount", style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                  ],
                  if (fanCount > 0) ...[
                    SvgPicture.asset('assets/Spaces_Cards_Icons/fan.svg', height: 20, width: 20),
                    const SizedBox(width: 4),
                    Text("$fanCount", style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                  ],
                  if (acCount > 0) ...[
                    SvgPicture.asset('assets/Spaces_Cards_Icons/ac.svg', height: 20, width: 20),
                    const SizedBox(width: 4),
                    Text("$acCount", style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 12),
                  ],
                  if (relayCount > 0) ...[
                    SvgPicture.asset('assets/Spaces_Cards_Icons/relay.svg', height: 20, width: 20),
                    const SizedBox(width: 4),
                    Text("$relayCount", style: const TextStyle(color: Colors.white)),
                  ],
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
