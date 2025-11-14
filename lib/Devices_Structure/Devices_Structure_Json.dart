import 'package:flutter/material.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';

class Device {
  late final String deviceId;
  final String listItemName;
  final String icon;
  String location;
  String element;
  String roomName;
  bool isOn;
  int brightness;
  late final String topic;
  final String subscribeTopic;
  final MQTTService? mqttService;

  Device({
    required this.deviceId,
    required this.listItemName,
    required this.icon,
    required this.location,
    required this.element,
    required this.roomName,
    required this.brightness,
    this.isOn = false,
    required this.topic,
    required this.subscribeTopic,
    this.mqttService,
  });

  Map<String, dynamic> toJson() {
    return {
      "deviceId": deviceId,
      "listItemName": listItemName,
      "icon": icon,
      "location": location,
      "element": element,
      "roomName": roomName,
      "isOn": isOn,
      "brightness": brightness,
      "topic": topic,
      "subscribeTopic": subscribeTopic,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: (json['deviceId'] ?? '').toString(),
      listItemName: (json['listItemName'] ?? '').toString(),
      icon: _normalizeIconName(json['icon']),
      location: (json['location'] ?? '').toString(),
      element: (json['element'] ?? '').toString(),
      roomName: (json['roomName'] ?? '').toString(),
      isOn: json['isOn'] ?? false,
      brightness: json['brightness'],
      topic: (json['topic'] ?? '').toString(),
      subscribeTopic: (json['subscribeTopic'] ?? '').toString(),
    );
  }

  /// Convert icon name to a valid string
  static String _normalizeIconName(dynamic icon) {
    if (icon is int) {
      return iconMapping.entries
          .firstWhere(
            (entry) => entry.value.codePoint == icon,
        orElse: () => MapEntry('default', Icons.device_unknown),
      )
          .key;
    }
    return icon?.toString() ?? 'default';
  }

  /// **Get IconData from iconName**
  IconData get iconName => iconMapping[icon] ?? Icons.device_unknown;
}

/// **Predefined icon mapping**
const Map<String, IconData> iconMapping = {
  'Dimmer': Icons.lightbulb_outline,
  'SubNode Supply': Icons.light,
  'Strip Light': Icons.tungsten,
  'Fan': Icons.air,
  'AC': Icons.ac_unit,
  'Curtains': Icons.window,
  'Exhaust': Icons.wind_power_outlined,
  'Appliance (Relay)': Icons.power,
  'Sensors (Occupancy)': Icons.sensors,
  'Individual device': Icons.devices_other,
  'Group device': Icons.group_work_outlined,
  'default': Icons.device_unknown,
};
