// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
//
// class GroupSubnode extends StatefulWidget {
//   final Device device;
//   final bool isOn;
//   final Function(bool) onToggle;
//   final Function(String) onNameChanged;
//   final MQTTService mqttService;
//
//   const GroupSubnode({
//     super.key,
//     required this.device,
//     required this.isOn,
//     required this.onToggle,
//     required this.onNameChanged,
//     required this.mqttService,
//   });
//
//   @override
//   State<GroupSubnode> createState() => _GroupLightState();
// }
//
// class _GroupLightState extends State<GroupSubnode> {
//   final int _segments = 255;
//   late int _brightness = 128; // Start in the middle or your desired default
//   late String name;
//   late String _elementId;
//   late String _roomName;
//   late bool _isOn;
//   String _mqttTopic = '';
//   bool _showFirstContainer = false;
//   bool _showSecondContainer = false;
//   Timer? _pauseTimer;
//   List<String> _elements = [];
//
//
//   @override
//   void initState() {
//     super.initState();
//     // 🔒 Lock to portrait mode only
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//     ]);
//     name = widget.device.name;
//     _roomName = widget.device.roomName;
//     _elementId = widget.device.element;
//     _isOn = widget.isOn;
//     _loadSavedState();
//   }
//
//   @override
//   void dispose() {
//     _pauseTimer?.cancel();  // Stops pending timer safely
//     super.dispose();
//   }
//
//   void _loadSavedState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _isOn = prefs.getBool('${widget.device.name}_isOn') ?? widget.isOn;
//       _brightness = prefs.getInt('${widget.device.name}_brightness') ?? 128;
//       _brightness = _brightness.clamp(0, 255); // Keep within range
//       _mqttTopic = prefs.getString('${widget.device.name}_topic') ?? widget.device.topic;
//       _roomName = prefs.getString('${widget.device.name}_room') ?? widget.device.roomName;
//       _elements = (prefs.getString('${widget.device.name}_elements') ?? widget.device.element)
//
//           .split(',')
//           .map((e) => e.trim())
//           .where((e) => e.isNotEmpty)
//           .toList();
//
//     });
//
//     print("📡 Loaded MQTT Topic: $_mqttTopic");
//     print("🏠 Loaded Room: $_roomName");
//     print("🔆 Loaded Brightness: $_brightness");
//     print("🧩 Loaded Elements: $_elements");
//
//   }
//
//   void _saveState() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('${widget.device.name}_isOn', _isOn);
//     await prefs.setInt('${widget.device.name}_brightness', _brightness);
//     await prefs.setString('${widget.device.name}_topic', _mqttTopic);
//     await prefs.setString('${widget.device.name}_room', _roomName);
//     await prefs.setString('${widget.device.name}_element', _elementId);
//   }
//
//   Future<void> _updateBrightness(double value) async {
//     setState(() {
//       _brightness = value.round().clamp(0, 255);
//       _saveState();
//     });
//
//     if (!widget.mqttService.isConnected) {
//       print("⚠️ MQTT NOT CONNECTED! Cannot send brightness update.");
//       return;
//     }
//
//     for (String elementId in _elements) {
//       String message = '#*2*$elementId*2*$_brightness*#';
//       print("✅ Publishing: $_mqttTopic -> $message");
//       widget.mqttService.publish(_mqttTopic, message);
//
//       await Future.delayed(const Duration(milliseconds:10));
//
//     }
//   }
//
//   Future<String?> _editFieldDialog(String title, String currentValue, String label) {
//     final controller = TextEditingController(text: currentValue);
//     return showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: TextField(
//           controller: controller,
//           decoration: InputDecoration(labelText: label),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _toggleSwitch(bool value) async {
//     setState(() => _isOn = value);
//     widget.onToggle(value);
//     _saveState();
//
//     if (!widget.mqttService.isConnected) {
//       print("⚠️ MQTT NOT CONNECTED! Cannot send toggle message.");
//       return;
//     }
//
//     for (String elementId in _elements) {
//       String message = value
//           ? '#*2*$elementId*2*$_brightness*#'
//           : '#*2*$elementId*2*0*#';
//
//       print("✅ Publishing: $_mqttTopic -> $message");
//       widget.mqttService.publish(_mqttTopic, message);
//
//       await Future.delayed(const Duration(milliseconds:10));
//     }
//   }
//
//   Future<void> editDeviceRoom(Device device, String newRoomName) async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
//
//     List<String> updatedDevices = savedDevices.map((deviceJson) {
//       final deviceMap = json.decode(deviceJson);
//       if (deviceMap['name'] == device.name && deviceMap['listItemName'] == device.listItemName) {
//         deviceMap['roomName'] = newRoomName; // 🟢 Update room
//       }
//       return json.encode(deviceMap);
//     }).toList();
//
//     await prefs.setStringList('saved_devices', updatedDevices);
//   }
//
//   Future<void> editDeviceName(Device device, String newName) async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];
//
//     List<String> updatedDevices = savedDevices.map((deviceJson) {
//       final deviceMap = json.decode(deviceJson);
//       if (deviceMap['name'] == device.name && deviceMap['listItemName'] == device.listItemName) {
//         deviceMap['name'] = newName; // ✅ update the name field
//       }
//       return json.encode(deviceMap);
//     }).toList();
//
//     await prefs.setStringList('saved_devices', updatedDevices);
//   }
//
//   void _editDevice() async {
//     final newName = await _editFieldDialog('Edit Device Name', widget.device.name, 'Device Name');
//
//     if (newName != null && newName.isNotEmpty && newName != widget.device.name) {
//       await editDeviceName(widget.device, newName);
//
//       setState(() {
//         name = newName;
//         widget.device.name = newName;
//       });
//     }
//   }
//
//   void _editRoom() async {
//     final newRoom = await _editFieldDialog('Edit Room Name', _roomName, 'Room Name');
//
//     if (newRoom != null && newRoom.isNotEmpty && newRoom != _roomName) {
//       await editDeviceRoom(widget.device, newRoom);
//
//       setState(() {
//         _roomName = newRoom;
//         widget.device.roomName = newRoom;
//       });
//     }
//   }
//
//   void _editElement() async {
//     final String oldElements = _elements.join(', ');
//
//     String? newElements = await _editFieldDialog(
//         'Edit Element IDs (comma-separated)', oldElements, 'Element IDs');
//
//     if (newElements != null && newElements.isNotEmpty && newElements != oldElements) {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//
//       // Save the new element list
//       await prefs.setString('${widget.device.name}_elements', newElements);
//
//       // Optionally: remove the old single-element key (cleanup)
//       await prefs.remove('${widget.device.name}_element');
//
//       setState(() {
//         _elements = newElements.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
//         _elementId = _elements.isNotEmpty ? _elements.first : '';
//         widget.device.element = _elementId; // Update first one if needed
//       });
//
//       print("✅ New Elements saved: $_elements");
//       print("🗑️ Old Elements removed: $oldElements");
//     }
//   }
//
//   Widget _buildDetailsPanel() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       height: _showFirstContainer ? 900 : 0, // Adjust height as needed
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
//       ),
//       child: _showFirstContainer
//           ? AnimatedOpacity(
//         opacity: _showSecondContainer ? 1.0 : 0.0,
//         duration: const Duration(milliseconds: 500),
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 35),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Device Name:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     "Device Type:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     "Location:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Part of Group:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Part of Scene:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     "Topic:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Element ID:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Application ID:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     "OPCode:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     "Firmware Version:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     "Hardware Version:",
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Light",
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     ":",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     "_spaces",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     ":",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     ":",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     _mqttTopic,
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   Text(
//                     "$_elementId",
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     ":",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     ":",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     ":",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   const Text(
//                     ":",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//
//                 ],
//               ),
//             ],
//           ),
//
//         ),
//
//       )
//           : const SizedBox.shrink(), // Empty widget when not visible
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(130),
//         child: Container(
//           height: 130,
//           color: Colors.black,
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: SafeArea(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _showFirstContainer = !_showFirstContainer;
//                       _showSecondContainer = false;
//                     });
//                     if (_showFirstContainer) {
//                       Future.delayed(const Duration(milliseconds: 100), () {
//                         setState(() => _showSecondContainer = true);
//                       });
//                     }
//                   },
//                   child: Transform.translate(
//                     offset: const Offset(0, 0),
//                     child: SvgPicture.asset(
//                       'assets/icons/Card_Icons/ListGroupLight.svg',
//                       height: 50,
//                       width: 50,
//                     ),
//                   ),
//                 ),
//                 PopupMenuButton<String>(
//                   icon: SvgPicture.asset(
//                     'assets/icons/Setting_Icon/Vector.svg',
//                     height: 24,
//                     width: 24,
//                   ),
//                   onSelected: (value) {
//                     if (value == 'Element') {
//                       _editElement();
//                     } else if (value == 'room') {
//                       _editRoom();
//                     } else if (value == 'Device') {
//                       _editDevice();
//                     }
//                   },
//                   itemBuilder: (context) => const [
//                     PopupMenuItem(value: 'Element', child: Text('Edit Element')),
//                     PopupMenuItem(value: 'room', child: Text('Edit Room')),
//                     PopupMenuItem(value: 'Device', child: Text('Edit Device')),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           double screenHeight = constraints.maxHeight;
//           double screenWidth = constraints.maxWidth;
//
//           double maxSliderHeight = screenHeight * 0.5;
//           double sliderHeight = maxSliderHeight.clamp(270, 420);
//           double sliderWidth = (sliderHeight * 0.35).clamp(90, screenWidth * 0.5);
//           double powerBtnSize = 70 * (sliderHeight / 400);
//           double percentageTextSize = 24 * (sliderHeight / 390);
//           double spacing = screenHeight < 600 ? 5 : 20;
//           double borderRadius = sliderHeight * 0.09;
//
//           return Stack(
//             children: [
//               // Background tap to dismiss panel
//               GestureDetector(
//                 behavior: HitTestBehavior.translucent,
//                 onTap: () {
//                   if (_showFirstContainer) {
//                     setState(() {
//                       _showSecondContainer = false;
//                       _showFirstContainer = false;
//                     });
//                   }
//                 },
//                 child: Center(
//                   child: FittedBox(
//                     fit: BoxFit.fitHeight,
//                     child: IntrinsicHeight(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           // Spacer to avoid overlap
//                           const SizedBox(height: 90),
//
//                           SizedBox(
//                             height: screenHeight * 0.8,
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   '$_brightness / $_segments',
//                                   style: const TextStyle(color: Colors.grey, fontSize: 18),
//                                 ),
//
//                                 SizedBox(height: spacing),
//
//                                 // --- Slider Block ---
//                                 SizedBox(
//                                   height: sliderHeight,
//                                   width: sliderWidth,
//                                   child: Stack(
//                                     alignment: Alignment.bottomCenter,
//                                     children: [
//                                       Container(
//                                         height: 340 * (sliderHeight / 370),
//                                         width: sliderWidth * 0.82,
//                                         decoration: BoxDecoration(
//                                           color: Colors.black,
//                                           borderRadius: BorderRadius.circular(borderRadius),
//                                         ),
//                                         child: ClipRRect(
//                                           borderRadius: BorderRadius.circular(borderRadius),
//                                           child: Stack(
//                                             children: [
//                                               Container(
//                                                 decoration: const BoxDecoration(
//                                                   gradient: LinearGradient(
//                                                     begin: Alignment.centerLeft,
//                                                     end: Alignment.centerRight,
//                                                     colors: [Color(0xFF080808), Color(0xFF252525)],
//                                                   ),
//                                                 ),
//                                               ),
//                                               Align(
//                                                 alignment: Alignment.bottomCenter,
//                                                 child: Container(
//                                                   width: sliderWidth * 0.82,
//                                                   height: (_brightness / _segments) * (340 * (sliderHeight / 370)),
//                                                   color: const Color(0xFFFFBB00),
//                                                 ),
//                                               ),
//                                               if (!_isOn)
//                                                 Container(
//                                                   width: sliderWidth * 0.82,
//                                                   height: 340 * (sliderHeight / 370),
//                                                   color: Colors.black.withOpacity(0.7),
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       Positioned(
//                                         bottom: sliderHeight * 0.13,
//                                         child: Opacity(
//                                           opacity: _isOn ? 1.0 : 0.5,
//                                           child: Text(
//                                             '${((_brightness / 255) * 100).clamp(1, 100).round()}%',
//                                             style: TextStyle(
//                                               color: (_brightness / 255) > (54 / 255)
//                                                   ? Colors.black
//                                                   : Colors.white,
//                                               fontSize: percentageTextSize,
//                                               fontWeight: FontWeight.w700,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       Opacity(
//                                         opacity: _isOn ? 1.0 : 0.4,
//                                         child: RotatedBox(
//                                           quarterTurns: -1,
//                                           child: SizedBox(
//                                             width: 340 * (sliderHeight / 400),
//                                             height: sliderWidth * 0.67 + 60, // Extra padding for gesture comfort
//                                             child: SliderTheme(
//                                               data: SliderTheme.of(context).copyWith(
//                                                 trackHeight: 100 * (sliderHeight / 400),
//                                                 inactiveTrackColor: Colors.transparent,
//                                                 activeTrackColor: Colors.transparent,
//                                                 thumbColor: Colors.transparent,
//                                                 overlayColor: Colors.transparent,
//                                                 thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
//                                                 overlayShape: SliderComponentShape.noOverlay,
//                                               ),
//                                               child: Slider(
//                                                 min: 1,
//                                                 max: 255,
//                                                 divisions: 254,
//                                                 value: _brightness.toDouble().clamp(1.0, 255.0),
//                                                 onChanged: (value) {
//                                                   if (!_isOn) {
//                                                     _toggleSwitch(true);
//                                                     setState(() => _brightness = value.round());
//                                                     _updateBrightness(value);
//                                                     return;
//                                                   }
//                                                   _pauseTimer?.cancel();
//                                                   _pauseTimer = Timer(
//                                                     const Duration(milliseconds: 300),
//                                                         () => _updateBrightness(value),
//                                                   );
//                                                 },
//                                                 onChangeEnd: (value) {
//                                                   _pauseTimer?.cancel();
//                                                   _updateBrightness(value);
//                                                 },
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//
//                                 SizedBox(height: sliderHeight * 0.12),
//
//                                 SizedBox(
//                                   width: powerBtnSize,
//                                   height: powerBtnSize,
//                                   child: GestureDetector(
//                                     onTap: () => _toggleSwitch(!_isOn),
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         shape: BoxShape.circle,
//                                         color: _isOn ? Colors.grey[1000] : const Color(0xFF121212),
//                                       ),
//                                       child: Center(
//                                         child: Icon(
//                                           Icons.power_settings_new,
//                                           color: _isOn ? Colors.grey[500] : const Color(0xFFFFBB00),
//                                           size: 40 * (sliderHeight / 425),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Top Header always visible
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 12),
//                     Text(
//                       name,
//                       style: const TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       _roomName,
//                       style: const TextStyle(fontSize: 20, color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Panel overlay (below name)
//               if (_showFirstContainer || _showSecondContainer)
//                 Positioned.fill(
//                   top: 90, // appear below room name
//                   child: GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         _showFirstContainer = false;
//                         _showSecondContainer = false;
//                       });
//                     },
//                     child: AnimatedOpacity(
//                       opacity: (_showFirstContainer || _showSecondContainer) ? 1.0 : 0.0,
//                       duration:  Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                       child: Container(
//                         color: Colors.black.withOpacity(0.6),
//                         child: Center(
//                           child: GestureDetector(
//                             onTap: () {}, // Prevent outside tap
//                             child: LayoutBuilder(
//                               builder: (context, constraints) {
//                                 return _buildDetailsPanel();
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//
//             ],
//           );
//         },
//       ),
//     );
//   }
// }