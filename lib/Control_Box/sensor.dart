// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
// import 'package:smart_control/MQTT_STRUCTURE/MQTT_SETUP.dart';
//
// class Sensor extends StatefulWidget {
//   final Device device;
//   final bool isOn;
//   final Function(bool) onToggle;
//   final Function(String) onNameChanged;
//   final MQTTService mqttService;
//
//   const Sensor({
//     super.key,
//     required this.device,
//     required this.isOn,
//     required this.onToggle,
//     required this.onNameChanged,
//     required this.mqttService,
//   });
//
//   @override
//   State<Sensor> createState() => _SensorPageState();
// }
//
// class _SensorPageState extends State<Sensor> {
//   late String _deviceName;
//   late bool _isOn;
//   late String _mqttTopic;
//   late String _roomName;
//
//   @override
//   void initState() {
//     super.initState();
//     _deviceName = widget.device.name;
//     _roomName = widget.device.roomName;
//     _isOn = widget.isOn;
//     _mqttTopic = widget.device.topic;
//     _loadSavedState();
//   }
//
//   Future<void> _loadSavedState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _isOn = prefs.getBool('${widget.device.topic}_isOn') ?? widget.isOn;
//       _mqttTopic = prefs.getString('${widget.device.topic}_topic') ?? widget.device.topic;
//       _roomName = prefs.getString('${widget.device.topic}_room') ?? widget.device.roomName;
//       _deviceName = prefs.getString('${widget.device.topic}_name') ?? widget.device.name;
//     });
//
//     print("📡 Loaded MQTT Topic: $_mqttTopic");
//     print("🏠 Loaded Room: $_roomName");
//   }
//
//   Future<void> _saveState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('${widget.device.topic}_isOn', _isOn);
//     await prefs.setString('${widget.device.topic}_topic', _mqttTopic);
//     await prefs.setString('${widget.device.topic}_room', _roomName);
//     await prefs.setString('${widget.device.topic}_name', _deviceName);
//   }
//
//   void _toggleSwitch(bool value) {
//     setState(() {
//       _isOn = value;
//       widget.onToggle(value);
//     });
//     _saveState();
//   }
//
//   void _calibrateDevice() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Calibrating device...'),
//         duration: Duration(seconds: 1),
//         backgroundColor: Colors.blueAccent,
//       ),
//     );
//
//     String elementId = widget.device.element;
//     String message = '#*2*$elementId*200*#'; // ✅ fixed format
//
//     if (widget.mqttService.isConnected) {
//       print("✅ Sending calibration command: $_mqttTopic -> $message");
//       widget.mqttService.publish(_mqttTopic, message);
//     } else {
//       print("⚠️ MQTT NOT CONNECTED! Cannot send calibration command.");
//     }
//   }
//
//   void _editName() async {
//     final TextEditingController controller = TextEditingController(text: _deviceName);
//     String? newName = await showDialog<String>(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Edit Device Name'),
//           content: TextField(
//             controller: controller,
//             decoration: const InputDecoration(labelText: 'Device Name'),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context, controller.text.trim()),
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (newName != null && newName.isNotEmpty) {
//       setState(() => _deviceName = newName);
//       widget.onNameChanged(newName);
//       _saveState(); // ✅ persist new name
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: Text(
//           _deviceName,
//           style: const TextStyle(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit, color: Colors.yellowAccent),
//             onPressed: _editName,
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const SizedBox(height: 20),
//             Text(
//               "Topic: $_mqttTopic",
//               style: const TextStyle(fontSize: 14, color: Colors.cyan),
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 5),
//             Text(
//               "Room: $_roomName",
//               style: const TextStyle(fontSize: 14, color: Colors.orange),
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text('OFF', style: TextStyle(fontSize: 14, color: Colors.red)),
//                 Switch(
//                   value: _isOn,
//                   onChanged: _toggleSwitch,
//                   activeColor: Colors.green,
//                 ),
//                 const Text('ON', style: TextStyle(fontSize: 15, color: Colors.green)),
//               ],
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: _calibrateDevice,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text('CALIBRATE'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
