import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../utils/global_controller.dart';

class SMPSController extends StatefulWidget {
  final String deviceId;
  final String deviceLocation;
  final Device device;
  final bool isOn;
  final Function(bool) onToggle;
  final Function(String) onNameChanged;
  final MQTTService mqttService;

  const SMPSController({
    super.key,
    required this.deviceId,
    required this.deviceLocation,
    required this.device,
    required this.isOn,
    required this.onToggle,
    required this.onNameChanged,
    required this.mqttService,
  });

  @override
  State<SMPSController> createState() => _SMPSControllerState();
}

class _SMPSControllerState extends State<SMPSController> {
  bool internalUpdate = false;
  bool sliderActive = false;
  final int _segments = 255;
  late int _brightness = 128;
  late String _location;
  late String _elementId;
  late String _roomName;
  late String deviceId;
  bool _isOn = true;
  String _mqttTopic = '';
  bool _showFirstContainer = false;
  bool _showSecondContainer = false;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _isOn = widget.isOn;
    deviceId = widget.device.deviceId;
    _location = widget.device.location;
    _roomName = widget.device.roomName;
    _elementId = widget.device.element;
    _brightness = widget.device.brightness;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadState());
  }

  @override
  void dispose() {
    deviceRefreshNotifier.removeListener(_loadState);
    _pauseTimer?.cancel();
    super.dispose();
  }

  void _saveState() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDevices = prefs.getStringList('saved_devices') ?? [];

    final updatedDevices = savedDevices.map((deviceStr) {
      final json = jsonDecode(deviceStr);

      if (json['deviceId'] == widget.device.deviceId) {
        json['deviceId'] = widget.device.deviceId;
        json['location'] = _location;
        json['roomName'] = _roomName;
        json['element'] = _elementId;
        json['isOn'] = _isOn;
        json['brightness'] = _brightness;
      }

      return jsonEncode(json);
    }).toList();

    await prefs.setStringList('saved_devices', updatedDevices);
  }

  void _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDevices = prefs.getStringList('saved_devices') ?? [];
    final globalPub = prefs.getString('saved_topic_${widget.device.roomName}');

    if (!mounted) return;

    for (final deviceStr in savedDevices) {
      final json = jsonDecode(deviceStr);
      if (json['deviceId'] == widget.device.deviceId) {
        setState(() {
          _brightness = (json['brightness'] ?? _brightness).clamp(0, 255);
          _isOn = json['isOn'] ?? _isOn;
          _location = (json['location'] ?? _location).toString();
          _roomName = (json['roomName'] ?? _roomName).toString();
          _elementId = (json['element'] ?? _elementId).toString();
          _mqttTopic = globalPub ?? _mqttTopic; // safe assignment
          internalUpdate = true;
        });
        return;
      }
    }
  }

  void _updateBrightness(double value) {
    setState(() => _brightness = value.round().clamp(1, 255));
    _saveState();

    final ids = _elementId.toString().split(',');

    if (ids.length < 2) {
      debugPrint('❌ Invalid element ID format: $_elementId');
      return;
    }

    final stripElementId = ids[1].trim();
    final String topic = _mqttTopic;

    // ✅ Brightness update command only for strip
    final String message = '#*2*$stripElementId*2*$_brightness*#';

    if (widget.mqttService.isConnected) {
      widget.mqttService.publish(topic, message);
    }
  }

  void _toggleSwitch(bool value) async {
    setState(() => _isOn = value);
    widget.onToggle(value);
    _saveState();

    final ids = _elementId.toString().split(',');

    if (ids.length < 2) {
      debugPrint('❌ Invalid element ID format: $_elementId');
      return;
    }

    final relayElementId = ids[0].trim();
    final stripElementId = ids[1].trim();

    final String topic = _mqttTopic;

    // ✅ Relay command
    final String relayMessage = value
        ? '#*2*$relayElementId*2*1*#'
        : '#*2*$relayElementId*2*0*#';

    // ✅ Strip command
    final String stripMessage = value
        ? '#*2*$stripElementId*2*$_brightness*#'
        : '#*2*$stripElementId*2*0*#';

    if (widget.mqttService.isConnected) {
      if (value) {
        // 🔹 Turning ON: relay first, then strip
        widget.mqttService.publish(topic, relayMessage);
        await Future.delayed(const Duration(seconds: 2));
        widget.mqttService.publish(topic, stripMessage);
      } else {
        // 🔹 Turning OFF: strip first, then relay
        widget.mqttService.publish(topic, stripMessage);
        await Future.delayed(const Duration(seconds: 2));
        widget.mqttService.publish(topic, relayMessage);
      }
    } else {
      print("⚠️ MQTT NOT CONNECTED! Cannot send messages");
    }
  }

  Future<String?> _editFieldDialog(String title, String currentValue, String label) {
    final controller = TextEditingController(text: currentValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> editDeviceRoom(Device device, String newRoomName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];

    List<String> updatedDevices = savedDevices.map((deviceJson) {
      final deviceMap = json.decode(deviceJson);
      if (deviceMap['name'] == device.deviceId && deviceMap['listItemName'] == device.listItemName) {
        deviceMap['roomName'] = newRoomName; // 🟢 Update room
      }
      return json.encode(deviceMap);
    }).toList();

    await prefs.setStringList('saved_devices', updatedDevices);
  }

  Future<void> editDeviceElement(Device device, String newElementId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];

    List<String> updatedDevices = savedDevices.map((deviceJson) {
      final deviceMap = json.decode(deviceJson);
      if (deviceMap['name'] == device.deviceId && deviceMap['listItemName'] == device.listItemName) {
        deviceMap['element'] = newElementId; // 🟢 Update element
      }
      return json.encode(deviceMap);
    }).toList();

    await prefs.setStringList('saved_devices', updatedDevices);
  }

  Future<void> editDeviceName(Device device, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDevices = prefs.getStringList('saved_devices') ?? [];

    List<String> updatedDevices = savedDevices.map((deviceJson) {
      final deviceMap = json.decode(deviceJson);
      if (deviceMap['name'] == device.deviceId && deviceMap['listItemName'] == device.listItemName) {
        deviceMap['name'] = newName; // ✅ update the name field
      }
      return json.encode(deviceMap);
    }).toList();

    await prefs.setStringList('saved_devices', updatedDevices);
  }

  void _editDevice() async {
    final newName = await _editFieldDialog('Edit Device Name', widget.device.deviceId, 'Device Name');

    if (newName != null && newName.isNotEmpty && newName != widget.device.deviceId) {
      await editDeviceName(widget.device, newName);

      setState(() {
        deviceId = newName;
        widget.device.deviceId = newName;
      });
    }
  }

  void _editRoom() async {
    final newRoom = await _editFieldDialog('Edit Room Name', _roomName, 'Room Name');

    if (newRoom != null && newRoom.isNotEmpty && newRoom != _roomName) {
      await editDeviceRoom(widget.device, newRoom);

      setState(() {
        _roomName = newRoom;
        widget.device.roomName = newRoom;
      });
    }
  }

  void _editElement() async {
    final newElement = await _editFieldDialog('Edit Element ID', _elementId, 'Element ID');

    if (newElement != null && newElement.isNotEmpty && newElement != _elementId) {
      await editDeviceElement(widget.device, newElement);

      setState(() {
        _elementId = newElement;
        widget.device.element = newElement;
      });
    }
  }

  Widget _buildDetailsPanel() {
    final Map<String, String> deviceDetails = {
      "Device ID": deviceId,
      "Device Name": "Light",
      "Location": "_spaces",
      "Part of Group": ":",
      "Part of Scene": ":",
      "Topic": _mqttTopic,
      "Element ID": _elementId,
      "Application ID": ":",
      "OPCode": ":",
      "Firmware Version": ":",
      "Hardware Version": ":",
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _showFirstContainer ? 900 : 0,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: _showFirstContainer
          ? AnimatedOpacity(
        opacity: _showSecondContainer ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deviceDetails.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final label = deviceDetails.keys.elementAt(index);
              final value = deviceDetails.values.elementAt(index);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$label:",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final String deviceKey = widget.device.deviceId;

    if (!brightnessNotifiers.containsKey(deviceKey)) {
      brightnessNotifiers[deviceKey] = ValueNotifier<int>(_brightness);
    }
    ValueNotifier<int> deviceNotifier = brightnessNotifiers[deviceKey]!;


    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 130,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFirstContainer = !_showFirstContainer;
                      _showSecondContainer = false;
                    });
                    if (_showFirstContainer) {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() => _showSecondContainer = true);
                      });
                    }
                  },
                  child: Transform.translate(
                    offset: const Offset(0, 6),
                    child: SvgPicture.asset(
                      'assets/icons/Devices_Icons/StripLight.svg',
                      height: 74,
                      width: 80,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: SvgPicture.asset(
                    'assets/icons/Setting_Icon/Vector.svg',
                    height: 24,
                    width: 24,
                  ),
                  onSelected: (value) {
                    if (value == 'Element') {
                      _editElement();
                    } else if (value == 'room') {
                      _editRoom();
                    } else if (value == 'Device') {
                      _editDevice();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Element', child: Text('Edit Element')),
                    PopupMenuItem(value: 'room', child: Text('Edit Room')),
                    PopupMenuItem(value: 'Device', child: Text('Edit Device')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenHeight = constraints.maxHeight;
          double screenWidth = constraints.maxWidth;

          double maxSliderHeight = screenHeight * 0.5;
          double sliderHeight = maxSliderHeight.clamp(270, 420);
          double sliderWidth = (sliderHeight * 0.35).clamp(90, screenWidth * 0.5);
          double powerBtnSize = 70 * (sliderHeight / 400);
          double percentageTextSize = 24 * (sliderHeight / 390);
          double spacing = screenHeight < 600 ? 5 : 20;
          double borderRadius = sliderHeight * 0.09;

          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_showFirstContainer) {
                    setState(() {
                      _showSecondContainer = false;
                      _showFirstContainer = false;
                    });
                  }
                },
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 90),
                          SizedBox(
                            height: screenHeight * 0.8,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '$_brightness / $_segments',
                                  style: const TextStyle(color: Colors.grey, fontSize: 18),
                                ),

                                SizedBox(height: spacing),

                                // --- Slider Block ---
                                SizedBox(
                                  height: sliderHeight,
                                  width: sliderWidth,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Container(
                                        height: 340 * (sliderHeight / 370),
                                        width: sliderWidth * 0.82,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(borderRadius),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(borderRadius),
                                          child: Stack(
                                            children: [
                                              Container(
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [Color(0xFF080808), Color(0xFF252525)],
                                                  ),
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.bottomCenter,
                                                child: Container(
                                                  width: sliderWidth * 0.82,
                                                  height: (_brightness / _segments) * (340 * (sliderHeight / 370)),
                                                  color: const Color(0xFFFFBB00),
                                                ),
                                              ),
                                              if (!_isOn)
                                                Container(
                                                  width: sliderWidth * 0.82,
                                                  height: 340 * (sliderHeight / 370),
                                                  color: Colors.black.withOpacity(0.7),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: sliderHeight * 0.13,
                                        child: Opacity(
                                          opacity: _isOn ? 1.0 : 0.5,
                                          child: Text(
                                            '${((_brightness / 255) * 100).clamp(1, 100).round()}%',
                                            style: TextStyle(
                                              color: (_brightness / 255) > (54 / 255)
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontSize: percentageTextSize,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Opacity(
                                        opacity: _isOn ? 1.0 : 0.4,
                                        child: RotatedBox(
                                          quarterTurns: -1,
                                          child: SizedBox(
                                            width: 340 * (sliderHeight / 400),
                                            height: sliderWidth * 0.67 + 60,
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 100 * (sliderHeight / 400),
                                                inactiveTrackColor: Colors.transparent,
                                                activeTrackColor: Colors.transparent,
                                                thumbColor: Colors.transparent,
                                                overlayColor: Colors.transparent,
                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
                                                overlayShape: SliderComponentShape.noOverlay,
                                              ),
                                              child: Slider(
                                                min: 1,
                                                max: 255,
                                                divisions: 254,
                                                value: _brightness.toDouble().clamp(1.0, 255.0),
                                                onChanged: _isOn
                                                    ? (value) {
                                                  // Only allow sliding if device is ON
                                                  if (!sliderActive) sliderActive = true;
                                                  setState(() => _brightness = value.round());
                                                  _pauseTimer?.cancel();
                                                  _pauseTimer = Timer(
                                                    const Duration(milliseconds: 300),
                                                        () => _updateBrightness(value),
                                                  );
                                                }
                                                    : null, // disables the slider when _isOn is false
                                                onChangeEnd: _isOn
                                                    ? (value) {
                                                  _pauseTimer?.cancel();
                                                  _updateBrightness(value);
                                                  if (deviceNotifier.value != value.round()) {
                                                    deviceNotifier.value = value.round();
                                                  }
                                                  sliderActive = false;
                                                }
                                                    : null,
                                              ),

                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: sliderHeight * 0.12),

                                SizedBox(
                                  width: powerBtnSize,
                                  height: powerBtnSize,
                                  child: GestureDetector(
                                    onTap: () => _toggleSwitch(!_isOn),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isOn ? Colors.grey[1000] : const Color(0xFF121212),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.power_settings_new,
                                          color: _isOn ? Colors.grey[500] : const Color(0xFFFFBB00),
                                          size: 40 * (sliderHeight / 425),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Top Header always visible
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      _location,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _roomName,
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Panel overlay (below name)
              if (_showFirstContainer || _showSecondContainer)
                Positioned.fill(
                  top: 90, // appear below room name
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showFirstContainer = false;
                        _showSecondContainer = false;
                      });
                    },
                    child: AnimatedOpacity(
                      opacity: (_showFirstContainer || _showSecondContainer) ? 1.0 : 0.0,
                      duration:  Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: GestureDetector(
                            onTap: () {}, // Prevent outside tap
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return _buildDetailsPanel();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}





