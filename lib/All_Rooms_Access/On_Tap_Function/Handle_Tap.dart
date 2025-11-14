import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_control/Control_Box/Exhaust.dart';
import '../../Control_Box/Group Random Lights.dart';
import '../../Control_Box/SMPS Controller.dart';
import '../../Control_Box/ac.dart';
import '../../Control_Box/cob.dart';
import '../../Control_Box/fan.dart';
import '../../Control_Box/individual_box.dart';
import '../../Control_Box/relay.dart';
import '../../Control_Box/strip_light.dart';
import '../../Control_Box/subnode_supply.dart';
import '../../Devices_Structure/Devices_Structure_Json.dart';
import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';


typedef UpdateDeviceNameCallback = void Function(String newName);
typedef SaveDevicesCallback = void Function();
typedef SetStateCallback = void Function(VoidCallback fn);

Future<void> handleDeviceTap({
  required BuildContext context,
  required Device device,
  required int index,
  required List<Device> devices,
  required Map<String, bool> deviceStates,
  required SetStateCallback setState,
  required SaveDevicesCallback saveDevices,
}) async {
  final mqttService = Provider.of<MQTTService>(context, listen: false);
  final prefs = await SharedPreferences.getInstance();
  final lowerName = device.listItemName.toLowerCase();


  bool savedState = prefs.getBool('${device.deviceId}_isOn') ?? false;

  void updateDeviceName(String newLocation) {
    setState(() {
      Device newDevice = Device(
        deviceId: device.deviceId,
        location: newLocation,
        listItemName: device.listItemName,
        element: device.element,
        topic: device.topic,
        subscribeTopic: device.subscribeTopic,
        icon: device.icon,
        roomName: device.roomName,
        brightness: device.brightness,
      );
      devices[index] = newDevice;
      deviceStates[newLocation] = deviceStates.remove(device.location) ?? false;
      devices.add(newDevice);
      saveDevices();
    });
  }

  void toggleHandler(bool value, {bool isRelay = false}) async {
    setState(() {
      deviceStates[device.deviceId] = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${device.deviceId}_isOn', value);

    print("🔁 State updated successfully for ${device.deviceId}: ${value ? 'ON' : 'OFF'}");
  }


  /// 1. Handle Group Devices first
  if (lowerName.contains("group single light")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupLights(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
  else if (lowerName.contains("group fan")) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => FanGroup(
    //       device: device,
    //       isOn: savedState,
    //       onToggle: toggleHandler,
    //       onNameChanged: updateDeviceName,
    //       mqttService: mqttService,
    //     ),
    //   ),
    // );
  }
  else if (lowerName.contains("group strip")) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => GroupStrip(
    //       device: device,
    //       isOn: savedState,
    //       onToggle: toggleHandler,
    //       onNameChanged: updateDeviceName,
    //       mqttService: mqttService,
    //     ),
    //   ),
    // );
  }
  else if (lowerName.contains("group light")) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => GroupSubnode(
    //       device: device,
    //       isOn: savedState,
    //       onToggle: toggleHandler,
    //       onNameChanged: updateDeviceName,
    //       mqttService: mqttService,
    //     ),
    //   ),
    // );
  }

  /// 2. Handle Individual Devices after
  else if (lowerName.contains("fan")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Fan(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
  else if (lowerName.contains("subnode supply")) {Navigator.push(context,
        MaterialPageRoute(
          builder: (context) => SubNodeSupply(
            deviceId: "",
            deviceLocation: '',
            device: device,
            isOn: savedState,
            onToggle: toggleHandler,
            onNameChanged: updateDeviceName,
            mqttService: mqttService,
          ),
        ),
    );}
  else if (lowerName.contains("strip light")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StripLight(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
  else if (lowerName.contains("relay")) { Navigator.push( context,
      MaterialPageRoute(
        builder: (context) => Relay(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    ); }
  else if (lowerName.contains("exhaust")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Exhaust(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
  // else if (lowerName.contains("curtain")) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => Curtain(
  //         deviceId: "",
  //         deviceLocation: '',
  //         device: device,
  //         isOn: savedState,
  //         onToggle: toggleHandler,
  //         onNameChanged: updateDeviceName,
  //         mqttService: mqttService,
  //       ),
  //     ),
  //   );
  // }
  else if (lowerName.contains("dimmer")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Dimmer(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
  else if (lowerName.contains("ac")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Ac(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
  else if (lowerName.contains("individual subnode") || lowerName.contains("individual strip")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualBox(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
  // else if (lowerName.contains("sensor")) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => Sensor(
  //         deviceId: "",
  //         deviceLocation: '',
  //         device: device,
  //         isOn: savedState,
  //         onToggle: toggleHandler,
  //         onNameChanged: updateDeviceName,
  //         mqttService: mqttService,
  //       ),
  //     ),
  //   );
  // }
  // else if (lowerName.contains("rgb strip")) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => RGBStrip(
  //         deviceId: "",
  //         deviceLocation: '',
  //         device: device,
  //         isOn: savedState,
  //         onToggle: toggleHandler,
  //         onNameChanged: updateDeviceName,
  //         mqttService: mqttService,
  //       ),
  //     ),
  //   );
  // }
  else if (lowerName.contains("smps")) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SMPSController(
          deviceId: "",
          deviceLocation: '',
          device: device,
          isOn: savedState,
          onToggle: toggleHandler,
          onNameChanged: updateDeviceName,
          mqttService: mqttService,
        ),
      ),
    );
  }
}
