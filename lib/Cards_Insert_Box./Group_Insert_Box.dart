// import 'dart:convert';
// import 'package:flutter_svg/svg.dart';
// import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
// import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
//
// Future<Device?> showGroupDataDialog({
//   required BuildContext context,
//   required String selectedOption,
//   required String roomName,
//   required Function(String) updateTopicsCallback,
//   required Function(Device) updateGridCallback,
// }) async {
//   final nameController = TextEditingController();
//   final elementController = TextEditingController();
//   final topicController = TextEditingController();
//   final subscribeTopicController = TextEditingController();
//
//   final mqttService = Provider.of<MQTTService>(context, listen: false);
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//
//   topicController.text = prefs.getString('saved_topic_$roomName') ?? '';
//   subscribeTopicController.text = prefs.getString('saved_subscribeTopic_$roomName') ?? '';
//
//   final deviceIconSvgMapping = {
//     'Group Fan': 'assets/icons/Card_Icons/ListGroupFan.svg',
//     'Group Strip': 'assets/icons/Card_Icons/ListGroupStrip.svg',
//     'Group Light': 'assets/icons/Card_Icons/ListGroupLight.svg',
//     'Group Single Light': 'assets/icons/Card_Icons/ListGroupSingleLight.svg',
//   };
//
//
//   bool isDuplicate = false;
//   bool isSubmitDisabled = true;
//
//   Future<void> checkDuplicate(String name) async {
//     List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
//     isDuplicate = savedDevices.any((deviceStr) {
//       try {
//         final json = jsonDecode(deviceStr);
//         return json['name'] == name && json['listItemName'] == selectedOption;
//       } catch (e) {
//         return false;
//       }
//     });
//   }
//
//   Future<void> saveDevice(Device newDevice) async {
//     List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
//     savedDevices.add(jsonEncode(newDevice.toJson()));
//     await prefs.setStringList('saved_devices', savedDevices);
//   }
//
//   Future<void> saveRoom(String newRoom) async {
//     List<String> savedRooms = prefs.getStringList('saved_rooms') ?? [];
//     if (!savedRooms.contains(newRoom)) {
//       savedRooms.add(newRoom);
//       await prefs.setStringList('saved_rooms', savedRooms);
//       updateTopicsCallback(newRoom);
//     }
//   }
//
//   Future<void> saveElementWithTopic(String elementId, String topic) async {
//     List<String> savedElements = prefs.getStringList('saved_elements') ?? [];
//     String entry = "$elementId|$topic";
//     if (!savedElements.contains(entry)) {
//       savedElements.add(entry);
//       await prefs.setStringList('saved_elements', savedElements);
//     }
//   }
//
//
//   return showDialog<Device>(
//     context: context,
//     builder: (context) {
//       return StatefulBuilder(builder: (context, setState) {
//         void validateForm() async {
//           String name = nameController.text.trim();
//           String element = elementController.text.trim();
//           await checkDuplicate(name);
//
//           setState(() {
//             isSubmitDisabled = name.isEmpty || element.isEmpty || isDuplicate;
//           });
//         }
//
//           return AlertDialog(
//             title: Row(
//               children: [
//                 SvgPicture.asset(
//                   deviceIconSvgMapping[selectedOption]!,
//                   width: 28,
//                   height: 28,
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Text(
//                     selectedOption,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: nameController,
//                     decoration: const InputDecoration(labelText: 'Device Name'),
//                     onChanged: (_) => validateForm(),
//                   ),
//                   if (isDuplicate)
//                     const Padding(
//                       padding: EdgeInsets.only(top: 8.0),
//                       child: Text(
//                         "⚠️ Device with this name & type already exists!",
//                         style: TextStyle(color: Colors.red, fontSize: 14),
//                       ),
//                     ),
//                   const SizedBox(height: 10),
//
//                   // 🔒 Predefined room
//                   TextFormField(
//                     readOnly: true,
//                     initialValue: roomName,
//                     decoration: const InputDecoration(
//                       labelText: 'Room Name',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   TextField(
//                     controller: elementController,
//                     decoration: const InputDecoration(
//                       labelText: 'Element_IDs Separate with(,)',
//                       border: OutlineInputBorder(),),
//                     onChanged: (_) => validateForm(),
//                   ),
//                   const SizedBox(height: 10),
//
//                   TextFormField(
//                     readOnly: true,
//                     controller: topicController,
//                     decoration: const InputDecoration(
//                       labelText: 'Publish Topic (Global)',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     readOnly: true,
//                     controller: subscribeTopicController,
//                     decoration: const InputDecoration(
//                       labelText: 'Subscribe Topic (Global)',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   const Text(
//                     "To change topics, use the Global Topic Controller.",
//                     style: TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: isSubmitDisabled
//                     ? null
//                     : () async {
//                   final name = nameController.text.trim();
//                   final element = elementController.text.trim();
//                   final topic = topicController.text.trim();
//                   final subscribeTopic = subscribeTopicController.text.trim();
//
//
//                   await checkDuplicate(name);
//                   if (isDuplicate) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("⚠️ Device with this name & type already exists!"),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                     return;
//                   }
//                     Device newDevice = Device(
//                       name: name,
//                       listItemName: selectedOption,
//                       topic: topic,
//                       subscribeTopic: subscribeTopic,
//                       element: element,
//                       roomName: roomName,
//                       iconName: selectedOption, deviceId: '',
//                     );
//
//
//                     await saveDevice(newDevice);
//                     await saveRoom(roomName);
//                     await saveElementWithTopic(element, topic);
//
//
//                     List<String> elements = element.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
//                     for (String e in elements) {
//                       await saveElementWithTopic(e, topic);
//                     }
//
//
//                   if (mqttService.isConnected) {
//                     mqttService.publish(topic, "Device: $name, Room: $roomName, Type: $selectedOption, Element: $element");
//                     mqttService.subscribe(subscribeTopic);
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text("✅ Saved & Published: $topic & Saved & Subscribe: $subscribeTopic"),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("⚠️ MQTT not connected!"), backgroundColor: Colors.red),
//                       );
//                     }
//
//                     updateGridCallback(newDevice);
//                     Navigator.of(context).pop(newDevice);
//                   },
//                 child: const Text('Submit'),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }
