import 'dart:convert';
import 'package:smart_control/Devices_Structure/Devices_Structure_Json.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Drawer_Access_Main/Export_Import/Export_Json.dart';
import '../Drawer_Access_Main/Export_Import/Import_Json.dart';
import '../Drawer_Access_Main/Global_Topic/Topic_Load.dart';
import '../Drawer_Access_Main/about_swaro.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../Drawer_Access_Main/Tabular_Stored_Data.dart';
import '../Temprature_Box/CardBaseTempratrure/CardBaseTemp.dart';
import '../Temprature_Box/CardBaseTempratrure/Weather_Provider.dart';
import '../Temprature_Box/Parameter_Box.dart';
import '../Temprature_Box/Weather_Provider.dart';
import '../Drawer_Access_Main/Global_Topic/Global_Topics.dart';
import '../Drawer_Access_Main/Subscribe_Data_Log.dart';
import '../utils/global_controller.dart';
import 'Account_Profile_Page/Main_Setting_Page.dart';
import 'Card_Map_Base_Screen_Widget/Card_Base_Screen.dart';
import 'Card_Map_Base_Screen_Widget/Map_Base_Screen.dart';
import 'Scenes/Active_Provider.dart';
import 'Scenes/All_Scenes_Access.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required String role});
  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController topicController = TextEditingController();
  final TextEditingController subscribeTopicController = TextEditingController();
  final TextEditingController publishTopicController = TextEditingController();
  final TextEditingController publishMessageController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController fileController = TextEditingController();

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
    'Individual device': 'assets/icons/Card_Icons/ListFan.svg',
    'Group device': 'assets/icons/Card_Icons/ListGroup.svg',
  };
  final List<Device> _devices = [];
  final Map<String, bool> _deviceStates = {};
  String searchQuery = "";
  List<Device> displayedDevices = [];
  List<Device> allDevices = [];
  List<String> roomNames = [];
  List<String> filteredSubscribeItems = [];
  String savedTopic = "";
  String savedSubscribeTopic = "";
  bool isDrawerOpen = false;
  Set<String> selectedTopics = {};
  String selectedTopic = "No topic selected";
  String? selectedRoom;
  String selectedTab = 'Room';
  String savedName = '';
  late Future<Map<String, dynamic>> weatherData;
  String activeRoom = '';
  bool _showHome = true;


  @override
  void initState() {
    super.initState();
    _loadSavedTopic();
    _loadRoomsFromSharedPrefs();
    _loadSubscribeTopicsFromSharedPrefs();
    _saveSubscribeTopicsToSharedPrefs();
    _loadSelectedRoom();
    _loadUserName();
    _loadToggleState();
    usernameNotifier.addListener(_handleUsernameChange);
    _loadDevices();
    loadTopics();
    Future.microtask(() {
      print("🟢 About to fetch AQI & UV");
      Provider.of<WeatherProvider>(context, listen: false).fetchAQIAndUV();
    });
    Future.microtask(() {
      print("🟢 About to fetch AQI & UV for Cards ");
      Provider
          .of<CardBaseWeatherProvider>(context, listen: false)
          .cardFetchAQIAndUV();
    });
  }

  @override
  void dispose() {
    usernameNotifier.removeListener(_handleUsernameChange);
    super.dispose();
  }

  void _handleUsernameChange() {
    setState(() {
      savedName = usernameNotifier.value;
    });
  }

  Future<List<String>> _loadRoomsFromSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> rooms = prefs.getStringList('saved_rooms') ?? [];
    return rooms; // ✅ Return the loaded rooms
  }

  Future<void> _loadSelectedRoom() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedRoom = prefs.getString('selected_room'); // ✅ Load saved room
    });

    print("🏠 Selected Room: $selectedRoom"); // Debugging
  }

  Future<void> _loadSubscribeTopicsFromSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedSubscribeTopics = prefs.getStringList(
        'saved_subscribeTopics') ?? [];

    setState(() {
      filteredSubscribeItems.clear(); // Clear old data before adding new ones
      filteredSubscribeItems.addAll(
          savedSubscribeTopics); // Load topics from SharedPreferences
    });

    print(
        "Loaded Subscribe Topics: $filteredSubscribeItems"); // ✅ Debugging log
  }

  Future<void> _saveSubscribeTopicsToSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_subscribeTopics', filteredSubscribeItems);
    print("📦 Saved Subscribed Topics: $filteredSubscribeItems"); // ✅ Debugging
  }

  Future<void> _loadDevices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedDevices = prefs.getStringList('saved_devices');

    if (savedDevices == null || savedDevices.isEmpty) {
      print("⚠️ No saved devices found.");
      return;
    }

    print("📦 Raw Saved Devices: $savedDevices");

    List<Device> loadedDevices = [];
    Map<String, bool> loadedStates = {};

    // ✅ Get MQTTService instance
    MQTTService mqttService = Provider.of<MQTTService>(context, listen: false);

    for (String item in savedDevices) {
      try {
        Map<String, dynamic> json = jsonDecode(item);
        Device device = Device.fromJson(json);
        loadedDevices.add(device);

        bool deviceState = prefs.getBool('${device.deviceId}_isOn') ?? false;
        loadedStates[device.deviceId] = deviceState;

        // Print the device state
        print("🔌 Device: ${device.deviceId}, State: ${deviceState
            ? 'ON'
            : 'OFF'}");

        // ✅ Queue message instead of publishing immediately
        // if (device.topic.isNotEmpty) {
        //   String message = "#*2*${device.element}*1*1*#";
        //   mqttService.queueMessage(device.topic, message);
        // }

      } catch (e) {
        print("❌ JSON Decode Error: $e");
      }
    }

    setState(() {
      _devices.clear();
      _devices.addAll(loadedDevices);
      _deviceStates.clear();
      _deviceStates.addAll(loadedStates);
    });

    print("✅ Loaded Devices: ${_devices.length}");
  }

  void _loadSavedTopic() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String loadedTopic = prefs.getString('saved_topic') ?? '';
    if (mounted) {
      setState(() {
        savedTopic = loadedTopic; // ✅ Store the saved topic
      });
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('user_name') ?? '';
    setState(() {
      savedName = name;
    });

    usernameNotifier.value = name; // sync notifier on first load
  }

  void _showBackendData(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> allPrefs = {};
    for (var key in prefs.getKeys()) {
      allPrefs[key] = prefs.get(key);
    }

    String formattedData = const JsonEncoder.withIndent("  ").convert(allPrefs);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Raw Backend Data"),
          content: SingleChildScrollView(
            child: SelectableText(
              formattedData.isNotEmpty ? formattedData : "No data found",
              style: const TextStyle(fontFamily: "monospace"),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete All Data"),
          content: const Text(
              "Are you sure you want to permanently delete all saved data?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear persistent storage

                setState(() {
                  _devices.clear(); // 👈 Clear in-memory list too
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("All data has been permanently deleted.")),
                );

                Navigator.pop(context); // Close dialog
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> showSubscribeOptions(BuildContext context) async {
    await _loadSubscribeTopicsFromSharedPrefs(); // ✅ Load topics before showing modal
    _showSubscribeOption(context); // ✅ Now show modal
  }

  void _showSubscribeOption(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final MQTTService mqttService = Provider.of<MQTTService>(
        context, listen: false);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Set<String> allTopics = Set.from(
        prefs.getStringList('saved_subscribeTopics') ??
            []); // ✅ Load updated topics
    Set<String> subscribedTopics = mqttService
        .subscribedTopics; // MQTT subscribed topics

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom + 20.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select or Enter Topics",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(thickness: 1, height: 20),

                  if (allTopics.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: allTopics.length,
                        itemBuilder: (context, index) {
                          String topic = allTopics.elementAt(index);
                          bool isSubscribed = subscribedTopics.contains(topic);

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(
                                isSubscribed ? Icons.check_circle : Icons
                                    .cancel,
                                color: isSubscribed ? Colors.green : Colors.red,
                              ),
                              title: Text(topic, style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                              onTap: () {
                                setModalState(() {
                                  if (isSubscribed) {
                                    mqttService.unsubscribe(topic);
                                    subscribedTopics.remove(topic);
                                  } else {
                                    mqttService.subscribe(topic);
                                    subscribedTopics.add(topic);
                                  }
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isSubscribed
                                          ? "❌ Unsubscribed from $topic"
                                          : "✅ Subscribed to $topic",
                                    ),
                                    backgroundColor: isSubscribed
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Text(
                      "No topics available. Enter a new one below.",
                      style: TextStyle(color: Colors.grey),
                    ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Enter new topics (comma-separated)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          String newTopics = controller.text.trim();
                          if (newTopics.isNotEmpty) {
                            List<String> newTopicList = newTopics
                                .split(',')
                                .map((e) => e.trim())
                                .toList();

                            SharedPreferences prefs = await SharedPreferences
                                .getInstance();
                            List<String> savedSubscribeTopics = prefs
                                .getStringList('saved_subscribeTopics') ?? [];

                            for (String topic in newTopicList) {
                              if (topic.isNotEmpty &&
                                  !savedSubscribeTopics.contains(topic)) {
                                savedSubscribeTopics.add(topic);
                                mqttService.subscribe(
                                    topic); // Subscribe to new topics
                              }
                            }

                            await prefs.setStringList(
                                'saved_subscribeTopics', savedSubscribeTopics);

                            setModalState(() {
                              allTopics.clear();
                              allTopics.addAll(savedSubscribeTopics);
                            });

                            print(
                                "✅ Saved Subscribe Topics: $allTopics"); // Debugging log
                          }

                          // Close the modal
                          Navigator.pop(context);

                          // Show success message
                          if (newTopics.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ Subscribed to: ${newTopics}"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text("Subscribe"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Export Devices',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Do you want to export all saved devices as a JSON file?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    'Cancel', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  exportDevicesAndSpaces(context);
                },
                child: const Text(
                    'Export', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Import Devices',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),),
            content: Text(
              'Import devices from JSON file? This will overwrite existing data.',
              style: TextStyle(color: Colors.white70),),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                    'Cancel', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  final mqttService = Provider.of<MQTTService>(
                      context, listen: false);
                  importDevicesAndSpaces(context, mqttService);
                },
                child: const Text(
                    'Import', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
    );
  }

  String getGreeting() {
    final hour = DateTime
        .now()
        .hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final weekday = getWeekdayName(now.weekday);
    final formattedDate = " ${getMonthName(now.month)} ${now.day}, ${now.year}";
    return "$weekday, $formattedDate";
  }

  String getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }

  String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _loadToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showHome = prefs.getBool('showHome') ?? true; // default to card
    });
  }


  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery
        .of(context)
        .orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: _buildAppBar(context),
        ),
      ),
      endDrawer: SizedBox(child: _buildDrawer(context)),
      body: SafeArea(
        child: isLandscape
            ? _buildPortraitBody(context)
            : _buildPortraitBody(context),
      ),
    );
  }

  Widget _buildPortraitBody(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _showHome
          ? _buildPortraitBodyCard(context)
          : _buildPortraitBodyCard(context),
    );
  }

  Widget _buildPortraitBodyCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double initialFraction = 300 / constraints.maxHeight;
        final double minFraction = 180 / constraints.maxHeight;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: CardBaseScreen(),
                  ),
                ),
              ],
            ),

              DraggableScrollableSheet(
              initialChildSize: initialFraction,
        minChildSize: minFraction,
        maxChildSize: 1.0,

        builder: (context, scrollController) {
        return Container(
        decoration: const BoxDecoration(
        color: Color(0xff171717),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),

        padding: const EdgeInsets.all(14),

        child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
        children: [


        Center(
        child: Container(
        width: 55,
        height: 5,
        decoration: BoxDecoration(
        color: Colors.grey[500],
        borderRadius: BorderRadius.circular(10),
        ),
        ),
        ),

        const SizedBox(height: 12),

        SizedBox(
        height: 600,
        child: DynamicSceneScreen(),
        ),
        ],
        ),
        ),
        );
        },
              ),

        ],
        );
      },
    );
  }





  Widget _buildDrawer(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);

    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SWARO',
                  style: TextStyle(color: Colors.white, fontSize: 26),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.settings_input_antenna,
                          color: mqttService.isConnected ? Colors
                              .lightGreenAccent : Colors.red,
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          String username = prefs.getString('mqtt_username') ??
                              '';
                          String password = prefs.getString('mqtt_password') ??
                              '';

                          if (!mqttService.isConnected) {
                            if (username.isEmpty || password.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "⚠️ Fill the credentials first!"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              mqttService.connect(username, password);
                            }
                          } else {
                            mqttService.disconnect();
                          }
                        },
                      ),
                      SizedBox(
                        width: 100, // fixed width for consistent alignment
                        child: Text(
                          mqttService.isConnected
                              ? "Connected"
                              : "Tap to Connect",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text(
                "Raw Data", style: TextStyle(color: Colors.white)),
            onTap: () => _showBackendData(context),
          ),
          ListTile(
            leading: const Icon(Icons.publish, color: Colors.yellow),
            title: const Text("Topic", style: TextStyle(color: Colors.white)),
            onTap: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PublishTopicEdit()),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.grading, color: Colors.green),
            title: const Text(
                "Tabular Format Data", style: TextStyle(color: Colors.white)),
            onTap: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeviceTablePage()),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.get_app, color: Color(0xff00A1F1)),
            title: const Text(
                "Show Subscribed Data", style: TextStyle(color: Colors.white)),
            onTap: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ShowSubscribedDataScreen()),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.unsubscribe, color: Colors.orangeAccent),
            title: const Text("Show Subscribed Topics",
                style: TextStyle(color: Colors.white)),
            onTap: () => _showSubscribeOption(context),
          ),

          const Divider(color: Colors.grey),

          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.green),
            title: const Text(
                "Export Data", style: TextStyle(color: Colors.white)),
            onTap: () => _showExportDialog(context),
          ),

          ListTile(
            leading: const Icon(Icons.download, color: Color(0xff00A1F1)),
            title: const Text(
                "Import Data", style: TextStyle(color: Colors.white)),
            onTap: () => _showImportDialog(context),
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Data Permanently",
                style: TextStyle(color: Colors.white)),
            onTap: () => _confirmDeleteData(context),
          ),

          const Divider(color: Colors.grey),

          ListTile(
            leading: const Icon(
                Icons.info_outline_rounded, color: Colors.white),
            title: const Text(
                "About SWAJA ROBOTICS", style: TextStyle(color: Colors.white)),
            onTap: () =>
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutSwaro()),
                ),
          ),

        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);
    return AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${getGreeting()}, ${savedName.isNotEmpty
                              ? '$savedName!'
                              : 'User'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        getFormattedDate(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: mqttService.isConnected ? Colors
                                  .lightGreenAccent : Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [

          // IconButton(
          //   icon: Icon(
          //     _showHome ?  Icons.grid_view_rounded :Icons.maps_home_work_outlined  ,
          //     size: 27,
          //     color: Colors.white,
          //   ),
          //   onPressed: () async {
          //     final isHome = _showHome;
          //
          //     final confirm = await showDialog<bool>(
          //       context: context,
          //       builder: (ctx) => AlertDialog(
          //         title: const Text("Switch View"),
          //         content: Text(
          //           isHome
          //               ? "Are you sure you want to switch to Map view?"
          //               : "Are you sure you want to switch to Card view?",
          //         ),
          //         actions: [
          //           TextButton(
          //             onPressed: () => Navigator.pop(ctx, false),
          //             child: const Text("Cancel"),
          //           ),
          //           ElevatedButton(
          //             onPressed: () => Navigator.pop(ctx, true),
          //             child: Text(isHome ? "Switch to Map" : "Switch to Card"),
          //           ),
          //         ],
          //       ),
          //     );
          //
          //     if (confirm == true) {
          //       setState(() {
          //         _showHome = !_showHome;
          //       });
          //       _saveToggleState();
          //     }
          //   },
          // ),

          Builder(
            builder: (context) =>
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.menu, size: 28, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
          ),
        ]

    );
  }

}









