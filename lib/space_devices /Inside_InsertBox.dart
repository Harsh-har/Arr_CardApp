// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:flutter_switch/flutter_switch.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smart_control/control_box/individual_box.dart';
// import '../All_Rooms_Access/On_Tap_Function/Handle_Tap.dart';
// import '../Cards_Insert_Box./Group_Insert_Box.dart';
// import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
// import '../Main_Screens/list_screen.dart';
// import '../control_box/Exhaust.dart';
// import '../control_box/ac.dart';
// import '../control_box/cob.dart';
// import '../control_box/curtain.dart';
// import '../control_box/fan.dart';
// import '../control_box/relay.dart';
// import '../control_box/strip_light.dart';
// import '../control_box/subnode_supply.dart';
// import '../Devices_Structure/Devices_Structure_Json.dart';
// import '../utils/sharepreference_data.dart';
// import 'Insert_Box_Spaces.dart';
//
// class SpaceDetailScreen extends StatefulWidget {
//   final String roomName;
//   final String spaceName;
//
//   const SpaceDetailScreen({super.key, required this.spaceName, required this.roomName});
//
//   @override
//   State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
// }
//
// class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
//
//   late final String spaceName;
//
//   final Map<String, String> deviceIconSvgMapping = {
//     'Dimmer': 'assets/icons/Card_Icons/ListDimmer.svg',
//     'SubNode Supply': 'assets/icons/Card_Icons/ListSubnode.svg',
//     'Strip Light': 'assets/icons/Card_Icons/ListStrip.svg',
//     'Fan': 'assets/icons/Card_Icons/ListFan.svg',
//     'AC': 'assets/icons/Card_Icons/ListAC.svg',
//     'Curtains': 'assets/icons/Card_Icons/ListBlinds.svg',
//     'Exhaust': 'assets/icons/Card_Icons/ListExhaust.svg',
//     'Appliance (Relay)': 'assets/icons/Card_Icons/ListRelay.svg',
//     'Sensors (Occupancy)': 'assets/icons/Card_Icons/ListFan.svg',
//     'Individual Subnode': 'assets/icons/Card_Icons/ListSubnode.svg',
//     'Individual Strip': 'assets/icons/Card_Icons/ListStrip.svg',
//     'Group device': 'assets/icons/Card_Icons/ListGroup.svg',
//   };
//
//   late List<Device> _devices = [];
//   late Map<String, bool> _deviceStates = {};
//
//   List<Device> get spaceDevices =>
//       _devices.where((d) => d.roomName == widget.spaceName).toList();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadDevices();
//   }
//
//   Future<void> _reloadDevices() async {
//     await _loadDevices();
//   }
//
//   Future<void> _loadDevices() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? savedDevices = prefs.getStringList('saved_devices');
//
//     if (savedDevices == null || savedDevices.isEmpty) {
//       print("⚠️ No saved devices.");
//       return;
//     }
//
//     List<Device> loaded = [];
//     Map<String, bool> loadedStates = {};
//
//     for (String item in savedDevices) {
//       try {
//         Map<String, dynamic> json = jsonDecode(item);
//         Device device = Device.fromJson(json);
//         loaded.add(device);
//         bool isOn = prefs.getBool('${device.name}_isOn') ?? false;
//         loadedStates[device.name] = isOn;
//
//         // if (device.topic.isNotEmpty) {
//         //   String msg = "#*2*${device.element}*1*1*#";
//         //   mqttService.queueMessage(device.topic, msg);
//         // }
//
//       } catch (e) {
//         print("❌ JSON error: $e");
//       }
//     }
//
//     setState(() {
//       _devices = loaded;
//       _deviceStates = loadedStates;
//     });
//   }
//
//   Future<void> _deleteDevice(int index) async {
//     if (index < 0 || index >= _devices.length) return;
//
//     final deviceToDelete = _devices[index];
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Delete Device"),
//         content: Text("Are you sure you want to delete ${deviceToDelete.name}?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context); // Close the dialog first
//
//               SharedPreferences prefs = await SharedPreferences.getInstance();
//
//               setState(() {
//                 _deviceStates.remove(deviceToDelete.name);
//                 _devices.removeAt(index);
//               });
//
//               // Save updated devices list
//               _saveDevices(); // ✅ this will handle deduplication too
//
//               // Load current topic/room/subscribe lists
//               List<String> savedTopics = prefs.getStringList('saved_topics') ?? [];
//               List<String> savedSubscribeTopics = prefs.getStringList('saved_subscribeTopics') ?? [];
//               List<String> savedRooms = prefs.getStringList('saved_rooms') ?? [];
//
//               // If no other device uses this topic/room/subscribeTopic, remove it
//               bool topicStillUsed = _devices.any((d) => d.topic == deviceToDelete.topic);
//               bool subscribeStillUsed = _devices.any((d) => d.subscribeTopic == deviceToDelete.subscribeTopic);
//               bool roomStillUsed = _devices.any((d) => d.roomName == deviceToDelete.roomName);
//
//               if (!topicStillUsed && deviceToDelete.topic.isNotEmpty) {
//                 savedTopics.remove(deviceToDelete.topic);
//                 await prefs.setStringList('saved_topics', savedTopics);
//               }
//
//               if (!subscribeStillUsed && deviceToDelete.subscribeTopic.isNotEmpty) {
//                 savedSubscribeTopics.remove(deviceToDelete.subscribeTopic);
//                 await prefs.setStringList('saved_subscribeTopics', savedSubscribeTopics);
//               }
//
//               if (!roomStillUsed && deviceToDelete.roomName.isNotEmpty) {
//                 savedRooms.remove(deviceToDelete.roomName);
//                 await prefs.setStringList('saved_rooms', savedRooms);
//               }
//
//               // Remove saved state
//               await prefs.remove('${deviceToDelete.name}_isOn');
//             },
//             child: const Text("Delete", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _saveDevices() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     List<String> encoded = _devices.map((d) => jsonEncode({
//       'name': d.name,
//       'listItemName': d.listItemName,
//       'topic': d.topic,
//       'subscribeTopic': d.subscribeTopic,
//       'element': d.element,
//       'roomName': d.roomName,
//       'icon': d.icon.codePoint,
//     })).toSet().toList(); // remove duplicates
//
//     await prefs.setStringList('saved_devices', encoded);
//   }
//
//   void _showOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext bottomSheetContext) {
//         return ListScreen(
//           onItemSelected: (selectedOption) async {
//             Navigator.pop(bottomSheetContext);
//             await Future.delayed(const Duration(milliseconds: 100));
//
//             List<String> predefinedDevices = [
//               'Dimmer',
//               'SubNode Supply',
//               'Strip Light',
//               'Fan',
//               'AC',
//               'Curtains',
//               'Exhaust',
//               'Appliance (Relay)',
//               'Sensors (Occupancy)',
//             ];
//
//             List<String> predefinedIndividualDevices = [
//               'Individual Subnode',
//               'Individual Strip',
//             ];
//
//             if (selectedOption == 'Group device') {
//               await showGroupDataDialog(
//                 context: context,
//                 selectedOption: selectedOption,
//                 roomName: widget.roomName,
//                 updateTopicsCallback: _updateTopics,
//                 updateGridCallback: _addDevice,
//               );
//             }
//
//             else if (predefinedIndividualDevices.contains(selectedOption)) {
//               await _addDeviceToMyISpace(selectedOption);
//             }
//
//             else if (predefinedDevices.contains(selectedOption)) {
//               await _addDeviceToMySpace(selectedOption);
//             }
//
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> _addDeviceToMySpace(String selectedOption) async {
//     String roomName = widget.roomName;
//     String spaceName = widget.spaceName;
//
//     Device? newDevice = await showGlobalInsertBox(
//       context,
//       selectedOption,
//       roomName,
//       spaceName,
//       _updateTopics,
//           (Device device) {
//         _addDevice(device);
//       },
//     );
//
//     if (newDevice != null) {
//       setState(() {
//         _deviceStates[newDevice.name] = false;
//       });
//     }
//   }
//
//   Future<void> _addDeviceToMyISpace(String selectedOption) async {
//     String roomName = widget.roomName;
//     String spaceName = widget.spaceName;
//
//     Device? newDevice = await showGlobalInsertBox(
//       context,
//       selectedOption,
//       roomName,
//       spaceName,
//       _updateTopics,
//           (Device device) {
//         _addDevice(device);
//       },
//     );
//
//     if (newDevice != null) {
//       setState(() {
//         _deviceStates[newDevice.name] = false;
//       });
//     }
//   }
//
//   void _updateTopics(String newTopic) {
//     _saveTopicsToSharedPrefs(); //
//   }
//
//   Future<void> _saveTopicsToSharedPrefs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//   }
//
//   void _addDevice(Device newDevice) {
//     setState(() {
//       bool exists = _devices.any((d) =>
//       d.name == newDevice.name && d.listItemName == newDevice.listItemName);
//       if (exists) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("⚠️ Device '${newDevice.name}' already exists!"),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//
//       // ✅ Force assign correct room name
//       newDevice.roomName = widget.spaceName;
//
//       _devices.add(newDevice);
//       _saveDevices();
//     });
//   }
//
//   void _showConnectionMessage(BuildContext context) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("⚠️ First connect to the broker!"),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
//
//   void _handleDeviceTap(BuildContext context, Device device, int index) {
//     handleDeviceTap(
//       context: context,
//       device: device,
//       index: index,
//       devices: _devices,
//       deviceStates: _deviceStates,
//       setState: setState,
//       saveDevices: _saveDevices,
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final mqttService = Provider.of<MQTTService>(context);
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: Text(widget.spaceName, style: const TextStyle(color: Colors.white)),
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//         ),
//         backgroundColor: Colors.black,
//         centerTitle: true,
//
//         actions: [
//             IconButton(
//               icon: const Icon(Icons.add, color: Colors.white, size: 34),
//               onPressed: mqttService.isConnected
//                   ? _showOptions
//                   : () => _showConnectionMessage(context),
//             ),
//         ],
//       ),
//
//         body: Column(
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 500),
//                   transitionBuilder: (child, animation) =>
//                       FadeTransition(opacity: animation, child: child),
//                   child: spaceDevices.isEmpty
//                       ? Center(
//                     key: const ValueKey("empty"),
//                     child: Text(
//                       "NO DEVICES IN ${widget.spaceName}",
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   )
//                       : RefreshIndicator(
//                     key: const ValueKey("grouped_grid"),
//                     onRefresh: _reloadDevices,
//                     child: ListView(
//                       children: _buildGroupedDeviceSections(),
//                     ),
//                   ),
//                 ),
//
//               ),
//             ),
//           ],
//         )
//
//     );
//   }
//
//   List<Widget> _buildGroupedDeviceSections() {
//     Map<String, String> displayNames = {
//       "Subnode Supply": "Light",
//       "Group Device": "Group Lights",
//       "Fans": "Fans",
//       "Relays": "Relay",
//       "Strip Light": "Strip Light",
//       "Dimmer": "Dimmer",
//       "AC": "AC",
//       "Exhaust": "Exhaust",
//       "Curtains": "Curtains",
//       "Individual Subnode": "Individual Light",
//       "Individual Strip": "Individual Strip",
//     };
//
//     Map<String, List<Device>> groupedDevices = {
//       "Subnode Supply": [],
//       "Group Device":[],
//       "Fans": [],
//       "Relays": [],
//       "Strip Light": [],
//       "Dimmer": [],
//       "AC": [],
//       "Exhaust": [],
//       "Curtains": [],
//       "Individual Subnode": [],
//       "Individual Strip": [],
//       "Others": [],
//
//     };
//
//     for (var device in _devices.where((d) => d.roomName == widget.spaceName)) {
//       String name = device.listItemName.toLowerCase();
//
//       if (name.contains("subnode supply")) {
//         groupedDevices["Subnode Supply"]!.add(device);
//       }
//       else if (name.contains("fan")) {
//         groupedDevices["Fans"]!.add(device);
//       }
//       else if (name.contains("individual subnode")) {
//         groupedDevices["Individual Subnode"]!.add(device);
//       }
//       else if (name.contains("individual strip")) {
//         groupedDevices["Individual Strip"]!.add(device);
//       }
//       else if (name.contains("appliance (relay)") || name.contains("relay")) {
//         groupedDevices["Relays"]!.add(device);
//       } else if (name.contains("strip light")) {
//         groupedDevices["Strip Light"]!.add(device);
//       } else if (name.contains("dimmer")) {
//         groupedDevices["Dimmer"]!.add(device);
//       } else if (name.contains("ac")) {
//         groupedDevices["AC"]!.add(device);
//       } else if (name.contains("exhaust")) {
//         groupedDevices["Exhaust"]!.add(device);
//       } else if (name.contains("curtain")) {
//         groupedDevices["Curtains"]!.add(device);
//       }
//       else if (name.contains("group device")) {
//         groupedDevices["Group Device"]!.add(device);
//       }
//       else {
//         groupedDevices["Others"]!.add(device);
//       }
//     }
//
//     List<Widget> sections = [];
//
//     groupedDevices.forEach((category, devices) {
//       if (devices.isEmpty) return;
//
//       sections.add(
//         Padding(
//           padding: const EdgeInsets.only(bottom: 5),
//           child: Row(
//             children: [
//               Container(
//                 margin: const EdgeInsets.only(left: 0, bottom: 10),
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   displayNames[category] ?? category,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     color: Colors.white,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//
//
//       sections.add(
//         GridView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: devices.length,
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             crossAxisSpacing: 6,
//             mainAxisSpacing: 6,
//             childAspectRatio: 1.18,
//           ),
//           itemBuilder: (context, index) {
//             final device = devices[index];
//             final bool isOn = _deviceStates[device.name] ?? false;
//
//             return TweenAnimationBuilder<Offset>(
//               duration: const Duration(milliseconds: 400),
//               tween: Tween<Offset>(
//                 begin: const Offset(0, 0.3),
//                 end: Offset.zero,
//               ),
//               builder: (context, offset, child) {
//                 return Transform.translate(
//                   offset: offset,
//                   child: AnimatedOpacity(
//                     duration: const Duration(milliseconds: 400),
//                     opacity: 1.0,
//                     child: Card(
//                       color: const Color(0xFF171717),
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: InkWell(
//                         onTap: () => _handleDeviceTap(context, device, _devices.indexOf(device)),
//                         borderRadius: BorderRadius.circular(20),
//                         child: _devicesCardBuild(
//                           context: context,
//                           device: device,
//                           isOn: isOn,
//                           index: _devices.indexOf(device),
//                           deviceStates: _deviceStates,
//                           onDelete: _deleteDevice,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       );
//       sections.add(const SizedBox(height: 25));
//     }
//     );
//
//     return sections;
//   }
//
//   Widget _devicesCardBuild({required BuildContext context, required Device device, required bool isOn, required int index, required Map<String, bool> deviceStates, required void Function(int) onDelete,}) {   return GestureDetector(
//     onLongPress: () => onDelete(index),
//     child: Material(
//       borderRadius: BorderRadius.circular(10),
//       color: Colors.transparent,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 10),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Builder(
//                 builder: (context) {
//                   final String? iconPath = deviceIconSvgMapping[device.listItemName];
//                   final bool isDeviceOn = isOn;
//                   final deviceCategory = device.listItemName;
//
//                   return Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       iconPath != null
//                           ? SizedBox(
//                         width: 50,
//                         height: 33,
//                         child: FittedBox(
//                           fit: BoxFit.contain,
//                           child: SvgPicture.asset(
//                             !isDeviceOn && (deviceCategory == 'Dimmer')
//                                 ? 'assets/icons/Off_State_Icons/Dimmer.svg'
//                                 : !isDeviceOn && (deviceCategory == 'Appliance (Relay)' || deviceCategory == 'Relay')
//                                 ? 'assets/icons/Off_State_Icons/Relay.svg'
//                                 : iconPath,
//                             width: 24,
//                             height: 24,
//                             colorFilter: (!isDeviceOn &&
//                                 deviceCategory != 'Dimmer' &&
//                                 deviceCategory != 'Appliance (Relay)' &&
//                                 deviceCategory != 'Relay')
//                                 ? const ColorFilter.mode(Color(0xFF666666), BlendMode.srcIn)
//                                 : null,
//                           ),
//                         ),
//                       )
//
//
//                           : Icon(
//                         Icons.device_unknown,
//                         size: 30,
//                         color: isDeviceOn ? null : Colors.grey, // Default color when ON, grey when OFF
//                       ),
//
//                       const SizedBox(width: 7),
//
//                       if (!(device.listItemName.toLowerCase().contains("sensor") ||
//                           device.listItemName.toLowerCase().contains("group device")))
//                         Flexible(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//                             child: Container(
//                               width: 50.0,
//                               height: 30.0,
//                               decoration: BoxDecoration(
//                                 border: Border.all(
//                                   color: isOn ? Colors.blue : const Color(0xFF666666),
//                                   width: 2,
//                                 ),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(20), // clip to rounded border
//                                 child: FlutterSwitch(
//                                   width: 50.0,
//                                   height: 30.0,
//                                   toggleSize: 26.0,
//                                   value: _deviceStates[device.name] ?? false,
//                                   borderRadius: 20.0,
//                                   padding: 0.0,
//                                   activeColor: const Color(0xFF00A1F1),
//                                   inactiveColor: Colors.white,
//                                   activeToggleColor: Colors.white,
//                                   inactiveToggleColor: const Color(0xFF444444),
//                                   onToggle: (bool value) async {
//                                     setState(() {
//                                       _deviceStates[device.name] = value;
//                                     });
//
//                                     SharedPreferences prefs = await SharedPreferences.getInstance();
//                                     await prefs.setBool('${device.name}_isOn', value);
//
//                                     int brightness = prefs.getInt('${device.name}_brightness') ?? 128 ;
//                                     String elementId = device.element;
//                                     String message;
//
//                                     String listItem = device.listItemName.toLowerCase().trim();
//
//                                     if (listItem.contains("individual subnode") || listItem.contains("individual strip")) {
//                                       // Special message for Individual Device
//                                       message = value
//                                           ? '#*2*$elementId*$brightness*#'
//                                           : '#*2*$elementId*0*#';
//                                     } else if (listItem.contains("relay") || listItem.contains("ac")) {
//                                       message = value
//                                           ? '#*2*$elementId*2*1*#'
//                                           : '#*2*$elementId*2*0*#';
//                                     } else {
//                                       message = value
//                                           ? '#*2*$elementId*2*$brightness*#'
//                                           : '#*2*$elementId*2*0*#';
//                                     }
//
//                                     final mqttService = Provider.of<MQTTService>(context, listen: false);
//                                     if (mqttService.isConnected) {
//                                       mqttService.publish(device.topic, message);
//                                     } else {
//                                       print("⚠️ MQTT NOT CONNECTED! Cannot send: $message");
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                         )
//                       else
//                         const SizedBox.shrink()
//                     ],
//                   );
//                 }
//             ),
//             const SizedBox(height: 5),
//
//             Column(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         device.name,
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: isOn ? Colors.white : Colors.white,
//                           fontWeight: FontWeight.w700,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 1,
//                         softWrap: false,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       isOn ? "On" : "Off",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: isOn ? Colors.blue : Colors.grey[600],
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//
//                     // Brightness / Speed display
//                     Flexible(
//                       child: isOn
//                           ? Builder(builder: (context) {
//                         final type = device.listItemName;
//
//                         // Skip AC and Group types
//                         if (type == "AC") return const SizedBox.shrink();
//                         if ([
//                           "Group Fan",
//                           "Group Strip",
//                           "Group Light",
//                           "Group Single Light"
//                         ].contains(type)) {
//                           return const SizedBox.shrink();
//                         }
//
//                         // Dimmer: show brightness with icon
//                         if (type == "Dimmer") {
//                           return FutureBuilder<int>(
//                             future: getDeviceValue(
//                               device.name,
//                               isDimmer: true,
//                               isFan: false,
//                               isExhaust: false,
//                             ),
//                             builder: (context, snapshot) {
//                               if (!snapshot.hasData) return const SizedBox.shrink();
//                               final brightness = snapshot.data!;
//                               return Padding(
//                                 padding: const EdgeInsets.only(right: 9.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     SvgPicture.asset(
//                                       'assets/icons/Devices_Cards_Icons/Device_Brightness.svg',
//                                       width: 17,
//                                       height: 17,
//                                       color: Colors.grey[500],
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       '$brightness%',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         color: Colors.grey[600],
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           );
//                         }
//                         // Lights: show brightness percentage
//                         if ([
//                           "SubNode Supply",
//                           "Strip Light",
//                           "Individual Subnode",
//                           "Individual Strip"
//                         ].contains(type)) {
//                           return FutureBuilder<int>(
//                             future: getDeviceValue(
//                               device.name,
//                               isDimmer: false,
//                               isFan: false,
//                               isExhaust: false,
//                             ),
//                             builder: (context, snapshot) {
//                               if (!snapshot.hasData) return const SizedBox.shrink();
//                               final brightness = snapshot.data!;
//                               final percentage = brightness > 0
//                                   ? ((brightness / 255) * 100).clamp(1, 100).round()
//                                   : 0;
//                               return Padding(
//                                 padding: const EdgeInsets.only(right: 9.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     SvgPicture.asset(
//                                       'assets/icons/Devices_Cards_Icons/Device_Brightness.svg',
//                                       width: 17,
//                                       height: 17,
//                                       color: Colors.grey[500],
//                                     ),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       '$percentage%',
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         color: Colors.grey[600],
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           );
//                         }
//
//                         // Fan / Exhaust: show numeric value
//                         return FutureBuilder<int>(
//                           future: getDeviceValue(
//                             device.name,
//                             isDimmer: type == "Dimmer",
//                             isFan: type == "Fan",
//                             isExhaust: type == "Exhaust",
//                           ),
//                           builder: (context, snapshot) {
//                             if (!snapshot.hasData) return const SizedBox.shrink();
//                             final value = snapshot.data!;
//                             return Padding(
//                               padding: const EdgeInsets.only(right: 9.0),
//                               child: Text(
//                                 '$value',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.grey[600],
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             );
//                           },
//                         );
//                       })
//                           : const SizedBox.shrink(),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     ),
//   );}
//
// }
