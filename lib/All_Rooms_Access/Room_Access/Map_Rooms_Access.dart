import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../../Devices_Structure/Devices_Structure_Json.dart';

class MapRoomsAccess extends StatefulWidget {
  final String roomName;
  final String appBarTitle;
  const MapRoomsAccess({
    super.key,
    required this.roomName,
    required this.appBarTitle,
  });

  @override
  State<MapRoomsAccess> createState() => _MapRoomsAccessState();
}

class _MapRoomsAccessState extends State<MapRoomsAccess> {
  final Map<String, String> deviceIconSvgMapping = {
    'Dimmer': 'assets/icons/Card_Icons/ListDimmer.svg',
    'SubNode Supply': 'assets/icons/Card_Icons/ListSubnode.svg',
    'Strip Light': 'assets/icons/Card_Icons/ListStrip.svg',
    'Fan': 'assets/icons/Card_Icons/ListFan.svg',
    'AC': 'assets/icons/Card_Icons/ListAC.svg',
    'Curtains': 'assets/icons/Card_Icons/ListBlinds.svg',
    'Exhaust': 'assets/icons/Card_Icons/ListExhaust.svg',
    'Relay': 'assets/icons/Card_Icons/ListRelay.svg',
    'Sensors (Occupancy)': 'assets/icons/Card_Icons/ListFan.svg',
    'Individual Subnode': 'assets/icons/Card_Icons/ListSubnode.svg',
    'Individual Strip': 'assets/icons/Card_Icons/ListStrip.svg',
    'Group Fan': 'assets/icons/Card_Icons/ListGroupFan.svg',
    'Group Strip': 'assets/icons/Card_Icons/ListGroupStrip.svg',
    'Group Light': 'assets/icons/Card_Icons/ListGroupLight.svg',
    'Group Single Light': 'assets/icons/Card_Icons/ListGroupSingleLight.svg',
    'Sensor': 'assets/icons/Card_Icons/ListSensor.svg',
    'RGB Strip': 'assets/icons/Card_Icons/ListStrip.svg',
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadDevices();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedDevices = prefs.getStringList('saved_devices');

    if (savedDevices == null || savedDevices.isEmpty) {
      print("⚠️ No saved devices.");
      return;
    }

    List<Device> loaded = [];

    for (String item in savedDevices) {
      try {
        final Map<String, dynamic> json = jsonDecode(item);
        final device = Device.fromJson(json);
        loaded.add(device);
      } catch (e) {
        print("❌ JSON error while loading device: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.appBarTitle,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),

      body: Stack(
        children: [
          // Room rectangle
          Center(
            child: Container(
              width: 350,
              height: 500,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Lights
                  Positioned(
                    left: 40,
                    top: 40,
                    child: GestureDetector(
                      onTap: () {
                          print("Light 1 tapped!");
                          },
                      child: Icon(
                        Icons.lightbulb,
                        color: Colors.yellow,
                        size: 40,
                      ),
                    ),
                  ),

                  Positioned(
                    left: 140,
                    top: 40,
                    child: Icon(Icons.lightbulb, color: Colors.yellow, size: 40),
                  ),
                  Positioned(
                    left: 240,
                    top: 40,
                    child: Icon(Icons.lightbulb, color: Colors.yellow, size: 40),
                  ),
                  Positioned(
                    left: 90,
                    top: 150,
                    child: Icon(Icons.lightbulb, color: Colors.yellow, size: 40),
                  ),
                  Positioned(
                    left: 200,
                    top: 150,
                    child: Icon(Icons.lightbulb, color: Colors.yellow, size: 40),
                  ),

                  // Fans
                  Positioned(
                    left: 70,
                    bottom: 50,
                    child: Icon(Icons.wind_power, color: Colors.blue, size: 50),
                  ),
                  Positioned(
                    right: 70,
                    bottom: 50,
                    child: Icon(Icons.wind_power, color: Colors.blue, size: 50),
                  ),
                ],
              ),
            ),
          ),

          if (!mqttService.isConnected)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Text(
                  "Broker/Wi-Fi Is Out Of Service!!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}