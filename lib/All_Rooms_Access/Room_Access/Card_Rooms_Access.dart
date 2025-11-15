import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Cards_Insert_Box./Universal_Insert_Box.dart';
import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../../Main_Screens/list_screen.dart';
import '../../Spaces/Spaces_Screen.dart';
import '../../Devices_Structure/Devices_Structure_Json.dart';
import '../../tab_selector/Tab_selector.dart';
import '../../utils/global_controller.dart';
import '../Animation UI Setting.dart';
import '../On_Tap_Function/Handle_Tap.dart';

class CardRoomsAccess extends StatefulWidget {
  final String roomName;
  final String appBarTitle;
  const CardRoomsAccess({
    super.key,
    required this.roomName,
    required this.appBarTitle,
  });

  @override
  State<CardRoomsAccess> createState() => _CardRoomsAccessState();
}

class _CardRoomsAccessState extends State<CardRoomsAccess> {
  final Map<String, String> deviceIconSvgMapping = {
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
    'Group Fan': 'assets/icons/Card_Icons/ListGroupFan.svg',
    'Group Strip': 'assets/icons/Card_Icons/ListGroupStrip.svg',
    'Group Light': 'assets/icons/Card_Icons/ListGroupLight.svg',
    'Group Single Light': 'assets/icons/Card_Icons/ListGroupSingleLight.svg',
    'Sensor': 'assets/icons/Card_Icons/ListSensor.svg',
    'RGB Strip': 'assets/icons/Card_Icons/ListStrip.svg',
    'SMPS' : 'assets/icons/Card_Icons/ListStrip.svg',

  };
  int getDefaultBrightness(String type) {
    switch(type) {
      case 'Dimmer': return 50;
      case 'Exhaust': return 2;
      case 'Fan': return 4;
      case 'SubNode Supply':
      case 'Strip Light': return 128;
      default: return 100;
    }
  }
  late List<Device> _devices = [];
  late Map<String, bool> _deviceStates = {};
  bool _showDevices = true;
  String? _selectedCategory;
  List<Device> get filteredDevices =>
      _devices.where((d) => d.roomName == widget.roomName).toList();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadDevices();
    // _initDevices();
    deviceRefreshNotifier.addListener(() {
      if (deviceRefreshNotifier.value) {
        _loadDevices();
        deviceRefreshNotifier.value = false;
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _refreshDevices() async {
    print('🔄 Refreshing devices...');
    await _loadDevices();
    print('✅ Devices updated!');

    for (var device in _devices) {
      print(
        '📱 Device Location: ${device.location}, Room: ${device.roomName}, Element: ${device.element}',
      );
    }
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedDevices = prefs.getStringList('saved_devices');
    final List<String> savedDeviceIDs = prefs.getStringList('deviceId') ?? [];

    if (savedDevices == null || savedDevices.isEmpty) {
      print("⚠️ No saved devices found.");
      return;
    }

    List<Device> loaded = [];
    Map<String, bool> loadedStates = {};

    for (String item in savedDevices) {
      try {
        final Map<String, dynamic> json = jsonDecode(item);

        // ✅ Get deviceId (from JSON or fallback list)
        String deviceId = (json['deviceId'] ?? '').toString();
        if (deviceId.isEmpty && savedDeviceIDs.isNotEmpty) {
          // Try matching by device name in case it was stored separately
          String? matchedId = savedDeviceIDs.firstWhere(
                (id) => id.contains(json['location'] ?? ''),
            orElse: () => '',
          );
          deviceId = matchedId;
        }

        final String roomName = (json['roomName'] ?? '').toString();
        final String topic = (json['topic'] ?? prefs.getString('saved_topic_$roomName') ?? '').toString();
        final String subscribeTopic = (json['subscribeTopic'] ?? prefs.getString('saved_subscribeTopic_$roomName') ?? '').toString();

        if (deviceId.isEmpty) {
          print("⚠️ Skipping device '${json['name']}' → Missing deviceId");
          continue;
        }

        final String icon = (json['icon'] ?? json['icon'] ?? 'default').toString();

        final device = Device(
          deviceId: deviceId,
          location: json['location']?.toString() ?? '',
          listItemName: json['listItemName']?.toString() ?? '',
          element: json['element']?.toString() ?? '',
          roomName: roomName,
          icon: icon,
          topic: topic,
          subscribeTopic: subscribeTopic,
          isOn: prefs.getBool('${deviceId}_isOn') ?? false,
          brightness: json['brightness']?.toInt() ?? getDefaultBrightness(json['listItemName']?.toString() ?? ''),
        );

        loaded.add(device);
        loadedStates[device.deviceId] = device.isOn;

      } catch (e) {
        print("❌ JSON error while loading device: $e");
      }
    }

    // ✅ Update state
    if (!mounted) return;
    setState(() {
      _devices = loaded;
      _deviceStates = loadedStates;
    });

    print("📂 Loaded devices: ${loaded.length}");
    for (var d in loaded) {
      print("🔹Device ID: ${d.deviceId} | ${d.location} | topic: ${d.topic} | Room: ${d.roomName} | subscribe: ${d.subscribeTopic}");
    }
  }

  void _saveDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> encoded =
    _devices
        .map(
          (d) => jsonEncode({
        'deviceId' : d.deviceId,
        'location': d.location,
        'listItemName': d.listItemName,
        'topic': d.topic,
        'isOn' : d.isOn,
        'subscribeTopic': d.subscribeTopic,
        'element': d.element,
        'roomName': d.roomName,
        'icon': d.icon,
        'brightness' : d.brightness,
      }),
    )
        .toSet()
        .toList();

    await prefs.setStringList('saved_devices', encoded);
  }

  Future<void> _saveStateForDevice(Device device, {int? brightness, bool? isOn}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedDevices = prefs.getStringList('saved_devices') ?? [];

    final updatedDevices = savedDevices.map((deviceStr) {
      final jsonMap = jsonDecode(deviceStr);
      if (jsonMap['deviceId'] == device.deviceId) {
        if (brightness != null) jsonMap['brightness'] = brightness;
        if (isOn != null) jsonMap['isOn'] = isOn;
        jsonMap['location'] = device.location;
        jsonMap['roomName'] = device.roomName;
        jsonMap['element'] = device.element;
      }
      return jsonEncode(jsonMap);
    }).toList();

    await prefs.setStringList('saved_devices', updatedDevices);
  }

  // Future<void> _initDevices() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final isDevicesInitialized = prefs.getBool('is_devices_initialized') ?? false;
  //
  //   // Already initialized → load from saved
  //   if (isDevicesInitialized) {
  //     print("📂 Devices already initialized → loading from SharedPreferences");
  //     await _loadDevices();
  //     return;
  //   }
  //
  //   try {
  //     // 🔥 Use secure client (bundled PEM cert)
  //     final http.Client client = await createSecureClient();
  //
  //     final url = Uri.parse('https://192.168.1.125/app-init');
  //     print("🌍 Fetching devices from: $url");
  //
  //     final response = await client.get(url);
  //     print("📡 API status: ${response.statusCode}");
  //
  //     if (response.statusCode == 200) {
  //       final decoded = jsonDecode(response.body);
  //
  //       if (decoded is List) {
  //         List<String> deviceList = [];
  //
  //         for (var item in decoded) {
  //           if (item is Map<String, dynamic>) {
  //             try {
  //               Device device = Device.fromJson(item);
  //
  //               // ✅ Validate topics
  //               String topic = (device.topic).trim();
  //               String subscribeTopic = (device.subscribeTopic).trim();
  //
  //               if (topic.isEmpty || subscribeTopic.isEmpty) {
  //                 print(
  //                     "⚠️ Skipping device '${device.name}' because topic or subscribeTopic is empty");
  //                 continue; // skip this device
  //               }
  //
  //               // Save encoded device with validated topics
  //               deviceList.add(jsonEncode({
  //                 'name': device.name,
  //                 'listItemName': device.listItemName,
  //                 'element': device.element,
  //                 'roomName': device.roomName,
  //                 'icon': device.icon.codePoint,
  //                 'topic': topic,
  //                 'subscribeTopic': subscribeTopic,
  //               }));
  //             } catch (e) {
  //               print("⚠️ Error parsing device: $e");
  //             }
  //           }
  //         }
  //
  //         // ✅ Remove duplicates and save
  //         deviceList = deviceList.toSet().toList();
  //         await prefs.setStringList('saved_devices', deviceList);
  //
  //         // Save flag → so we don’t call API again
  //         await prefs.setBool('is_devices_initialized', true);
  //
  //         print("💾 Devices saved to SharedPreferences: ${deviceList.length}");
  //
  //         // Load into state
  //         await _loadDevices();
  //       } else {
  //         print("⚠️ API returned unexpected data format.");
  //       }
  //     } else {
  //       print("❌ API error: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("⚠️ Error fetching devices from API: $e");
  //   }
  // }

  Future<void> _deleteDevice(int index) async {
    if (index < 0 || index >= _devices.length) return;

    final deviceToDelete = _devices[index];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xff171717),
            title: const Text("Delete Device",style: TextStyle(color: Colors.white),),
            content: Text(
              "Are you sure you want to delete ${deviceToDelete.deviceId}?",style: TextStyle(color: Colors.white)
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel",style: TextStyle(color: Color(0xff0071A9))),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close the dialog first

                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();

                  setState(() {
                    _deviceStates.remove(deviceToDelete.deviceId);
                    _devices.removeAt(index);
                  });

                  // Save updated devices list
                  _saveDevices(); // ✅ this will handle deduplication too

                  // Load current topic/room/subscribe lists
                  List<String> savedTopics =
                      prefs.getStringList('saved_topics') ?? [];
                  List<String> savedSubscribeTopics =
                      prefs.getStringList('saved_subscribeTopics') ?? [];
                  List<String> savedRooms =
                      prefs.getStringList('saved_rooms') ?? [];

                  // If no other device uses this topic/room/subscribeTopic, remove it
                  bool topicStillUsed = _devices.any(
                    (d) => d.topic == deviceToDelete.topic,
                  );
                  bool subscribeStillUsed = _devices.any(
                    (d) => d.subscribeTopic == deviceToDelete.subscribeTopic,
                  );
                  bool roomStillUsed = _devices.any(
                    (d) => d.roomName == deviceToDelete.roomName,
                  );

                  if (!topicStillUsed && deviceToDelete.topic.isNotEmpty) {
                    savedTopics.remove(deviceToDelete.topic);
                    await prefs.setStringList('saved_topics', savedTopics);
                  }

                  if (!subscribeStillUsed &&
                      deviceToDelete.subscribeTopic.isNotEmpty) {
                    savedSubscribeTopics.remove(deviceToDelete.subscribeTopic);
                    await prefs.setStringList(
                      'saved_subscribeTopics',
                      savedSubscribeTopics,
                    );
                  }

                  if (!roomStillUsed && deviceToDelete.roomName.isNotEmpty) {
                    savedRooms.remove(deviceToDelete.roomName);
                    await prefs.setStringList('saved_rooms', savedRooms);
                  }

                  // Remove saved state
                  await prefs.remove('${deviceToDelete.deviceId}_isOn');
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return ListScreen(
          onItemSelected: (selectedOption) async {
            Navigator.pop(bottomSheetContext);
            await Future.delayed(const Duration(milliseconds: 100));

            List<String> predefinedDevices = [
              'Dimmer',
              'SubNode Supply',
              'Strip Light',
              'Fan',
              'AC',
              'Curtains',
              'Exhaust',
              'Relay',
              'Sensor',
              'RGB Strip',
              'SMPS',
            ];

            List<String> predefinedIndividualDevices = [
              'Individual Subnode',
              'Individual Strip',
            ];

            if ([
              'Group Fan',
              'Group Strip',
              'Group Light',
              'Group Single Light',
            ].contains(selectedOption)) {
              // await showGroupDataDialog(
              //   context: context,
              //   selectedOption: selectedOption,
              //   roomName: widget.roomName,
              //   updateTopicsCallback: _updateTopics,
              //   updateGridCallback: _addDevice,
              // );
            // } else if (predefinedIndividualDevices.contains(selectedOption)) {
            //   await _addIndividualDeviceToRoom(selectedOption);
            } else if (predefinedDevices.contains(selectedOption)) {
              await _addDeviceToRoom(selectedOption);
            }
          },
        );
      },
    );
  }

