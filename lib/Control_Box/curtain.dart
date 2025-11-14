// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
//
// import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
//
// class Curtain extends StatefulWidget {
//   final Device device;
//   final bool isOn;
//   final Function(bool) onToggle;
//   final Function(String) onNameChanged;
//   final MQTTService mqttService;
//
//   const Curtain({
//     super.key,
//     required this.device,
//     required this.isOn,
//     required this.onToggle,
//     required this.onNameChanged,
//     required this.mqttService,
//   });
//
//   @override
//   State<Curtain> createState() => _CurtainPageState();
// }
//
// class _CurtainPageState extends State<Curtain> {
//   final int _segments = 10;
//   late int _brightness = 4;
//   late String _deviceName;
//   late String _elementId;
//   late String _roomName;
//   late bool _isOn;
//   String _mqttTopic = '';
//   bool _showFirstContainer = false;
//   bool _showSecondContainer = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _deviceName = widget.device.name;
//     _roomName = widget.device.roomName;
//     _elementId = widget.device.element;
//     _isOn = widget.isOn;
//     _loadSavedState();
//   }
//
//   void _loadSavedState() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _isOn = prefs.getBool('${widget.device.name}_isOn') ?? widget.isOn;
//       _brightness = (prefs.getInt('${widget.device.name}_brightness') ?? 4).clamp(0, 10);
//       _mqttTopic = prefs.getString('${widget.device.name}_topic') ?? widget.device.topic;
//       _roomName = prefs.getString('${widget.device.name}_room') ?? widget.device.roomName;
//       _elementId = prefs.getString('${widget.device.name}_element') ?? widget.device.element;
//     });
//   }
//
//   void _saveState() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('${widget.device.name}_isOn', _isOn);
//     await prefs.setInt('${widget.device.name}_brightness', _brightness);
//     await prefs.setString('${widget.device.name}_topic', _mqttTopic);
//     await prefs.setString('${widget.device.name}_room', _roomName);
//     await prefs.setString('${widget.device.name}_element', _elementId);
//   }
//
//   void _updateBrightness(double value) {
//     setState(() => _brightness = value.round().clamp(0, 10));
//     _saveState();
//
//     final message = '#*2*$_elementId*2*$_brightness*#';
//
//     if (widget.mqttService.isConnected) {
//       widget.mqttService.publish(_mqttTopic, message);
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
//   void _toggleSwitch(bool value) {
//     setState(() => _isOn = value);
//     widget.onToggle(value);
//     _saveState();
//
//     final message = value
//         ? '#*2*$_elementId*2*$_brightness*#'
//         : '#*2*$_elementId*2*0*#';
//
//     if (widget.mqttService.isConnected) {
//       widget.mqttService.publish(_mqttTopic, message);
//     }
//   }
//
//   void _editRoom() async {
//     final oldRoom = _roomName;
//     final newRoom = await _editFieldDialog('Edit Room Name', _roomName, 'Room Name');
//
//     if (newRoom != null && newRoom.isNotEmpty && newRoom != oldRoom) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('${widget.device.name}_room');
//       await prefs.setString('${widget.device.name}_room', newRoom);
//
//       setState(() {
//         _roomName = newRoom;
//         widget.device.roomName = newRoom;
//       });
//     }
//   }
//
//   void _editElement() async {
//     final oldElement = _elementId;
//     final newElement = await _editFieldDialog('Edit Element ID', _elementId, 'Element ID');
//
//     if (newElement != null && newElement.isNotEmpty && newElement != oldElement) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('${widget.device.name}_element');
//       await prefs.setString('${widget.device.name}_element', newElement);
//
//       setState(() {
//         _elementId = newElement;
//         widget.device.element = newElement;
//       });
//     }
//   }
//
//   Widget _buildDetailsPanel() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       height: _showFirstContainer ? 650 : 0, // Adjust height as needed
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: const BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: _showFirstContainer
//           ? AnimatedOpacity(
//         opacity: _showSecondContainer ? 1.0 : 0.0,
//         duration: const Duration(milliseconds: 200),
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 18),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text(
//                 "Device Name:",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               Text(
//                 "Device Type:",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               Text(
//                 "Location Type:",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               Text(
//                 "Firmware Version:",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               Text(
//                 "Hardware Version:",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               Text(
//                 "Connection: MQTT Online",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
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
//     return Scaffold(
//       backgroundColor: Colors.black,
//
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(140),
//         child: Container(
//           height: 140, //
//           color: Colors.black,
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: SafeArea(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 // Leading back button
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//                 ),
//
//                 // Center title (SVG with gesture)
//                 GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _showFirstContainer = !_showFirstContainer;
//                       _showSecondContainer = false;
//                     });
//
//                     if (_showFirstContainer) {
//                       Future.delayed(const Duration(milliseconds: 300), () {
//                         setState(() => _showSecondContainer = true);
//                       });
//                     }
//                   },
//                   child: Transform.translate(
//                     offset: Offset(0, 5),
//                     child: SvgPicture.asset(
//                       'assets/icons/Devices_Icons/Blinds.svg',
//                       height: 78,
//                       width: 78,
//                     ),
//                   ),
//                 ),
//
//                 // Action menu
//                 PopupMenuButton<String>(
//                   icon: SvgPicture.asset(
//                     'assets/icons/Setting_Icon/Vector.svg',
//                     height: 30,
//                     width: 30,
//                   ),
//                   onSelected: (value) {
//                     if (value == 'Element') _editElement();
//                     if (value == 'room') _editRoom();
//                   },
//                   itemBuilder: (context) => const [
//                     PopupMenuItem(value: 'Element', child: Text('Edit Element')),
//                     PopupMenuItem(value: 'room', child: Text('Edit Room')),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//
//
//       body: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 5),
//         child: GestureDetector(
//           behavior: HitTestBehavior.translucent,
//           onTap: () {
//             if (_showFirstContainer) {
//               setState(() {
//                 _showSecondContainer = false;
//                 _showFirstContainer = false;
//               });
//             }
//           },
//           child: Stack(
//             children: [
//               AnimatedPositioned(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//                 top: _showFirstContainer ? 0 : 0,
//                 left: 0,
//                 right: 0,
//                 child: GestureDetector(
//                   // Absorb tap events inside panel to avoid triggering outside tap handler
//                   onTap: () {},
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
//                     decoration: const BoxDecoration(
//                       color: Colors.black,
//                       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(_deviceName,style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: Colors.white)),
//                         Text(_roomName, style: const TextStyle(fontSize: 20, color: Colors.grey)),
//                         const SizedBox(height: 3),
//                         Text(_mqttTopic, style: const TextStyle(fontSize: 16,color: Colors.green)),
//                         const SizedBox(height: 3),
//                         Text("Element: $_elementId", style: const TextStyle(fontSize: 16,color: Colors.yellow)),
//                         const SizedBox(height: 10),
//
//
//                         SizedBox(
//                           height: 400,
//                           width: 300,
//                           child: Column(
//                             children: [
//                               Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   // Text(
//                                   //   'SPEED :  $_brightness /$_segments',
//                                   //   style: const TextStyle(color: Colors.white, fontSize: 18),
//                                   // ),
//                                   const SizedBox(height: 35),
//                                   Stack(
//                                     alignment: Alignment.center,
//                                     children: [
//
//
//                                       Container(
//                                         height: 340,
//                                         width: double.infinity,
//                                         decoration: BoxDecoration(
//                                           color: Colors.black,
//                                           borderRadius: BorderRadius.circular(31),
//                                         ),
//                                         child: Column(
//                                           mainAxisAlignment: MainAxisAlignment.end,
//                                           children: List.generate(_segments, (index) {
//                                             bool isActive = index >= (_segments - _brightness);
//                                             return Container(
//                                               margin: const EdgeInsets.symmetric(vertical: 2),
//                                               height: 30,
//                                               width: 200,
//                                               decoration: BoxDecoration(
//                                                 color: isActive
//                                                     ? (_isOn ? Color(0xFFF58700) : Colors.grey)
//                                                     : Colors.grey[900],
//                                                 borderRadius: index == 0
//                                                     ? const BorderRadius.only(
//                                                   topLeft: Radius.circular(25),
//                                                   topRight: Radius.circular(25),
//                                                 )
//                                                     : index == _segments - 1
//                                                     ? const BorderRadius.only(
//                                                   bottomLeft: Radius.circular(25),
//                                                   bottomRight: Radius.circular(25),
//                                                 )
//                                                     : BorderRadius.zero,
//                                               ),
//                                             );
//                                           }),
//                                         ),
//                                       ),
//
//                                       Transform.translate(
//                                         offset: const Offset(52, 0), // Adjust as needed
//                                         child: RotatedBox(
//                                           quarterTurns: -1,
//                                           child: SizedBox(
//                                             width: 340, // Match your fill bar height
//                                             height: 100, // Match your fill bar width
//                                             child: SliderTheme(
//                                               data: SliderTheme.of(context).copyWith(
//                                                 trackHeight: 100, // Match custom bar width
//                                                 inactiveTrackColor: Colors.transparent,
//                                                 activeTrackColor: Colors.transparent,
//                                                 thumbColor: Colors.transparent,
//                                                 overlayColor: Colors.transparent,
//                                                 thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
//                                                 overlayShape: SliderComponentShape.noOverlay,
//                                               ),
//                                               child: Slider(
//                                                 min: 0,
//                                                 max: _segments.toDouble(),
//                                                 divisions: _segments,
//                                                 value: _brightness.toDouble(),
//                                                 onChanged: _isOn
//                                                     ? (value) {
//                                                   setState(() {
//                                                     _brightness = value.round();
//                                                   });
//                                                 }
//                                                     : null,
//                                                 onChangeEnd: _isOn ? _updateBrightness : null,
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         Positioned(
//                           child: Text(
//                             '${((_brightness / _segments) * 100).round()}%',
//                             style: TextStyle(
//                               color: (_brightness / _segments) > (58 / 255)
//                                   ? Colors.white
//                                   : Colors.white,
//                               fontSize: 26,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                         ),
//
//
//                         const SizedBox(height: 20),
//
//
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//
//                             const SizedBox(width: 16),
//
//                             GestureDetector(
//                               onTap: () => _toggleSwitch(!_isOn), // call with inverse of current value
//                               child: Container(
//                                 width: 70,
//                                 height: 70,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: _isOn ?  Colors.grey[1000] : Color(0xFF121212),
//                                 ),
//                                 child: Center(
//                                   child: Icon(
//                                     Icons.power_settings_new, // or choose another icon
//                                     color: _isOn ?  Colors.grey[500] : Color(0xFFF58700),
//                                     size: 40,
//                                   ),
//                                 ),
//                               ),
//                             ),
//
//
//                             const SizedBox(width: 15),
//
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Align(
//                 alignment: Alignment.bottomCenter,
//                 child: _buildDetailsPanel(),
//               ),
//             ],
//           ),
//         ),
//       ),
//
//     );
//   }
// }
