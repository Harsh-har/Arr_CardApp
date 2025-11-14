import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class MQTTService extends ChangeNotifier with WidgetsBindingObserver {
  late MqttServerClient _client;
  String? _broker;
  int? _port;
  late final String clientId;
  final List<Map<String, String>> _messageQueue = [];
  List<String> filteredSubscribeItems = [];


  bool _isConnected = false;
  bool _manualDisconnect = false;
  int _reconnectAttempts = 0;
  final List<String> _messages = [];
  Timer? _refreshTimer;
  Timer? _publishTimer;

  final Set<String> _allTopics = {};
  final Set<String> _subscribedTopics = {};
  String? _lastReceivedMessage;

  String _waterLevel = '--';
  String _temperature = '--';
  String _humidity = '--';

  String get waterLevel => _waterLevel;
  String get temperature => _temperature;
  String get humidity => _humidity;

  String? get lastReceivedMessage => _lastReceivedMessage;

  final Map<String, List<String>> _topicMessages = {};

  List<String> getMessagesForTopic(String topic) {
    return _topicMessages[topic] ?? [];
  }

  final Map<String, bool> _deviceStates = {};
  Map<String, bool> get deviceStates => _deviceStates;
  bool get isConnected => _isConnected;
  Set<String> get allTopics => _allTopics;
  List<String> get messages => _messages;
  Set<String> get subscribedTopics => _subscribedTopics;
  int _lastReceivedBrightness = 0;
  int get lastReceivedBrightness => _lastReceivedBrightness;
  final bool _initialStatusSent = false;
  String? lastSentWaterLevelStatus;
  String? lastMotorControlMessage;
  int? lastNotifiedEmptyLevel;
  int? lastNotifiedFullLevel;
  int? lastNotifiedTurnOnLevel;
  int? lastNotifiedTurnOffLevel;


  MQTTService() {
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    clientId = await _generateClientId();
    await _setupClient();
    await connectWithSavedCredentials();
    monitorNetwork();
    initializeSubscriptions();
    _startAutoRefresh();
    _loadLastBrightness();
    _loadLastValues();
  }

  Future<void> _setupClient() async {
    final prefs = await SharedPreferences.getInstance();
    _broker = prefs.getString('mqtt_broker') ?? '';
    _port = prefs.getInt('mqtt_port') ?? 1883;
    final username = prefs.getString('mqtt_username') ?? '';
    final password = prefs.getString('mqtt_password') ?? '';

    // Generate unique clientId
    final String clientId = await _generateClientId();

    _client = MqttServerClient.withPort(_broker!, clientId, _port!);
    _client.logging(on: true);
    _client.keepAlivePeriod = 30;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;

    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;
    _client.onSubscribed = _onSubscribed;
    _client.onUnsubscribed = _onUnsubscribed;
    _client.pongCallback = _pong;

    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .withWillTopic("last/will")
        .withWillMessage("Client disconnected")
        .withWillQos(MqttQos.atMostOnce);
  }

  Future<String> _generateClientId() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final String androidId = androidInfo.id ?? 'unknown';
        final String model = androidInfo.model ?? 'AndroidDevice';
        return 'Swaja_App_${model.replaceAll(' ', '_')}_$androidId';
      }
      else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        final String deviceId = iosInfo.identifierForVendor ?? 'unknown';
        final String deviceName = iosInfo.name ?? 'iPhone';
        return 'Swaja_App_${deviceName.replaceAll(' ', '_')}_$deviceId';
      }
      else {
        return 'Swaja_App_Unknown_Device';
      }
    } catch (e) {
      print("⚠️ DeviceInfo error: $e");
      return 'Swaja_App_Unknown';
    }
  }


  // Future<String> _generateClientId() async {
  //   final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   String deviceId = '';
  //   String deviceName = '';
  //
  //   if (Platform.isAndroid) {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     deviceId = androidInfo.androidId ?? 'unknown';
  //     deviceName = androidInfo.model ?? 'Android';
  //   } else if (Platform.isIOS) {
  //     IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //     deviceId = iosInfo.identifierForVendor ?? 'unknown';
  //     deviceName = iosInfo.name ?? 'iPhone';
  //   }
  //
  //   return 'Swaja_App_${deviceName.replaceAll(' ', '_')}_$deviceId';
  // }

  Future<void> connectWithSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    String username = prefs.getString('mqtt_username') ?? '';
    String password = prefs.getString('mqtt_password') ?? '';

    if (username.isNotEmpty && password.isNotEmpty) {
      await connect(username, password);
    } else {
      print("⚠️ Missing MQTT credentials!");
    }
  }

  Future<void> connect(String username, String password) async {
    try {
      print("🔄 Connecting to MQTT broker...");
      _manualDisconnect = false;

      // Update connection message with provided credentials
      _client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .withWillTopic("last/will")
          .withWillMessage("Client disconnected")
          .startClean()
          .withWillQos(MqttQos.atMostOnce);

      await _client.connect();

      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        _updateConnectionStatus(true);
        _reconnectAttempts = 0;

        // ✅ Do NOT print success here anymore
        // let _onConnected() handle it instead

        _client.updates?.listen(_onMessageReceived);
      } else {
        print("❌ MQTT Connection failed: ${_client.connectionStatus}");
        _updateConnectionStatus(false);
        attemptReconnect();
      }
    } catch (e) {
      print("❌ MQTT Connection error: $e");
      _updateConnectionStatus(false);
      attemptReconnect();
    }
  }

  Future<void> _onConnected() async {
    _updateConnectionStatus(true);
    print("✅ Successfully connected to MQTT!");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedTopics = prefs.getStringList('saved_subscribeTopics') ?? [];

    if (savedTopics.isNotEmpty) {
      print("📩 Re-subscribing to saved topics...");
      await Future.delayed(const Duration(milliseconds: 500));
      for (String topic in savedTopics) {
        if (_client.connectionStatus?.state == MqttConnectionState.connected) {
          _client.subscribe(topic, MqttQos.atLeastOnce);
          _subscribedTopics.add(topic);
          // print("✅ Subscribed to: $topic");
        }
      }
    } else {
      print("⚠️ No saved topics found to subscribe.");
    }
  }

  void _onDisconnected() {
    print("❌ MQTT Disconnected.");
    _updateConnectionStatus(false);

    if (!_manualDisconnect) {
      print("🔄 Reconnecting...");
      reconnect();
    }
  }

  void subscribe(String subscribeTopic) async {
    if (!_isConnected) {
      print("⚠️ Cannot subscribe, not connected!");
      return;
    }
    if (subscribeTopic.isEmpty) {
      print("⚠️ Cannot subscribe to an empty topic!");
      return;
    }
    if (_subscribedTopics.contains(subscribeTopic)) {
      print("✅ Already subscribed to: $subscribeTopic");
      return;
    }

    try {
      _client.subscribe(subscribeTopic, MqttQos.atLeastOnce);
      _subscribedTopics.add(subscribeTopic);
      _allTopics.add(subscribeTopic);

      // ✅ Save subscribed topics persistently
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedTopics = prefs.getStringList('saved_subscribeTopics') ?? [];
      if (!savedTopics.contains(subscribeTopic)) {
        savedTopics.add(subscribeTopic);
        await prefs.setStringList('saved_subscribeTopics', savedTopics);
      }

      print("📩 Subscribed to topic: $subscribeTopic");
      notifyListeners();
    } catch (e) {
      print("❌ Failed to subscribe to [$subscribeTopic]: $e");
    }
  }

  void disconnect() {
    _manualDisconnect = true;
    _client.disconnect();
    _updateConnectionStatus(false);
    print("🔴 Disconnected from MQTT");
    notifyListeners();
  }

  void monitorNetwork() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        print("🚫 Wi-Fi lost");
        _updateConnectionStatus(false);
      } else if (!_isConnected && !_manualDisconnect) {
        print("🌐 Wi-Fi restored, reconnecting...");
        reconnect();
      }
    });
  }

  void reconnect() {
    if (!_isConnected && !_manualDisconnect) {
      _reconnectAttempts = 0;
      connectWithSavedCredentials();
    }
  }

  void attemptReconnect() {
    if (_isConnected || _manualDisconnect) return;
    _reconnectAttempts++;
    int delay = (_reconnectAttempts * 2).clamp(2, 30);
    print(
        "🔄 Attempting to reconnect in $delay seconds... (Attempt $_reconnectAttempts)");
    Future.delayed(Duration(seconds: delay), () {
      if (!_isConnected && !_manualDisconnect) {
        connectWithSavedCredentials();
      }
    });
  }

  Future<void> loadSubscribeTopics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    filteredSubscribeItems = prefs.getStringList('saved_subscribeTopics') ?? [];

    print("✅ Loaded Subscribe Topics: $filteredSubscribeItems");
    notifyListeners();
  }

  Future<void> initializeSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedTopics = prefs.getStringList('saved_subscribeTopics') ?? [];

    for (String topic in savedTopics) {
      subscribe(topic);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_manualDisconnect) {
      print("🔄 App Resumed - Reconnecting MQTT...");
      reconnect();
    }
  }

  @override
  void dispose() {
    _publishTimer?.cancel();
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    super.dispose();
  }

  Future<void> _loadLastValues() async {
    final prefs = await SharedPreferences.getInstance();
    _temperature = prefs.getString('temperature') ?? '--';
    _humidity = prefs.getString('humidity') ?? '--';
    _waterLevel = prefs.getString('Water Level') ?? '--';
    notifyListeners();
  }

  Future<void> setTemperature(int data1, int data2) async {
    _temperature = '$data1';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temperature', _temperature);
    notifyListeners();
  }

  Future<void> setWaterLevel(int averageData) async {
    _waterLevel = '$averageData';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('Water Level', _waterLevel);
    notifyListeners();
  }

  Future<void> setHumidity(int data1, int data2) async {
    _humidity = '$data1';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('humidity', _humidity);
    notifyListeners();
  }

  Future<void> _loadLastBrightness() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastReceivedBrightness = prefs.getInt('last_brightness') ?? 0;
    print("🔄 Loaded Last Brightness: $_lastReceivedBrightness");
  }

  Future<void> _saveLastBrightness(int brightness) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_brightness', brightness);
    print("💾 Saved Last Brightness: $brightness");
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_isConnected) {
        notifyListeners();
      }
    });
  }

  void handleMessage(String message) {
    _lastReceivedMessage = message;
    notifyListeners();
  }

  List<String> _parseMessage(String message) {
    message = message.replaceAll("#*", "").replaceAll("*#", ""); // Remove delimiters
    return message.split("*"); // Split into parts
  }

  bool _isValidMessage102(String message) {
    RegExp regex = RegExp(r'^#\*102\*[^*]+\*[^*]+\*[^*]+\*[^*]+\*#$');
    return regex.hasMatch(message);
  }

  bool _isValidMessage105(String message) {
    RegExp regex = RegExp(r'^#\*105\*[^*]+\*[^*]+\*[^*]+\*[^*]+\*#$');
    return regex.hasMatch(message);
  }

  bool _isValidMessage109(String message) {
    RegExp regex = RegExp(r'^#\*109\*[^*]+\*[^*]+\*[^*]+\*#$');
    return regex.hasMatch(message);
  }

  bool _isValidMessage110(String message) {
    RegExp regex = RegExp(r'^#\*110\*[^*]+\*[^*]+\*[^*]+\*#$');
    return regex.hasMatch(message);
  }

  bool _isValidMessage123(String message) {
    RegExp regex = RegExp(r'^#\*123\*[^*]+\*[^*]+\*[^*]+\*[^*]+\*#$');
    return regex.hasMatch(message);
  }

  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> event) async {
    final MqttPublishMessage receivedMessage = event[0].payload as MqttPublishMessage;
    final String topic = event[0].topic;
    final String message = MqttPublishPayload.bytesToStringAsString(receivedMessage.payload.message);

    print("📩 Received message on [$topic]: $message");

    if (_isValidMessage102(message)) {
      // ✅ Message is valid, parse and print data
      List<String> parts = _parseMessage(message);
      String oppCode = parts[0];
      String element = parts[1];
      String farmWare = parts[2];
      String appId = parts[3];
      String brightness = parts[4];

      // ✅ Print parsed data
      print("✅ Parsed MQTT Message:");
      print("🔹 Operation Code: $oppCode");
      print("🔹 Element: $element");
      print("🔹 farmWare: $farmWare");
      print("🔹 App ID: $appId");
      print("🔹 Brightness: $brightness");

      // ✅ Handle parsed message
      handleParsedMessage102(oppCode, element, farmWare, appId, brightness, topic);
    }

    else if (_isValidMessage105(message)) {
      // ✅ Message is valid, parse and print data
      List<String> parts = _parseMessage(message);
      String oppCode = parts[0];
      String element = parts[1];
      String brightness = parts[2];
      String data1 = parts[3];
      String data2 = parts[4];

      // ✅ Print parsed data
      print("✅ Parsed MQTT Message:");
      print("🔹 Operation Code: $oppCode");
      print("🔹 Element: $element");
      print("🔹 brightness: $brightness");
      print("🔹 Data1: $data1");
      print("🔹 Data2: $data2");

      // ✅ Handle parsed message
      handleParsedMessage105(oppCode, element, brightness, data1, data2,topic);
    }

    else if (_isValidMessage109(message)) {
      // ✅ Message is valid, parse and print data
      List<String> parts = _parseMessage(message);
      String oppCode = parts[0];
      String element = parts[1];
      String data1T = parts[2];
      String data2T = parts[3];

      // ✅ Print parsed data
      print("✅ Parsed MQTT Message:");
      print("🔹 Operation Code: $oppCode");
      print("🔹 Element: $element");
      print("🔹 Data1T: $data1T");
      print("🔹 Data2T: $data2T");

      // ✅ Handle parsed message
      handleParsedMessageTH(oppCode, element,data1T,data2T);
    }

    else if (_isValidMessage110(message)) {
      // ✅ Message is valid, parse and print data
      List<String> parts = _parseMessage(message);
      String oppCode = parts[0];
      String element = parts[1];
      String data1H = parts[2];
      String data2H = parts[3];

      // ✅ Print parsed data
      print("✅ Parsed MQTT Message:");
      print("🔹 Operation Code: $oppCode");
      print("🔹 Element: $element");
      print("🔹 Data1T: $data1H");
      print("🔹 Data2T: $data2H");

      // ✅ Handle parsed message
      handleParsedMessageTH(oppCode, element,data1H,data2H);
    }

    else if (_isValidMessage123(message)) {
      // ✅ Message is valid, parse and print data
      List<String> parts = _parseMessage(message);
      String oppCode = parts[0];
      String element = parts[1];
      String currentData1 = parts[2];
      String currentData2 = parts[3];
      String averageData = parts[4];
      // ✅ Print parsed data
      print("✅ Parsed MQTT Message:");
      print("🔹 Operation Code: $oppCode");
      print("🔹 Element: $element");
      print("🔹 Current Data1: $currentData1");
      print("🔹 Current Data2: $currentData2");
      print("🔹 Average Data: $averageData");

      // ✅ Handle parsed message
      handleParsedMessage123(oppCode, element, currentData1, currentData2, averageData);
    }

    else {
      print("⚠️ Invalid message format: $message");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    _topicMessages[topic] = (_topicMessages[topic] ?? [])..insert(0, message);

    List<String> messages = prefs.getStringList(topic) ?? [];
    messages.insert(0, message);

    if (messages.length > 10) {
      messages = messages.sublist(0, 10);
    }

    await prefs.setStringList(topic, messages);

    if (hasListeners) {
      notifyListeners();
    }
  }

  Future<void> handleParsedMessage102(String oppCode, String element, String farmWare, String appId, String brightness, String subscribeTopic,) async {
    if (oppCode != "102") return;

    print("🔆 Handling brightness update...");

    // -------------------- SharedPreferences --------------------
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // -------------------- Scene Trigger --------------------
    if (element == "40") {
      print("🎬 Scene Trigger → Element: $element, SceneID: $brightness, Topic: $subscribeTopic");

      final prefs = await SharedPreferences.getInstance();

      // Convert brightness (sceneId) into int
      final int sceneId = int.tryParse(brightness) ?? 0;

      // 🔔 Notify UI listeners
      // sceneTriggerNotifier.value = SceneTrigger(
      //   element: element,
      //   sceneId: sceneId.toString(),
      //   topic: subscribeTopic,
      // );

      // 📝 Save latest sceneId
      await prefs.setInt('latest_scene_$subscribeTopic', sceneId);

      // 🔄 Loop through all saved devices and update their ON/OFF state
      final savedDevices = prefs.getStringList('saved_devices') ?? [];
      for (String item in savedDevices) {
        try {
          final json = jsonDecode(item);
          final String? deviceId = json['id']?.toString();
          if (deviceId == null) continue;

          // Get the scene id mapped to this device
          final int? mappedSceneId = prefs.getInt('scene_id_$deviceId');
          if (mappedSceneId == null) continue;

          // If device's scene matches the received scene id → ON, else → OFF
          final bool isOn = mappedSceneId == sceneId;
          await prefs.setBool('scene_device_state_$deviceId', isOn);
          print("🔗 Device $deviceId → ${isOn ? "ON" : "OFF"}");
        } catch (e) {
          print("❌ Error decoding device JSON: $e");
        }
      }

      // 🔔 Notify UI to refresh
      // deviceRefreshNotifier.value = true;

      return;
    }

    // -------------------- Normal Device --------------------
    int brightnessValue = int.tryParse(brightness) ?? 0;
    bool isOn = brightnessValue > 0;

    List<String>? savedDevices = prefs.getStringList('saved_devices');
    if (savedDevices == null || savedDevices.isEmpty) {
      print("⚠️ No saved devices found.");
      return;
    }

    String deviceName = "Unknown Device";
    for (String item in savedDevices) {
      try {
        Map<String, dynamic> json = jsonDecode(item);
        Device device = Device.fromJson(json);

        // Match both element AND topic
        if (device.element == element && device.subscribeTopic == subscribeTopic) {
          deviceName = device.location;
          break;
        }
      } catch (e) {
        print("❌ JSON Decode Error: $e");
      }
    }

    if (deviceName == "Unknown Device") {
      print("⛔ Unknown device with element '$element' and topic '$subscribeTopic'. Skipping update.");
      return;
    }

    // Load last saved brightness
    int savedBrightness = prefs.getInt('${deviceName}_brightness') ?? 100;

    if (!isOn) {
      brightnessValue = savedBrightness;
    } else if (brightnessValue > 0) {
      await prefs.setInt('${deviceName}_brightness', brightnessValue);
    }

    // Save ON/OFF state
    await prefs.setBool('${deviceName}_isOn', isOn);
    // deviceRefreshNotifier.value = true;

    _lastReceivedBrightness = brightnessValue;
    await _saveLastBrightness(brightnessValue);

    _deviceStates[deviceName] = isOn;
    notifyListeners();

    print("✅ Updated Device [$deviceName]: ${isOn ? 'ON' : 'OFF'}, Brightness: $brightnessValue");
  }

  Future<void> handleParsedMessage105(String oppCode, String element, String brightness, String data1, String data2, String currentTopic,) async {
    if (oppCode == "105") {
      print("🔆 Handling brightness update...");

      int brightnessValue = int.tryParse(brightness) ?? 0;
      bool isOn = brightnessValue > 0;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? savedDevices = prefs.getStringList('saved_devices');
      if (savedDevices == null || savedDevices.isEmpty) {
        print("⚠️ No saved devices found.");
        return;
      }

      String deviceName = "Unknown Device";
      String deviceRoom = "";
      for (String item in savedDevices) {
        try {
          Map<String, dynamic> json = jsonDecode(item);
          Device device = Device.fromJson(json);

          // ✅ Match both element and topic
          if (device.element == element && device.subscribeTopic == currentTopic) {
            deviceName = device.location;
            deviceRoom = device.roomName;
            break;
          }
        } catch (e) {
          print("❌ JSON Decode Error: $e");
        }
      }

      if (deviceName == "Unknown Device") {
        print("⚠️ Device not found for element: $element and topic: $currentTopic");
        return;
      }

      // ✅ Load last saved brightness
      int savedBrightness = prefs.getInt('${deviceName}_brightness') ?? 100;

      if (!isOn) {
        brightnessValue = savedBrightness; // Keep previous brightness when off
      } else if (brightnessValue > 0) {
        await prefs.setInt('${deviceName}_brightness', brightnessValue); // Save new brightness
      }

      // ✅ Save ON/OFF state
      await prefs.setBool('${deviceName}_isOn', isOn);

      // ✅ Update local state
      _deviceStates[element] = isOn;
      _lastReceivedBrightness = brightnessValue;
      await _saveLastBrightness(brightnessValue);

      // ✅ Trigger UI update only for this device
      _deviceStates[deviceName] = isOn;
      // deviceRefreshNotifier.value = true;

      print("✅ Updated [$deviceRoom ➤ $deviceName]: ${isOn ? 'ON' : 'OFF'}, Brightness: $brightnessValue");
    }
  }

  void handleParsedMessageTH(String oppCode, String element, String data1, String data2) {
    print("📩 Received TH message → oppCode: $oppCode, data1: $data1, data2: $data2");

    final context = navigatorKey.currentContext;
    if (context == null) {
      print("❌ navigatorKey.currentContext is null");
      return;
    }

    final mqttService = Provider.of<MQTTService>(context, listen: false);

    int? d1 = int.tryParse(data1);
    int? d2 = int.tryParse(data2);

    if (d1 == null || d2 == null) {
      print("❌ Invalid values for temperature/humidity → data1: $data1, data2: $data2");
      return;
    }

    if (oppCode == "109") {
      mqttService.setTemperature(d1, d2);
    } else if (oppCode == "110") {
      mqttService.setHumidity(d1, d2);
    } else {
      print("❌ Unknown oppCode in TH message: $oppCode");
    }
  }

  void handleParsedMessage123(String oppCode, String element, String currentData1, String currentData2, String averageData) {
    print(
        "📩 Received Water Level message → oppCode: $oppCode, Element: $element, data1: $currentData1, data2: $currentData2, data3: $averageData");

    final context = navigatorKey.currentContext;
    if (context == null) {
      print("❌ navigatorKey.currentContext is null");
      return;
    }

    final mqttService = Provider.of<MQTTService>(context, listen: false);
    // final notificationService = NotificationService(); // Ensure this is your notification class instance

    int? avgLevel = int.tryParse(averageData);

    if (avgLevel == null) {
      print("❌ Invalid average water level value: $averageData");
      return;
    }

    if (oppCode == "123") {
      mqttService.setWaterLevel(avgLevel);

      if (avgLevel > 55 || avgLevel < 24) {
        print("🔕 Ignored value: $avgLevel (out of 30–55 range)");
        return;
      }

// // 🔁 Notify when empty (50–51)
//       if (avgLevel >= 50 && avgLevel <= 51) {
//         if (lastNotifiedEmptyLevel != avgLevel) {
//           notificationService.showNotification(
//             id: 2,
//             title: 'Water Tank Status',
//             body: '⚠️ Water tank is empty!',
//           );
//           lastSentWaterLevelStatus = 'empty';
//           lastNotifiedEmptyLevel = avgLevel;
//         }
//
//         // Reset motor turn-on so it can happen again
//         lastMotorControlMessage = null;
//       }
//
// // 🔁 Notify when very low (52–55): "turn on motor"
//       else if (avgLevel >= 52 && avgLevel <= 55) {
//         if (lastNotifiedTurnOnLevel != avgLevel) {
//           notificationService.showNotification(
//             id: 3,
//             title: 'Motor Alert',
//             body: '🛠️ Water is low. Please turn on the motor!',
//           );
//           lastMotorControlMessage = 'turn_on';
//           lastNotifiedTurnOnLevel = avgLevel;
//         }
//
//         // Reset empty state so it can re-trigger later
//         lastSentWaterLevelStatus = null;
//         lastNotifiedEmptyLevel = null;
//       }
//
// // 🔁 Notify when full (32–33)
//       else if (avgLevel >= 26 && avgLevel <= 27) {
//         if (lastNotifiedFullLevel != avgLevel) {
//           notificationService.showNotification(
//             id: 2,
//             title: 'Water Tank Status',
//             body: '🚰 Water tank is full!',
//           );
//           lastSentWaterLevelStatus = 'full';
//           lastNotifiedFullLevel = avgLevel;
//         }
//
//         lastMotorControlMessage = null;
//         lastNotifiedTurnOffLevel = null;
//       }
//
// // 🔁 Notify when overflowing (30–31): "turn off motor"
//       else if (avgLevel >= 24 && avgLevel < 26) {
//         if (lastNotifiedTurnOffLevel != avgLevel) {
//           notificationService.showNotification(
//             id: 3,
//             title: 'Motor Alert',
//             body: '⚠️ Water is overflowing. Please turn off the motor!',
//           );
//           lastMotorControlMessage = 'turn_off';
//           lastNotifiedTurnOffLevel = avgLevel;
//         }
//
//         lastSentWaterLevelStatus = null;
//         lastNotifiedFullLevel = null;
//       }



      else {
        lastSentWaterLevelStatus = null;
        lastMotorControlMessage = null;
      }
    } else {
      print("❌ Unknown oppCode for water level: $oppCode");
    }
  }

  Future<int> getRealTimeBrightness() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastReceivedBrightness = prefs.getInt('last_brightness') ?? 0;
    print("🔄 Real-time brightness fetched: $_lastReceivedBrightness");
    return _lastReceivedBrightness;
  }

  void clearMessagesForTopic(String topic) async {
    if (_topicMessages.containsKey(topic)) {
      _topicMessages[topic] = [];
      notifyListeners();
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(topic);
    print("🗑️ Cleared messages for topic [$topic]");
  }

  void queueMessage(String topic, String message) {
    if (_isConnected) {
      publish(topic, message); // Publish immediately if connected
    } else {
      if (!_initialStatusSent && message.startsWith("#*2*")) {
        _messageQueue.add({"topic": topic, "message": message});
        print("🕒 Queued STATUS message for [$topic]: $message");
      } else {
        print("⏭️ Skipping non-status message while disconnected: $message");
      }
    }
  }

  void _updateConnectionStatus(bool status) {
    if (_isConnected != status) {
      _isConnected = status;
      notifyListeners();
    }
  }

  void publish(String topic, String message) {
    if (!_isConnected) {
      print("⚠️ Cannot publish, MQTT is not connected.");
      return;
    }

    List<String> parts = message.split('*');

    // ✅ Allow publish if EITHER condition is valid
    if (!(parts.length == 6 || message.startsWith('#*3*'))) {
      print("⛔ Invalid message format, not publishing: $message");
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addUTF8String(message);

    try {
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print("✅ Published to [$topic]: $message");
    } catch (e) {
      print("❌ Publish error: $e");
    }

    _messages.insert(0, "[Me]: $message");
    notifyListeners();
  }

  void unsubscribe(String subscribeTopic) async {
    if (!_isConnected) {
      print("⚠️ Cannot unsubscribe, not connected!");
      return;
    }
    if (subscribeTopic.isEmpty) {
      print("⚠️ Cannot unsubscribe from an empty topic!");
      return;
    }
    if (!_subscribedTopics.contains(subscribeTopic)) {
      print("⚠️ Not subscribed to: $subscribeTopic");
      return;
    }

    try {
      _client.unsubscribe(subscribeTopic);
      _subscribedTopics.remove(subscribeTopic);


      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedTopics = prefs.getStringList('saved_subscribeTopics') ?? [];
      savedTopics.remove(subscribeTopic);
      await prefs.setStringList('saved_subscribeTopics', savedTopics);

      print("📤 Unsubscribed from topic: $subscribeTopic");
      notifyListeners();
    } catch (e) {
      print("❌ Failed to unsubscribe from [$subscribeTopic]: $e");
    }
  }

  // Future<void> publishToAllTopics() async {
  //   if (!_isConnected) {
  //     print("⚠️ Cannot publish, MQTT is not connected.");
  //     return;
  //   }
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final keys = prefs.getKeys();
  //
  //   // 🔹 Collect all publish topics (Map<roomKey, topic>)
  //   final publishTopics = keys
  //       .where((key) => key.startsWith("saved_topic_"))
  //       .map((key) => MapEntry(key, prefs.getString(key)))
  //       .where((entry) => entry.value != null && entry.value!.isNotEmpty)
  //       .toList();
  //
  //   if (publishTopics.isEmpty) {
  //     print("⚠️ No publish topics found in SharedPreferences.");
  //     return;
  //   }
  //
  //   // 🔹 Track already sent (topic + message) pairs
  //   final sentCommands = <String>{};
  //
  //   for (final entry in publishTopics) {
  //     final key = entry.key;
  //     final topic = entry.value!;
  //
  //     // Default message
  //     const defaultMessage = "#*10*1*1*1*#";
  //     final commandKey = "$topic|$defaultMessage";
  //
  //     if (!sentCommands.contains(commandKey)) {
  //       publish(topic, defaultMessage);
  //       sentCommands.add(commandKey);
  //     }
  //
  //     // ✅ Extra commands only for Engineering Room
  //     if (key == "saved_topic_Engineering Room") {
  //       final extraMessages = [
  //         "#*2*34*1*2*#",
  //         "#*2*37*1*2*#",
  //         "#*2*37*1*3*#",
  //       ];
  //
  //       for (final msg in extraMessages) {
  //         final extraKey = "$topic|$msg";
  //         if (!sentCommands.contains(extraKey)) {
  //           publish(topic, msg);
  //           sentCommands.add(extraKey);
  //         }
  //       }
  //
  //       print("🚀 Extra Engineering Room commands sent.");
  //     }
  //   }
  //
  //   print("✅ Message sent to all publish topics.");
  // }


  void _onSubscribed(String topic) => print("✅✅Subscribed to:: $topic");
  void _onUnsubscribed(String? topic) => print("Unsubscribed from: $topic");
  void _pong() => print("Pong received from broker");
  void simulateMessageReceive(String message) {
    handleMessage(message);
  }
}