  Future<void> _addDeviceToRoom(String selectedOption) async {
    Device? newDevice = await universalInsertBox(
      context: context,
      selectedOption: selectedOption,
      roomName: widget.roomName,
      updateTopicsCallback: _updateTopics,
      updateGridCallback: (Device device) {
        _addDevice(device);
      },
    );

    if (newDevice != null) {
      setState(() {
        _deviceStates[newDevice.deviceId] = false;
      });
    }
  }

  // Future<void> _addIndividualDeviceToRoom(String selectedOption) async {
  //   Device? newDevice = await individualInsertBox(
  //     context: context,
  //     selectedOption: selectedOption,
  //     roomName: widget.roomName,
  //     updateTopicsCallback: _updateTopics,
  //     updateGridCallback: (Device device) {
  //       _addDevice(device);
  //     },
  //   );
  //
  //   if (newDevice != null) {
  //     setState(() {
  //       _deviceStates[newDevice.name] = false;
  //     });
  //   }
  // }

  void _updateTopics(String newTopic) {}

  void _addDevice(Device newDevice) {
    setState(() {
      bool exists = _devices.any(
        (d) =>
            d.deviceId == newDevice.deviceId &&
            d.listItemName == newDevice.listItemName,
      );
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Device '${newDevice.deviceId}' already exists!!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _devices.add(newDevice);
      _saveDevices(); // Saves to SharedPreferences
    });
  }

