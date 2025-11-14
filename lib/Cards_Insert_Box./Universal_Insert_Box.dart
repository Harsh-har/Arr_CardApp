import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Devices_Structure/Devices_Structure_Json.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';

Future<Device?> universalInsertBox({
  required BuildContext context,
  required String selectedOption,
  required String roomName,
  required Function(String) updateTopicsCallback,
  required Function(Device) updateGridCallback,
}) async {
  final deviceIdController = TextEditingController();
  final locationController = TextEditingController();
  final elementController = TextEditingController();
  final topicController = TextEditingController();
  final subscribeTopicController = TextEditingController();

  final mqttService = Provider.of<MQTTService>(context, listen: false);
  SharedPreferences prefs = await SharedPreferences.getInstance();

  topicController.text = prefs.getString('saved_topic_$roomName') ?? '';
  subscribeTopicController.text = prefs.getString('saved_subscribeTopic_$roomName') ?? '';

  int getDefaultBrightness(String deviceType) {
    if (deviceType == 'Dimmer') return 50;
    if (deviceType == 'Exhaust') return 2;
    if (deviceType == 'Fan') return 4;
    if (deviceType == 'SubNode Supply' || deviceType == 'Strip Light') return 128;
    return 100;
  }

  final deviceIconSvgMapping = {
    'Dimmer': 'assets/icons/Card_Icons/ListDimmer.svg',
    'SubNode Supply': 'assets/icons/Card_Icons/ListSubnode.svg',
    'Strip Light': 'assets/icons/Card_Icons/ListStrip.svg',
    'Fan': 'assets/icons/Card_Icons/ListFan.svg',
    'AC': 'assets/icons/Card_Icons/ListAC.svg',
    'Curtains': 'assets/icons/Card_Icons/ListBlinds.svg',
    'Exhaust': 'assets/icons/Card_Icons/ListExhaust.svg',
    'Relay': 'assets/icons/Card_Icons/ListRelay.svg',
    'Sensors (Occupancy)': 'assets/icons/Card_Icons/ListFan.svg',
    'Individual Subnode': 'assets/icons/Card_Icons/ListSubnode.svg',
    'Individual Strip': 'assets/icons/Card_Icons/ListStrip.svg',
    'Group device': 'assets/icons/Card_Icons/ListGroup.svg',
    'RGB Strip': 'assets/icons/Card_Icons/ListStrip.svg',
    'SMPS' : 'assets/icons/Card_Icons/ListStrip.svg',

  };

  bool isDuplicate = false;
  bool isSubmitDisabled = true;

  void updateDeviceId() {
    String roomPrefix = roomName.length >= 3
        ? roomName.substring(0, 3).toLowerCase()
        : roomName.toLowerCase();
    String listItemPrefix = selectedOption.isNotEmpty
        ? selectedOption[0].toLowerCase()
        : '';
    String element = elementController.text.trim();
    deviceIdController.text = '${roomPrefix}_${listItemPrefix}_$element';
  }

  Future<void> checkDuplicate(String location) async {
    List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
    isDuplicate = savedDevices.any((deviceStr) {
      try {
        final json = jsonDecode(deviceStr);
        return json['location'] == location && json['listItemName'] == selectedOption;
      } catch (e) {
        return false;
      }
    });
  }

  Future<void> saveRoom(String newRoom) async {
    List<String> savedRooms = prefs.getStringList('saved_rooms') ?? [];
    if (!savedRooms.contains(newRoom)) {
      savedRooms.add(newRoom);
      await prefs.setStringList('saved_rooms', savedRooms);
      updateTopicsCallback(newRoom);
    }
  }

  Future<void> saveDevice(Device newDevice) async {
    List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
    savedDevices.add(jsonEncode(newDevice.toJson()));
    await prefs.setStringList('saved_devices', savedDevices);
  }

  Future<void> saveDeviceId(String newDeviceID) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDeviceIDs = prefs.getStringList('deviceId') ?? [];

    if (!savedDeviceIDs.contains(newDeviceID)) {
      savedDeviceIDs.add(newDeviceID);
      await prefs.setStringList('deviceId', savedDeviceIDs);
      updateTopicsCallback(newDeviceID);
    }
  }

  Future<void> saveElementWithTopic(String elementId, String topic) async {
    List<String> savedElements = prefs.getStringList('saved_elements') ?? [];
    String entry = "$elementId|$topic";
    if (!savedElements.contains(entry)) {
      savedElements.add(entry);
      await prefs.setStringList('saved_elements', savedElements);
    }
  }


  // 🧩 UI Dialog
  return showDialog<Device>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        void validateForm() async {
          String location = locationController.text.trim();
          String element = elementController.text.trim();
          await checkDuplicate(location);

          setState(() {
            isSubmitDisabled = location.isEmpty || element.isEmpty || isDuplicate;
          });
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              SizedBox(
                height: 50,
                width: 45,
                child: selectedOption == 'RGB Strip'
                    ? ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.red, Colors.green, Colors.blue],
                    stops: [0.25, 0.5, 0.7],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: SvgPicture.asset(
                    deviceIconSvgMapping[selectedOption] ?? 'assets/icons/Card_Icons/Null.svg',
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                )
                    : SvgPicture.asset(
                  deviceIconSvgMapping[selectedOption] ?? 'assets/icons/Card_Icons/Null.svg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(selectedOption, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Device Location'),
                  onChanged: (_) => validateForm(),
                ),
                if (isDuplicate)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "⚠️ Device with this Location & type already exists!",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 10),

                TextFormField(
                  readOnly: true,
                  initialValue: roomName,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: elementController,
                  decoration: const InputDecoration(
                      labelText: 'Element', border: OutlineInputBorder()),
                  onChanged: (_) {
                    validateForm();
                    setState(() => updateDeviceId()); // Update deviceId as element changes
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  readOnly: true,
                  controller: topicController,
                  decoration: const InputDecoration(
                    labelText: 'Publish Topic (Global)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  readOnly: true,
                  controller: subscribeTopicController,
                  decoration: const InputDecoration(
                    labelText: 'Subscribe Topic (Global)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),


                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Device ID section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Generated Device ID: ",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Expanded(
                            child: TextField(
                              controller: deviceIdController,
                              readOnly: true,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Default Brightness section
                      Text(
                        "Default brightness: ${getDefaultBrightness(selectedOption)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitDisabled
                  ? null
                  : () async {
                final location = locationController.text.trim();
                final element = elementController.text.trim();
                final topic = topicController.text.trim();
                final subscribeTopic = subscribeTopicController.text.trim();

                await checkDuplicate(location);
                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("⚠️ Device with this name & type already exists!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // ✅ Auto-generate deviceId
                String roomPrefix = roomName.length >= 3
                    ? roomName.substring(0, 3).toLowerCase()
                    : roomName.toLowerCase();
                String listItemPrefix = selectedOption.isNotEmpty
                    ? selectedOption[0].toLowerCase()
                    : '';
                String deviceId = '${roomPrefix}_${listItemPrefix}_$element';


                // Determine default brightness based on device type
                int defaultBrightness;
                if (selectedOption == 'Dimmer') {
                  defaultBrightness = 50;
                } else if (selectedOption == 'Exhaust') {
                  defaultBrightness = 2;
                } else if (selectedOption == 'Fan') {
                  defaultBrightness = 4;
                } else if (selectedOption == 'SubNode Supply' || selectedOption == 'Strip Light') {
                  defaultBrightness = 128;
                } else {
                  defaultBrightness = 100;
                }


                Device newDevice = Device(
                  deviceId: deviceId,
                  location: location,
                  listItemName: selectedOption,
                  topic: topic,
                  subscribeTopic: subscribeTopic,
                  element: element,
                  roomName: roomName,
                  icon: selectedOption,
                  brightness: defaultBrightness,
                );

                await saveDeviceId(deviceId);
                await saveDevice(newDevice);
                await saveRoom(roomName);
                await saveElementWithTopic(element, topic);

                if (mqttService.isConnected) {
                  mqttService.publish(
                    topic,
                    "Location: $location, Room: $roomName, Type: $selectedOption, Element: $element",
                  );
                  mqttService.subscribe(subscribeTopic);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✅ Published to $topic & Subscribed to $subscribeTopic",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("⚠️ MQTT not connected!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                updateGridCallback(newDevice);
                Navigator.of(context).pop(newDevice);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      });
    },
  );
}
