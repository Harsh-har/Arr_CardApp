import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../MQTT_STRUCTURE/MQTT_SETUP.dart';


class DynamicSceneScreen extends StatefulWidget {
  const DynamicSceneScreen({super.key});

  @override
  State<DynamicSceneScreen> createState() => _DynamicSceneScreenState();
}

class _DynamicSceneScreenState extends State<DynamicSceneScreen> {
  final Map<String, bool> _deviceStates = {};
  final List<Map<String, dynamic>> _scenes = [];
  List<String> _allTopics = [];

  final List<Map<String, dynamic>> devices = [
    {'id': 3, 'iconPath': 'assets/Scenes_Icons/low.svg', 'label': 'Low'},
    {'id': 1, 'iconPath': 'assets/Scenes_Icons/day.svg', 'label': 'Standard'},
    {'id': 4, 'iconPath': 'assets/Scenes_Icons/bright11.svg', 'label': 'Bright'},
  ];



  @override
  void initState() {
    super.initState();
    _loadScenes().then((_) async {
      await _loadDeviceStates();
      await _loadAllTopics();
    });
  }

  Future<void> _loadAllTopics() async {
    final List<String> predefinedTopics = [
      'arr/center',
      'arr/left',
    ];

    setState(() {
      _allTopics = predefinedTopics;
    });

    debugPrint("📡 Loaded Topics: $_allTopics");
  }

  Future<void> _loadScenes() async {
    _scenes
      ..clear()
      ..addAll(devices.map((d) {
        return {
          'id': d['id'],
          'label': d['label'],
        };
      }).toList());

    setState(() {});
  }

  Future<void> _saveDeviceState(String key, bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("device_state_$key", state);
    _deviceStates[key] = state;
    setState(() {}); // refresh UI
  }

  Future<void> _loadDeviceStates() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var scene in _scenes) {
        final int id = scene['id'];
        final String key = "scene_$id";
        final savedState = prefs.getBool("device_state_$key") ?? false;
        _deviceStates[key] = savedState;
      }
    });
  }

  Future<void> _publishToAllTopics(MQTTService mqttService, String message) async {
    if (!mqttService.isConnected) {
      debugPrint("⚠️ MQTT not connected — cannot publish");
      return;
    }
    final uniqueTopics = _allTopics.toSet();
    if (uniqueTopics.isEmpty) {
      debugPrint("⚠️ No topics found to publish");
      return;
    }
    for (final topic in uniqueTopics) {
      mqttService.publish(topic, message);
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }



  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context, listen: false);
    final allScenes = List<Map<String, dynamic>>.from(_scenes);

    final runningScene = allScenes.firstWhere(
          (scene) => _deviceStates["scene_${scene['id']}"] == true,
      orElse: () => {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Scenes",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            // IconButton(
            //   onPressed: null,
            //   icon: const Icon(Icons.add, color: Colors.white, size: 30),
            //   splashRadius: 15,
            //   tooltip: "Add Scene",
            // ),
          ],
        ),

        const SizedBox(height: 15),

        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },

            child: Container(
              key: ValueKey(runningScene['label'] ?? 'Off'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1D1D),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 55,
                    width: 55,
                    child: SvgPicture.asset(
                      runningScene.isNotEmpty
                          ? devices.firstWhere(
                            (d) => d['label'] == runningScene['label'],
                        orElse: () => {
                          'iconPath': 'assets/Scenes_Icons/inactive.svg',
                        },
                      )['iconPath']
                          : 'assets/Scenes_Icons/inactive.svg',
                    ),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          runningScene.isNotEmpty
                              ? "Currently Running"
                              : "Currently Off",
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          runningScene.isNotEmpty
                              ? runningScene['label']
                              : "Off",
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),


        Container(
          color: Colors.transparent,
          child: allScenes.isEmpty
              ? const Center(
            child: Text(
              "No Scene Available",
              style: TextStyle(color: Colors.white70),
            ),
          )
              : LayoutBuilder(
            builder: (context, constraints) {
              return GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: allScenes.map((scene) {
                  final int id = scene['id'];
                  final String label = scene['label'];
                  final String key = "scene_$id";
                  final bool isOn = _deviceStates[key] ?? false;

                  final device = devices.firstWhere(
                        (d) => d['label'] == label,
                    orElse: () => {
                      'iconPath': 'assets/Scenes_Icons/inactive.svg',
                      'label': label,
                    },
                  );

                  return GestureDetector(
                    onTap: () {
                      showDialog(

                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Color(0xff171717),
                            title: const Text("⚠️ Confirm Device Action",style: TextStyle(color: Colors.white),),
                            content: const Text(
                                "Are you sure you want to change this scene state?",style: TextStyle(color: Colors.white)),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final newState =
                                  !(_deviceStates[key] ?? false);

                                  setState(() {

                                    if (newState) {
                                      for (var other in _scenes) {
                                        final otherKey =
                                            "scene_${other['id']}";
                                        if (otherKey != key &&
                                            (_deviceStates[otherKey] ??
                                                false)) {
                                          _deviceStates[otherKey] = false;
                                          _saveDeviceState(
                                              otherKey, false);
                                        }
                                      }
                                    }

                                    _deviceStates[key] = newState;
                                    _saveDeviceState(key, newState);
                                  });

                                  final message = newState
                                      ? "#*6*$id*1*1*#"
                                      : "#*6*$id*0*1*#";
                                  await _publishToAllTopics(
                                      mqttService, message);
                                },
                                child: const Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1D1D),
                        borderRadius: BorderRadius.circular(16),
                        border: isOn
                            ? Border.all(color: Color(0xff00A1F1), width: 2)
                            : null,
                        boxShadow: isOn
                            ? [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                            : [],
                      ),


                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 33,
                            width: 33,
                            child: SvgPicture.asset(
                              device['iconPath'],
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            label,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

      ],
    );
  }

}