  void _handleDeviceTap(BuildContext context, Device device, int index) {
    handleDeviceTap(
      context: context,
      device: device,
      index: index,
      devices: _devices,
      deviceStates: _deviceStates,
      setState: setState,
      saveDevices: _saveDevices,
    );
  }

  Future<String?> getRoomTopic(String roomName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_topic_$roomName');
  }

  Future<void> masterRoomOff(BuildContext context, String roomName) async {
    final mqttService = Provider.of<MQTTService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    // 1. Get publish topic for the room
    final topic = prefs.getString('saved_topic_$roomName');
    if (topic == null || topic.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No topic found for $roomName")));
      return;
    }

    // 2. Load all saved devices
    final savedDevices = prefs.getStringList('saved_devices') ?? [];

    // 3. Filter devices by room
    final roomDevices = savedDevices
        .map((deviceJson) {
          final map = Map<String, dynamic>.from(jsonDecode(deviceJson));
          return Device.fromJson(map);
        })
        .where((device) => device.roomName == roomName);

    // 4. Publish OFF command for each device
    for (final device in roomDevices) {
      final command = "#*2*${device.element}*2*0*#";
      mqttService.publish(topic, command);
      debugPrint("🔴 Master OFF: Sent $command to $topic");
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Master OFF triggered for $roomName")),
    );
  }




  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.appBarTitle,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,

