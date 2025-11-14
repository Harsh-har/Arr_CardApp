// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../MQTT_STRUCTURE/MQTT_SETUP.dart';
// import 'Active_Provider.dart';
//
// class DynamicSceneScreen extends StatefulWidget {
//   final String roomName;
//   const DynamicSceneScreen({super.key, required this.roomName});
//
//   @override
//   State<DynamicSceneScreen> createState() => _DynamicSceneScreenState();
// }
//
// class _DynamicSceneScreenState extends State<DynamicSceneScreen> {
//   final Map<String, bool> _deviceStates = {};
//   final List<Map<String, dynamic>> _scenes = [];
//   String? _publishTopic;
//   String? _lastLoadedRoom;
//
//   final List<Map<String, dynamic>> devices = [
//     { 'iconPath': 'assets/Scenes_Icons/relax.svg', 'color': Colors.purpleAccent, 'label': 'Active'},
//     { 'iconPath': 'assets/Scenes_Icons/inactive.svg', 'color': Colors.redAccent, 'label': 'InActive'},
//     { 'iconPath': 'assets/Scenes_Icons/lunch.svg', 'color': Colors.amber, 'label': 'Lunch'},
//     { 'iconPath': 'assets/Scenes_Icons/evening.svg', 'color': Colors.orangeAccent, 'label': 'Evening'},
//     { 'iconPath': 'assets/Scenes_Icons/celebration.svg', 'color': Colors.blueAccent, 'label': 'Celebration'},
//     { 'iconPath': 'assets/Scenes_Icons/cleaning.svg', 'color': Colors.brown, 'label': 'Cleaning'},
//     { 'iconPath': 'assets/Scenes_Icons/day.svg', 'color': Colors.yellow, 'label': 'Day Time'},
//     { 'iconPath': 'assets/Scenes_Icons/meet.svg', 'color': Colors.green, 'label': 'Gathering'},
//     { 'iconPath': 'assets/Scenes_Icons/dining.svg', 'color': Colors.indigo, 'label': 'Dinner'},
//     { 'iconPath': 'assets/Scenes_Icons/party.night', 'color': Colors.blueAccent, 'label': 'Night'},
//     { 'iconPath': 'assets/Scenes_Icons/sleep.svg', 'color': Colors.blueAccent, 'label': 'Sleep'},
//     { 'iconPath': 'assets/Scenes_Icons/party2.svg', 'color': Colors.greenAccent, 'label': 'Without Sensor'},
//   ];
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     _loadScenes().then((_) {
//       _loadDeviceStates();
//     });
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final roomProvider = Provider.of<ActiveRoomProvider>(context);
//     final currentRoom = roomProvider.activeRoom ?? widget.roomName;
//     _loadTopicForRoom(currentRoom);
//   }
//
//   Future<void> _loadTopicForRoom(String room) async {
//     if (_lastLoadedRoom == room) return; // prevent reloading same room
//     _lastLoadedRoom = room;
//
//     final prefs = await SharedPreferences.getInstance();
//     final topic = prefs.getString("saved_topic_$room");
//     debugPrint("📡 Loaded publish topic for $room : $topic");
//     setState(() => _publishTopic = topic);
//   }
//
//   Future<void> _loadScenes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final sceneList = prefs.getStringList("scenes_${widget.roomName}") ?? [];
//
//     setState(() {
//       _scenes.clear();
//       for (var scene in sceneList) {
//         final parts = scene.split('|');
//         if (parts.length >= 2) {
//           _scenes.add({
//             'id': int.tryParse(parts[0]) ?? 0,
//             'label': parts[1],
//             'room': parts.length == 3 ? parts[2] : widget.roomName,
//           });
//         }
//       }
//     });
//   }
//
//   Future<void> _saveScenes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final sceneList = _scenes
//         .map((s) => "${s['id']}|${s['label']}|${s['room']}")
//         .toList();
//     await prefs.setStringList("scenes_${widget.roomName}", sceneList);
//   }
//
//   Future<void> _showAddSceneDialog() async {
//     final idController = TextEditingController();
//     String? selectedRoom;
//     String? selectedSceneName;
//
//     final prefs = await SharedPreferences.getInstance();
//     final List<String> rooms = prefs.getStringList('main_rooms') ?? [];
//
//     final List<String> predefinedScenes = [
//       "Active",
//       "InActive",
//       "Lunch",
//       "Without Sensor",
//       "Day Time",
//       "Evening",
//       "Celebration",
//       "Cleaning",
//       "Gathering",
//       "Dinner",
//       "Night",
//       "Sleep",
//     ];
//
//     // preselect current room if exists in list
//     if (rooms.contains(widget.roomName)) {
//       selectedRoom = widget.roomName;
//     }
//
//     await showDialog(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text("Create Scene"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: idController,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: "Scene ID"),
//               ),
//               const SizedBox(height: 10),
//               DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: "Select Scene",
//                   border: OutlineInputBorder(),
//                 ),
//                 value: selectedSceneName,
//                 items: predefinedScenes.map((scene) {
//                   return DropdownMenuItem(
//                     value: scene,
//                     child: Text(scene),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setDialogState(() => selectedSceneName = value);
//                 },
//               ),
//               const SizedBox(height: 10),
//               DropdownButtonFormField<String>(
//                 decoration: const InputDecoration(
//                   labelText: "Select Room",
//                   border: OutlineInputBorder(),
//                 ),
//                 value: selectedRoom,
//                 items: rooms.map((room) {
//                   return DropdownMenuItem(
//                     value: room,
//                     child: Text(room),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setDialogState(() => selectedRoom = value);
//                 },
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 final id = int.tryParse(idController.text.trim());
//                 final room = selectedRoom ?? widget.roomName;
//
//                 if (id != null && selectedSceneName != null) {
//                   setState(() {
//                     // ensure no duplicate IDs within the same room
//                     _scenes.removeWhere(
//                             (s) => s['id'] == id && s['room'] == room);
//
//                     _scenes.add({
//                       'id': id,
//                       'label': selectedSceneName,
//                       'room': room,
//                     });
//                   });
//                   _saveScenes();
//                   Navigator.pop(context);
//                 } else {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Please select scene & enter ID")),
//                   );
//                 }
//               },
//               child: const Text("Save"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _saveDeviceState(String key, bool state) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool("device_state_$key", state);
//     _deviceStates[key] = state; // also update local map
//     setState(() {}); // refresh UI
//   }
//
//   Future<void> _loadDeviceStates() async {
//     final prefs = await SharedPreferences.getInstance();
//
//     setState(() {
//       for (var scene in _scenes) {
//         final id = scene['id'];
//         final room = scene['room'];
//         final key = "${room}_$id";
//
//         final saved = prefs.getBool("device_state_$key");
//         _deviceStates[key] = saved ?? false;
//       }
//     });
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     final mqttService = Provider.of<MQTTService>(context, listen: false);
//     final roomProvider = Provider.of<ActiveRoomProvider>(context);
//     final currentRoom = roomProvider.activeRoom ?? widget.roomName;
//     final filteredScenes =
//     _scenes.where((s) => s['room'] == currentRoom).toList();
//
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 "SCENE",
//                 style: TextStyle(
//                   fontSize: 25,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               IconButton(
//                 onPressed: _showAddSceneDialog,
//                 icon: const Icon(Icons.add, color: Colors.white, size: 30),
//                 constraints: const BoxConstraints(),
//                 splashRadius: 25,
//                 tooltip: "Add Scene",
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
//         Padding(
//           padding: const EdgeInsets.only(bottom: 20, left: 15, right: 10),
//           child: Align(
//             alignment: Alignment.bottomCenter,
//             child: SizedBox(
//               height: 50,
//               child: filteredScenes.isEmpty
//                   ? const Center(
//                 child: Text(
//                   "No Default Scene Available",
//                   style: TextStyle(color: Colors.white70),
//                 ),
//               )
//                   : ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: filteredScenes.length,
//                 separatorBuilder: (_, __) => const SizedBox(width: 10),
//                 itemBuilder: (context, index) {
//                   final scene = filteredScenes[index];
//                   final int id = scene['id'];
//                   final String label = scene['label'];
//                   final String room = scene['room'];
//
//                   // Use room+id as unique key
//                   final String key = "${room}_$id";
//                   final bool isOn = _deviceStates[key] ?? false;
//
//                   // match with devices list
//                   final device = devices.firstWhere(
//                         (d) => d['label'] == label,
//                     orElse: () => {
//                       'iconPath': 'assets/Scenes_Icons/cleaning.svg',
//                       'color': Colors.grey,
//                       'label': label,
//                     },
//                   );
//
//                   return GestureDetector(
//                     onTap: () {
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return AlertDialog(
//                             title: const Text("⚠️ Confirm Device Action"),
//                             content: const Text("Are you sure you want to change this device state?"),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context), // Cancel
//                                 child: const Text("Cancel"),
//                               ),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   Navigator.pop(context);
//
//                                   final newState = !(_deviceStates[key] ?? false);
//
//                                   setState(() {
//                                     if (newState) {
//                                       // 🔑 Turn OFF all other scenes in the SAME ROOM only
//                                       for (var other in _scenes) {
//                                         final otherId = other['id'];
//                                         final otherRoom = other['room'];
//                                         final otherKey = "${otherRoom}_$otherId";
//
//                                         if (otherRoom == room && otherKey != key && (_deviceStates[otherKey] ?? false)) {
//                                           _deviceStates[otherKey] = false;
//                                           _saveDeviceState(otherKey, false);
//                                         }
//                                       }
//                                     }
//
//                                     // Update current scene state
//                                     _deviceStates[key] = newState;
//                                   });
//
//                                   _saveDeviceState(key, newState);
//
//                                   final message = newState ? "#*6*$id*1*1*#" : "#*6*$id*0*1*#";
//
//
//                                   if (mqttService.isConnected && _publishTopic != null) {
//                                     debugPrint("Publishing to $_publishTopic : $message");
//                                     mqttService.publish(_publishTopic!, message);
//                                   } else {
//                                     debugPrint("⚠️ MQTT not connected or topic missing");
//                                   }
//                                 },
//
//
//                                 child: const Text("Yes"),
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                     },
//
//                     onLongPress: () async {
//                       final action = await showModalBottomSheet<String>(
//                         context: context,
//                         builder: (context) {
//                           return SafeArea(
//                             child: Wrap(
//                               children: [
//                                 ListTile(
//                                   leading: const Icon(Icons.edit),
//                                   title: const Text("Edit Scene ID"),
//                                   onTap: () => Navigator.pop(context, "edit"),
//                                 ),
//                                 ListTile(
//                                   leading: const Icon(Icons.delete, color: Colors.red),
//                                   title: const Text("Delete Scene"),
//                                   onTap: () => Navigator.pop(context, "delete"),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       );
//
//                       if (action == "edit") {
//                         final controller = TextEditingController(text: id.toString()); // int -> string
//                         final newIdStr = await showDialog<String>(
//                           context: context,
//                           builder: (_) => AlertDialog(
//                             title: const Text("Edit Scene ID"),
//                             content: TextField(
//                               controller: controller,
//                               keyboardType: TextInputType.number,
//                               decoration: const InputDecoration(labelText: "Scene ID"),
//                             ),
//                             actions: [
//                               TextButton(
//                                   onPressed: () => Navigator.pop(context, null),
//                                   child: const Text("Cancel")),
//                               TextButton(
//                                   onPressed: () => Navigator.pop(context, controller.text.trim()),
//                                   child: const Text("Save")),
//                             ],
//                           ),
//                         );
//
//                         if (newIdStr != null && newIdStr.isNotEmpty) {
//                           final newId = int.tryParse(newIdStr);
//                           if (newId != null && newId != id) {
//                             setState(() {
//                               // Find and update the scene
//                               final scene = _scenes.firstWhere((s) => s['id'] == id && s['room'] == room);
//                               scene['id'] = newId;
//
//                               // Update device state key
//                               final oldKey = "${room}_$id";
//                               final newKey = "${room}_$newId";
//                               if (_deviceStates.containsKey(oldKey)) {
//                                 _deviceStates[newKey] = _deviceStates.remove(oldKey)!;
//                               }
//                             });
//                             _saveScenes(); // re-save with new id
//                           }
//                         }
//                       }
//                       else if (action == "delete") {
//                         final confirm = await showDialog<bool>(
//                           context: context,
//                           builder: (_) => AlertDialog(
//                             title: const Text("Delete Scene"),
//                             content: Text("Are you sure you want to delete Scene ID $id?"),
//                             actions: [
//                               TextButton(
//                                   onPressed: () => Navigator.pop(context, false),
//                                   child: const Text("Cancel")),
//                               TextButton(
//                                   onPressed: () => Navigator.pop(context, true),
//                                   child: const Text("Delete")),
//                             ],
//                           ),
//                         );
//
//                         if (confirm == true) {
//                           setState(() {
//                             _scenes.removeWhere((s) => s['id'] == id && s['room'] == room);
//                             _deviceStates.remove("${room}_$id");
//                           });
//                           _saveScenes();
//                         }
//                       }
//                     },
//
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isOn ? device['color'] : Colors.blueGrey.shade400 ,
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       alignment: Alignment.center,
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           SizedBox(
//                             height: 22,
//                             width: 22,
//                             child: SvgPicture.asset(
//                               device['iconPath'],
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(width: 6),
//                           Text(
//                             label,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                             textAlign: TextAlign.center,
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
