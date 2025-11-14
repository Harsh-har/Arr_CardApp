import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../utils/global_controller.dart';

class Relay extends StatefulWidget {
  final String deviceId;
  final String deviceLocation;
  final Device device;
  final bool isOn;
  final Function(bool) onToggle;
  final Function(String) onNameChanged;
  final MQTTService mqttService;


  const Relay({
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
  State<Relay> createState() => _Relay();
}
class _Relay extends State<Relay> {
  bool internalUpdate = false;
  late String _location;
  late String _elementId;
  late String _roomName;
  late String deviceId;
  bool _isOn = true;
  String _mqttTopic = '';
  bool _showFirstContainer = false;
  bool _showSecondContainer = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _isOn = widget.isOn;
    deviceId = widget.device.deviceId;
    _location = widget.device.location;
    _roomName = widget.device.roomName;
    _elementId = widget.device.element;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadState());
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

  void _toggleSwitch(bool value) {
    setState(() => _isOn = value);
    widget.onToggle(value);
    _saveState();

    final message = value
        ? '#*2*$_elementId*2*1*#'
        : '#*2*$_elementId*2*0*#';

    if (widget.mqttService.isConnected) {
      widget.mqttService.publish(_mqttTopic, message);
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

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          height: 140, //
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),

                // Center title (SVG with gesture)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFirstContainer = !_showFirstContainer;
                      _showSecondContainer = false;
                    });

                    if (_showFirstContainer) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        setState(() => _showSecondContainer = true);
                      });
                    }
                  },
                  child: Transform.translate(
                    offset: Offset(0, -2),
                    child: SvgPicture.asset(
                      'assets/icons/Card_Icons/ListRelay.svg',
                      height: 55,
                      width: 55,
                    ),
                  ),
                ),

                // Action menu
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


      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_showFirstContainer) {
              setState(() {
                _showSecondContainer = false;
                _showFirstContainer = false;
              });
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Device name and room name are now OUTSIDE the sliding panel
              Padding(
                padding:  EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ The slider panel
              Expanded(
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      top: _showFirstContainer ? 0 : 0,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {}, // Prevents tap from bubbling
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const SizedBox(height: 160), // adjust the height as needed

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () => _toggleSwitch(!_isOn),
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isOn ? Colors.grey[1000] : const Color(0xFF121212),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.power_settings_new,
                                          color: _isOn ? Colors.grey[500] : const Color(0xFFFFBB00),
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                ],
                              ),

                              const SizedBox(height: 12),

                              /// ✅ ON/OFF Status Text
                              Text(
                                _isOn ? "Status: ON" : "Status: OFF",
                                style: TextStyle(
                                  color: _isOn ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Optional floating panel or detail panel
                    Align(
                      alignment: Alignment.topCenter,
                      child: _buildDetailsPanel(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}