        actions: [
          if (_showDevices)
            RotatingSettingsMenu(
              isConnected: mqttService.isConnected,
              onAdd: _showOptions,
            ),
        ],
      ),

      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              TabSelector(
                showDevices: _showDevices,
                onTabChanged: (bool isDevices) {
                  setState(() {
                    _showDevices = isDevices;
                  });
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                    child:
                        _showDevices
                            ? Column(
                              children: [
                                if (filteredDevices.isNotEmpty) ...[
                                  _buildFilterBar(),
                                  const SizedBox(height: 20),
                                ],
                                Expanded(
                                  child:
                                      filteredDevices.isEmpty
                                          ? const Center(
                                            child: Text(
                                              "No Devices Added",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                          : RefreshIndicator(
                                            onRefresh: _refreshDevices,
                                            child: ListView(
                                              children:
                                                  _buildGroupedDeviceSections(),
                                            ),
                                          ),
                                ),
                              ],
                            )
                            : Column(
                              children: [Expanded(child: _buildSpacesBody())],
                            ),
                  ),
                ),
              ),
            ],
          ),

          if (!mqttService.isConnected)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Text(
                  "Broker/Wi-Fi Is Out Of Service!!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final Map<String, bool Function(Device)> categoryConditions = {
      "Subnode Supply": (d) => d.listItemName == "SubNode Supply",
      "Fans": (d) => d.listItemName == "Fan",
      "Strip Light": (d) => d.listItemName == "Strip Light",
      "Group Devices":
          (d) =>
              d.listItemName == "Group Fan" ||
              d.listItemName == "Group Strip" ||
              d.listItemName == "Group Light" ||
              d.listItemName == "Group Single Light",
      "AC": (d) => d.listItemName == "AC",
      "Relays":
          (d) =>
              d.listItemName == "Relay" ||
              d.listItemName == "Relay",
      "Dimmer": (d) => d.listItemName == "Dimmer",
      "Exhaust": (d) => d.listItemName == "Exhaust",
      "RGB Strip": (d) => d.listItemName == "RGB Strip",
      "Curtains": (d) => d.listItemName == "Curtains",
      "Individual Subnode": (d) => d.listItemName == "Individual Subnode",
      "Individual Strip": (d) => d.listItemName == "Individual Strip",
      "Sensor": (d) => d.listItemName == "Sensor",
      "SMPS": (d) => d.listItemName == "SMPS",
      "Others": (d) => false,
    };

    // Custom display names
    final Map<String, String> displayNames = {
      "Subnode Supply": "Light",
      "Fans": "Fans",
      "SMPS" : "SMPS",
      "Strip Light": "Strip Light",
      "AC": "AC",
      "Relays": "Relay",
      "Dimmer": "Dimmer",
      "Exhaust": "Exhaust",
      "RGB Strip": "RGB Strip",
      "Curtains": "Curtain",
      "Individual Subnode": "Individual Subnode",
      "Individual Strip": "Individual Strip",
      "Group Devices": "Group Devices",
      "Sensor": "Sensor",
      "Others": "Others",
    };

    // Show only categories with devices
    final List<String> activeCategories = [];
    for (var entry in categoryConditions.entries) {
      if (filteredDevices.any(entry.value)) {
        activeCategories.add(entry.key);
      }
    }
    activeCategories.insert(0, "All");

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: activeCategories.length,
        itemBuilder: (context, index) {
          final category = activeCategories[index];
          final isSelected =
              _selectedCategory == category ||
              (_selectedCategory == null && category == "All");

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(
                category == "All"
                    ? "All"
                    : (displayNames[category] ?? category),
                style: const TextStyle(color: Colors.white),
              ),
              selected: isSelected,
              selectedColor: Colors.blue[500],
              side: BorderSide.none,
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              showCheckmark: false,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category == "All" ? null : category;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpacesBody() {
    return SpacesBody(roomName: widget.roomName);
  }

  List<Widget> _buildGroupedDeviceSections() {
    Map<String, String> displayNames = {
      "Subnode Supply": "Light",
      "Fans": "Fans",
      "Relays": "Relay",
      "SMPS" : "SMPS",
      "Strip Light": "Strip Light",
      "Dimmer": "Dimmer",
      "AC": "AC",
      "Exhaust": "Exhaust",
      "RGB Strip": "RGB Strip",
      "Curtains": "Curtains",
      "Individual Subnode": "Individual Light",
      "Individual Strip": "Individual Strip",
      "Group Fan": "Group Devices",
      "Group Strip": "Group Devices",
      "Group Light": "Group Devices",
      "Group Single Light": "Group Devices",
      "Sensor": "Sensor",
      "Others": "Others",
    };

    Map<String, List<Device>> groupedDevices = {
      "Subnode Supply": [],
      "Fans": [],
      "Relays": [],
      "SMPS" : [],
      "Strip Light": [],
      "Dimmer": [],
      "AC": [],
      "Exhaust": [],
      "RGB Strip": [],
      "Curtains": [],
      "Individual Subnode": [],
      "Individual Strip": [],
      "Group Devices": [],
      "Sensor": [],
      "Others": [],
    };

    // Group devices properly
    for (var device in filteredDevices) {
      switch (device.listItemName) {
        case "SubNode Supply":
          groupedDevices["Subnode Supply"]!.add(device);
          break;
        case "Fan":
          groupedDevices["Fans"]!.add(device);
          break;
        case "Relay":
        groupedDevices["Relays"]!.add(device);
          break;
        case "Strip Light":
          groupedDevices["Strip Light"]!.add(device);
          break;
        case "SMPS":
          groupedDevices["SMPS"]!.add(device);
          break;
        case "Dimmer":
          groupedDevices["Dimmer"]!.add(device);
          break;
        case "AC":
          groupedDevices["AC"]!.add(device);
          break;
        case "Exhaust":
          groupedDevices["Exhaust"]!.add(device);
          break;
        case "RGB Strip":
          groupedDevices["RGB Strip"]!.add(device);
          break;
        case "Curtains":
          groupedDevices["Curtains"]!.add(device);
          break;
        case "Individual Subnode":
          groupedDevices["Individual Subnode"]!.add(device);
          break;
        case "Individual Strip":
          groupedDevices["Individual Strip"]!.add(device);
          break;
        case "Sensor":
          groupedDevices["Sensor"]!.add(device);
          break;
        case "Group Fan":
        case "Group Strip":
        case "Group Light":
        case "Group Single Light":
          groupedDevices["Group Devices"]!.add(device);
          break;
        default:
          groupedDevices["Others"]!.add(device);
      }
    }

    // Filter by selected category
    if (_selectedCategory != null) {
      groupedDevices.removeWhere((key, value) => key != _selectedCategory);
    }

    List<Widget> sections = [];

    groupedDevices.forEach((category, devices) {
      if (devices.isEmpty) return;

      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 3, bottom: 10),
                child: Text(
                  displayNames[category] ?? category,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      sections.add(
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.19,
            ),
            itemBuilder: (context, index) {
              final device = devices[index];
              final bool isOn = _deviceStates[device.deviceId] ?? false;

              return TweenAnimationBuilder<Offset>(
                duration: const Duration(milliseconds: 400),
                tween: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ),
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: 1.0,
                      child: Card(
                        color: const Color(0xFF131313),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap:
                              () => _handleDeviceTap(
                                context,
                                device,
                                _devices.indexOf(device),
                              ),
                          borderRadius: BorderRadius.circular(20),
                          child: _devicesCardBuild(
                            context: context,
                            device: device,
                            isOn: isOn,
                            index: _devices.indexOf(device),
                            deviceStates: _deviceStates,
                            onDelete: _deleteDevice,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      sections.add(const SizedBox(height: 30));
    });

    return sections;
  }

  Widget _devicesCardBuild({required BuildContext context, required Device device, required bool isOn, required int index, required Map<String, bool> deviceStates, required void Function(int) onDelete,}) {
    return GestureDetector(
      onLongPress: () => onDelete(index),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) {
                  final String? iconPath =
                      deviceIconSvgMapping[device.listItemName];
                  final bool isDeviceOn = deviceStates[device.deviceId] ?? false;
                  final deviceType = device.listItemName;

                  bool isGroupDevice = [
                    "Group Fan",
                    "Group Strip",
                    "Group Light",
                    "Group Single Light",
                  ].contains(deviceType);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ICON
                      iconPath != null
                          ? SizedBox(
                            width: 50,
                            height: 33,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child:
                                  (deviceType == 'RGB Strip' && isDeviceOn)
                                      ? Padding(
                                        padding: const EdgeInsets.only(left: 3),
                                        child: ShaderMask(
                                          shaderCallback:
                                              (bounds) => LinearGradient(
                                                colors: [
                                                  Colors.red,
                                                  Colors.green,
                                                  Colors.blue,
                                                ],
                                                stops: [
                                                  0.25,
                                                  0.5,
                                                  0.7,
                                                ], // biased gradient
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ).createShader(
                                                Rect.fromLTWH(
                                                  0,
                                                  0,
                                                  bounds.width,
                                                  bounds.height,
                                                ),
                                              ),
                                          child: SvgPicture.asset(
                                            iconPath,
                                            width: 24,
                                            height: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                      : SvgPicture.asset(
                                        // Special icons for OFF state
                                        !isDeviceOn && (deviceType == 'Dimmer')
                                            ? 'assets/icons/Off_State_Icons/Dimmer.svg'
                                            : !isDeviceOn &&
                                                (deviceType ==
                                                        'Relay' ||
                                                    deviceType == 'Relay')
                                            ? 'assets/icons/Off_State_Icons/Relay.svg'
                                            : iconPath,
                                        width: 24,
                                        height: 24,
                                        colorFilter:
                                            (!isDeviceOn &&
                                                    deviceType != 'Dimmer' &&
                                                    deviceType !=
                                                        'Relay' &&
                                                    deviceType != 'Relay')
                                                ? const ColorFilter.mode(
                                                  Color(0xFF666666),
                                                  BlendMode.srcIn,
                                                )
                                                : null,
                                      ),
                            ),
                          )
                          : Icon(
                            Icons.device_unknown,
                            size: 30,
                            color: isDeviceOn ? null : Colors.grey,
                          ),

                      const SizedBox(width: 7),

                      // SWITCH (hide for Group devices & Sensors)
                      if (!deviceType.toLowerCase().contains("sensor") &&
                          !deviceType.toLowerCase().contains("rgb strip") &&
                          !isGroupDevice)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            child: Container(
                              width: 50.0,
                              height: 30.0,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      isOn
                                          ? Colors.blue
                                          : const Color(0xFF666666),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),

                                child: FlutterSwitch(
                                  width: 50.0,
                                  height: 30.0,
                                  toggleSize: 26.0,
                                  value: _deviceStates[device.deviceId] ?? false,
                                  borderRadius: 20.0,
                                  padding: 0.0,
                                  activeColor: const Color(0xFF00A1F1),
                                  inactiveColor: Colors.white,
                                  activeToggleColor: Colors.white,
                                  inactiveToggleColor: const Color(0xFF444444),
                                  onToggle: (bool value) async {
                                    // 1️⃣ Update in-memory switch state immediately
                                    setState(() {
                                      _deviceStates[device.deviceId] = value;
                                    });

                                    // 2️⃣ Save switch state to SharedPreferences
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setBool('${device.deviceId}_isOn', value);

                                    // 3️⃣ Load the latest device JSON from saved_devices
                                    final savedDevices = prefs.getStringList('saved_devices') ?? [];
                                    final deviceJsonStr = savedDevices.firstWhere(
                                          (d) => jsonDecode(d)['deviceId'] == device.deviceId,
                                      orElse: () => '{}',
                                    );
                                    final deviceJson = jsonDecode(deviceJsonStr);

                                    // 4️⃣ Get brightness from JSON
                                    int brightness = deviceJson['brightness'] ?? 128;
                                    String elementId = device.element;
                                    String message;

                                    String listItem = device.listItemName.toLowerCase();
                                    final mqttService = Provider.of<MQTTService>(context, listen: false);

                                    // 5️⃣ Generate MQTT command based on device type
                                    if (listItem == "individual subnode" || listItem == "individual strip") {
                                      message = value
                                          ? '#*2*$elementId*$brightness*#'
                                          : '#*2*$elementId*0*#';
                                    } else if (listItem == "ac") {
                                      String tempKey = 'saved_temperature_${device.deviceId}';
                                      if (value) {
                                        await prefs.remove(tempKey);
                                        await prefs.setInt(tempKey, 25);
                                      }
                                      message = value
                                          ? '#*2*$elementId*2*9*#'
                                          : '#*2*$elementId*2*0*#';
                                    } else if (listItem == "relay") {
                                      message = value
                                          ? '#*2*$elementId*2*1*#'
                                          : '#*2*$elementId*2*0*#';
                                    } else if (listItem == "fan") {
                                      String firstOnKey = '${device.deviceId}_fan_firstOnDone';
                                      bool firstOnDone = prefs.getBool(firstOnKey) ?? false;

                                      if (value) {
                                        if (!firstOnDone) {
                                          message = '#*2*$elementId*2*4*#';
                                          await prefs.setBool(firstOnKey, true);
                                        } else {
                                          message = '#*2*$elementId*2*$brightness*#';
                                        }
                                      } else {
                                        message = '#*2*$elementId*2*0*#';
                                      }
                                    } else if (listItem == "exhaust") {
                                      String firstOnKey = '${device.deviceId}_exhaust_firstOnDone';
                                      bool firstOnDone = prefs.getBool(firstOnKey) ?? false;

                                      if (value) {
                                        if (!firstOnDone) {
                                          message = '#*2*$elementId*2*2*#';
                                          await prefs.setBool(firstOnKey, true);
                                        } else {
                                          message = '#*2*$elementId*2*$brightness*#';
                                        }
                                      } else {
                                        message = '#*2*$elementId*2*0*#';
                                      }
                                    }
                                    else if (listItem == 'smps') {
                                      final ids = elementId.toString().split(',');

                                      if (ids.length < 2) {
                                        debugPrint('❌ Invalid element ID format: $elementId');
                                        return;
                                      }

                                      final relayElementId = ids[0].trim();
                                      final stripElementId = ids[1].trim();

                                      // ✅ Commands
                                      final String relayMessage = '#*2*$relayElementId*2*${value ? 1 : 0}*#';
                                      final String stripMessage = '#*2*$stripElementId*2*${value ? brightness : 0}*#';

                                      if (mqttService.isConnected) {
                                        if (value) {
                                          // 🔹 Turning ON: relay first, then strip
                                          mqttService.publish(device.topic, relayMessage);
                                          await Future.delayed(const Duration(seconds: 2));
                                          mqttService.publish(device.topic, stripMessage);
                                        } else {
                                          // 🔹 Turning OFF: strip first, then relay
                                          mqttService.publish(device.topic, stripMessage);
                                          await Future.delayed(const Duration(seconds: 2));
                                          mqttService.publish(device.topic, relayMessage);
                                        }
                                      } else {
                                        print("⚠️ MQTT NOT CONNECTED! Cannot send SMPS messages");
                                      }
                                    }

                                    else {
                                      // Default case for single element devices
                                      message = value
                                          ? '#*2*$elementId*2*$brightness*#'
                                          : '#*2*$elementId*2*0*#';

                                      if (mqttService.isConnected) {
                                        mqttService.publish(device.topic, message);
                                      } else {
                                        print("⚠️ MQTT NOT CONNECTED! Cannot send: $message");
                                      }
                                    }


                                    // 7️⃣ Notify the card page to refresh
                                    deviceRefreshNotifier.value = !deviceRefreshNotifier.value;

                                    // 8️⃣ Save the switch state and brightness back to saved_devices JSON
                                    await _saveStateForDevice(device, brightness: brightness, isOn: value);
                                  },
                                ),

                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 5),

              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // DEVICE NAME
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          device.location,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),

                  // STATUS + BRIGHTNESS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOn ? "On" : "Off",
                        style: TextStyle(
                          fontSize: 16,
                          color: isOn ? Colors.blue : Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      // Brightness / Speed display
                      Flexible(
                        child: isOn
                            ? FutureBuilder<List<String>>(
                          future: SharedPreferences.getInstance().then((prefs) => prefs.getStringList('saved_devices') ?? []),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();

                            final savedDevices = snapshot.data!;
                            final deviceJsonStr = savedDevices.firstWhere(
                                  (d) => jsonDecode(d)['deviceId'] == device.deviceId,
                              orElse: () => '{}',
                            );
                            final deviceJson = jsonDecode(deviceJsonStr);

                            final type = device.listItemName;
                            final brightness = deviceJson['brightness'] ?? 0;

                            // Skip AC, Relay, RGB Strip, and Groups
                            if (["AC","Relay","RGB Strip","Group Fan","Group Strip","Group Light","Group Single Light"].contains(type)) {
                              return const SizedBox.shrink();
                            }

                            // Dimmer: show brightness as %
                            if (type == "Dimmer") {
                              return Padding(
                                padding: const EdgeInsets.only(right: 9.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/Devices_Cards_Icons/Device_Brightness.svg',
                                      width: 17,
                                      height: 17,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$brightness%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Light types: calculate brightness %
                            if (["SubNode Supply","Strip Light","Individual Subnode","Individual Strip", "SMPS"].contains(type)) {
                              final percentage = brightness > 0 ? ((brightness / 255) * 100).clamp(1, 100).round() : 0;

                              return Padding(
                                padding: const EdgeInsets.only(right: 9.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/Devices_Cards_Icons/Device_Brightness.svg',
                                      width: 17,
                                      height: 17,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Fan / Exhaust: show numeric value
                            if (type == "Fan" || type == "Exhaust") {
                              return Padding(
                                padding: const EdgeInsets.only(right: 9.0),
                                child: Text(
                                  '$brightness',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        )
                            : const SizedBox.shrink(),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
