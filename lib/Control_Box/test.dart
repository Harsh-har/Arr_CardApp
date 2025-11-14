// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../Devices_Structure/Devices_Structure_Json.dart';
// import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';
// import 'Color_wheel.dart';
//
// class RGBStrip extends StatefulWidget {
//   final String deviceName;
//   final Device device;
//   final bool isOn;
//   final Function(bool) onToggle;
//   final Function(String) onNameChanged;
//   final MQTTService mqttService;
//
//   const RGBStrip({
//     super.key,
//     required this.deviceName,
//     required this.device,
//     required this.isOn,
//     required this.onToggle,
//     required this.onNameChanged,
//     required this.mqttService,
//   });
//
//   @override
//   _RGBStripState createState() => _RGBStripState();
// }
//
// class _RGBStripState extends State<RGBStrip> {
//   int maxRgb = 255;
//   int _brightness = 50;
//   int _saturation = 50;
//   int _rgb = 0;
//   late String name;
//   late String _elementId;
//   late String _roomName;
//   bool _isOn = true;
//   String _mqttTopic = '';
//   bool _showFirstContainer = false;
//   bool _showSecondContainer = false;
//
//
//
//   late double _shade;
//   double selectedHue = 0;
//   Color? currentColor;
//
//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//     ]);
//     super.initState();
//     name = widget.device.name;
//     _roomName = widget.device.roomName;
//     _elementId = widget.device.element;
//     _isOn = widget.isOn;
//     _refreshState();
//   }
//
//   void _refreshState() async {
//     final prefs = await SharedPreferences.getInstance();
//     final deviceKey = widget.device.name;
//
//     String globalPub = prefs.getString('saved_topic_${widget.device.roomName}') ?? widget.device.topic;
//     int savedBrightness = (prefs.getInt('${deviceKey}_brightness') ?? 50).clamp(0, 100);
//     int savedSaturation = (prefs.getInt('${deviceKey}_saturation') ?? 50).clamp(0, 100);
//     int savedRgb = prefs.getInt('${deviceKey}_rgb') ?? 0;
//     double savedHue = prefs.getDouble('${deviceKey}_hue') ?? 0;
//     double savedShade = prefs.getDouble('${deviceKey}_shade') ?? 100;
//     bool savedIsOn = prefs.getBool('${deviceKey}_isOn') ?? widget.isOn;
//
//     if (!mounted) return;
//
//     setState(() {
//       _isOn = savedIsOn;
//       _brightness = savedBrightness;
//       _saturation = savedSaturation;
//       _rgb = savedRgb;
//       selectedHue = savedHue;
//       _shade = savedShade;
//
//       currentColor = HSVColor.fromAHSV(
//         1,
//         selectedHue,
//         _saturation / 100,
//         _shade / 100,
//       ).toColor();
//
//       _mqttTopic = globalPub;
//       _roomName = prefs.getString('${deviceKey}_room') ?? widget.device.roomName;
//       _elementId = prefs.getString('${deviceKey}_element') ?? widget.device.element;
//       name = prefs.getString('${deviceKey}_name') ?? widget.device.name;
//     });
//   }
//
//   void _saveState() async {
//     final prefs = await SharedPreferences.getInstance();
//     final deviceKey = widget.device.name;
//
//     await prefs.setBool('${deviceKey}_isOn', _isOn);
//     await prefs.setInt('${deviceKey}_brightness', _brightness);
//     await prefs.setInt('${deviceKey}_saturation', _saturation);
//     await prefs.setInt('${deviceKey}_rgb', _rgb);
//     await prefs.setDouble('${deviceKey}_hue', selectedHue);
//     await prefs.setDouble('${deviceKey}_shade', _shade);
//
//     await prefs.setString('${deviceKey}_room', _roomName);
//     await prefs.setString('${deviceKey}_element', _elementId);
//     await prefs.setString('${deviceKey}_name', name);
//   }
//
//   void _updateBrightness(double value) {
//     setState(() {
//       _brightness = value.round().clamp(1, 100);
//       _saveState();
//     });
//     int maxRgb = 255;
//     int firstPart = _rgb <= maxRgb ? _rgb : maxRgb;
//     int secondPart = _rgb <= maxRgb ? 0 : _rgb - maxRgb;
//
//     final message = '#*3*$_elementId*2*1*$firstPart*$secondPart*$_saturation*$_brightness*0*0*#';
//     if (widget.mqttService.isConnected) {
//       widget.mqttService.publish(_mqttTopic, message);
//     }
//   }
//
//   void _sendToMQTT() {
//     int maxRgb = 255;
//     int firstPart = _rgb <= maxRgb ? _rgb : maxRgb;
//     int secondPart = _rgb <= maxRgb ? 0 : _rgb - maxRgb;
//
//     final message = '#*3*$_elementId*2*1*$firstPart*$secondPart*$_saturation*$_brightness*0*0*#';
//
//     if (widget.mqttService.isConnected) {
//       widget.mqttService.publish(_mqttTopic, message);
//       print("📡 Sent final message: $message");
//     }
//   }
//
//   void _updateSaturation(double value) {
//     setState(() {
//       _saturation = value.round();
//       currentColor = HSVColor.fromAHSV(
//         1,
//         selectedHue,
//         _saturation / 100,
//         _shade / 100,
//       ).toColor();
//     });
//
//   }
//
//   void _updateRGBColor(HSVColor hsv) {
//     setState(() {
//       selectedHue = hsv.hue;
//       _saturation = (hsv.saturation * 100).round();
//       _shade = (hsv.value * 100).round().toDouble();
//
//       currentColor = hsv.toColor();
//       _rgb = hsv.hue.round();
//     });
//   }
//
//   void _toggleSwitch(bool value) {
//     setState(() => _isOn = value);
//     widget.onToggle(value);
//     _saveState();
//
//     // Handle _rgb exceeding 255
//     int maxRgb = 255;
//     int firstPart = _rgb <= maxRgb ? _rgb : maxRgb;
//     int secondPart = _rgb <= maxRgb ? 0 : _rgb - maxRgb;
//
//     final message = value
//         ? '#*3*$_elementId*2*1*$firstPart*$secondPart*$_saturation*$_brightness*0*0*#'
//         : '#*3*$_elementId*2*1*$firstPart*$secondPart*$_saturation*0*0*0*#' ;
//
//     if (widget.mqttService.isConnected) {
//       widget.mqttService.publish(_mqttTopic, message);
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
//     return Scaffold(
//       backgroundColor: Colors.black,
//
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
//                   },                  child: Transform.translate(
//                   offset: const Offset(0, 0),
//                   child: ShaderMask(
//                     shaderCallback: (bounds) => const LinearGradient(
//                       colors: [Colors.red, Colors.green, Colors.blue],
//                       stops: [0.25, 0.5, 0.7],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ).createShader(Rect.fromLTWH(0, 0, 80, 74)),
//                     child: SvgPicture.asset(
//                       'assets/icons/Devices_Icons/StripLight.svg',
//                       height: 74,
//                       width: 80,
//                       color: Colors.white, // base color for gradient overlay
//                     ),
//                   ),
//                 ),
//
//                 ),
//                 PopupMenuButton<String>(
//                   icon: SvgPicture.asset(
//                     'assets/icons/Setting_Icon/Vector.svg',
//                     height: 24,
//                     width: 24,
//                   ),
//
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
//       body: Stack(
//         children: [
//           GestureDetector(
//             behavior: HitTestBehavior.translucent,
//             onTap: () {
//               if (_showFirstContainer) {
//                 setState(() {
//                   _showSecondContainer = false;
//                   _showFirstContainer = false;
//                 });
//               }
//             },
//             child: SizedBox(
//               width: double.infinity,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Text(
//                     name,
//                     style: const TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     _roomName,
//                     style: const TextStyle(fontSize: 20, color: Colors.grey),
//                   ),
//                   const SizedBox(height: 20),
//
//
//                   ColorWheelWithSaturation(
//                     size: 310,
//                     initialHue: selectedHue,
//                     initialColor: HSVColor.fromAHSV(
//                       1,
//                       selectedHue,
//                       _saturation / 100,
//                       _shade / 100,
//                     ),
//                     onColorChanged: (hsv) {
//                       _updateRGBColor(hsv);
//                       _updateSaturation(hsv.saturation * 100);
//                       _saveState();
//                     },
//                     onColorChangeEnd: (hsv) {
//                       _sendToMQTT();
//                       _saveState();
//                     },
//                   ),
//
//
//
//                   const SizedBox(height: 50),
//
//
//                   // Brightness Slider
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         const Text(
//                           "Brightness",
//                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                         ),
//                         const SizedBox(height: 8),
//
//                         SizedBox(
//                           height: 50,
//                           width: double.infinity,
//                           child: LayoutBuilder(
//                             builder: (context, constraints) {
//                               const double thumbRadius = 10;
//                               return Stack(
//                                 alignment: Alignment.centerLeft,
//                                 children: [
//                                   SliderTheme(
//                                     data: SliderTheme.of(context).copyWith(
//                                       trackHeight: 12,
//                                       activeTrackColor: Color(0xFFFFBB00),
//                                       inactiveTrackColor: Colors.grey,
//                                       thumbColor: Colors.white,
//                                       overlayColor: Colors.white.withOpacity(0.2),
//                                       thumbShape: const RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
//                                       overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
//                                     ),
//                                     child: Slider(
//                                       min: 1,
//                                       max: 100,
//                                       divisions: 99,
//                                       value: _brightness.clamp(1, 100).toDouble(),
//                                       onChanged: (value) {
//                                         if (!_isOn) _toggleSwitch(true);
//                                         setState(() => _brightness = value.round().clamp(1, 100));
//                                       },
//                                       onChangeEnd: (value) {
//                                         _updateBrightness(value);
//                                       },
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ),
//
//                         // Percentage text
//                         Text(
//                           '${_brightness.clamp(1, 100)}%',
//                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
//                         ),
//                       ],
//                     ),
//                   ),
//
//
//                   SizedBox(height: 70,),
//
//                   // Power button
//                   SizedBox(
//                     width: double.infinity,
//                     child: GestureDetector(
//                       onTap: () => _toggleSwitch(!_isOn),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: _isOn ? Colors.grey[1000] : const Color(0xFF121212),
//                         ),
//                         child: Center(
//                           child: Icon(
//                             Icons.power_settings_new,
//                             color: _isOn ? Colors.grey[800] :  Colors.purpleAccent,
//                             size: 40,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Dim layer (always visible if light is on)
//           // Dim layer (only when OFF)
//           if (!_isOn)
//             Positioned.fill(
//               bottom: 130,
//               child: Container(
//                 color: Colors.black.withOpacity(0.6), // dim effect when off
//               ),
//             ),
//
//           // Panel overlay (only if panel is shown)
//           if (_showFirstContainer || _showSecondContainer)
//             Positioned.fill(
//               top: 90,
//               child: GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     _showFirstContainer = false;
//                     _showSecondContainer = false;
//                   });
//                 },
//                 child: AnimatedOpacity(
//                   opacity: (_showFirstContainer || _showSecondContainer) ? 1.0 : 0.0,
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                   child: Container(
//                     color: Colors.black.withOpacity(0.6),
//                     child: Center(
//                       child: GestureDetector(
//                         onTap: () {}, // prevent outside tap
//                         child: LayoutBuilder(
//                           builder: (context, constraints) {
//                             return _buildDetailsPanel();
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//
//
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
