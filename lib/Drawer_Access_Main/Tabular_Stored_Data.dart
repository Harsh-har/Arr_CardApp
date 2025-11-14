import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Devices_Structure/Devices_Structure_Json.dart';

class DeviceTablePage extends StatefulWidget {
  const DeviceTablePage({super.key});

  @override
  State<DeviceTablePage> createState() => _DeviceTablePageState();
}

class _DeviceTablePageState extends State<DeviceTablePage> {
  List<Device> devices = [];
  String savedName = '';
  String savedUsername = '';
  Map<String, int> brightnessMap = {};
  final Map<String, bool> _deviceStates = {};

  @override
  void initState() {
    super.initState();
    loadCredentialsAndDevices();
  }

  Future<void> loadCredentialsAndDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final username = prefs.getString('mqtt_username') ?? '';
    final savedDeviceStrings = prefs.getStringList('saved_devices');
    List<Device> loadedDevices = [];

    if (savedDeviceStrings != null && savedDeviceStrings.isNotEmpty) {
      try {
        loadedDevices = savedDeviceStrings.map((deviceStr) {
          final json = jsonDecode(deviceStr);
          return Device.fromJson(json);
        }).toList();
      } catch (e) {
        print("Error decoding devices: $e");
      }
    }
    setState(() {
      savedName = name;
      savedUsername = username;
      devices = loadedDevices;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Devices Table", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: Colors.black,
        onRefresh: loadCredentialsAndDevices,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 User Info
            Container(
              color: Colors.black,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 Name: $savedName", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("🔐 Username: $savedUsername", style: TextStyle(fontSize: 15, color: Colors.white)),
                ],
              ),
            ),
            const Divider(height: 1),

            // 📋 Device Table
            Expanded(
              child: devices.isEmpty
                  ? const Center(child: Text("No devices found", style: TextStyle(color: Colors.white)))
                  : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey.shade900),
                    dataRowColor: MaterialStateColor.resolveWith((states) => Colors.black),
                    columns: const [
                      DataColumn(label: Text("Device ID", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Location", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Brightness", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Is On", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Element", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("List Item", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Room", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Icon", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Topic", style: TextStyle(color: Colors.white))),
                      DataColumn(label: Text("Subscribe", style: TextStyle(color: Colors.white))),
                    ],
                    rows: devices.map((d) {
                      return DataRow(cells: [
                        DataCell(Text(d.deviceId, style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.location, style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.brightness.toString(), style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.isOn ? "ON" : "OFF", style: const TextStyle(color: Colors.white))),
                        DataCell(Text(d.element, style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.listItemName, style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.roomName, style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.icon, style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.topic, style: TextStyle(color: Colors.white))),
                        DataCell(Text(d.subscribeTopic, style: TextStyle(color: Colors.white))),
                      ]);
                    }).toList(),
                  ),

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
