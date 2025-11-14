import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';

class ShowSubscribedDataScreen extends StatefulWidget {
  const ShowSubscribedDataScreen({Key? key}) : super(key: key);

  @override
  _ShowSubscribedDataScreenState createState() => _ShowSubscribedDataScreenState();
}

class _ShowSubscribedDataScreenState extends State<ShowSubscribedDataScreen> {
  late MQTTService _mqttService;
  String? _selectedTopic; // ✅ Holds the selected topic

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mqttService = Provider.of<MQTTService>(context);

    // ✅ Default to the first subscribed topic, if available
    if (_mqttService.subscribedTopics.isNotEmpty) {
      _selectedTopic ??= _mqttService.subscribedTopics.first;
    }

    // ✅ Listen for new messages
    _mqttService.addListener(_updateMessages);
  }

  /// **Update the UI when new messages arrive**
  void _updateMessages() {
    if (!mounted) return; // ✅ Prevent calling setState() after dispose
    setState(() {});
  }

  /// **Remove listener when widget is disposed**
  @override
  void dispose() {
    _mqttService.removeListener(_updateMessages); // ✅ Correct way to remove a listener
    super.dispose();
  }

  /// **Clear all messages for the selected topic**
  Future<void> _clearMessages() async {
    if (_selectedTopic != null) {
      _mqttService.clearMessagesForTopic(_selectedTopic!);
      setState(() {});

      // ✅ Remove messages from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedTopic!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(6),

            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 25),
          ),
        ),

        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedTopic,
            dropdownColor: Colors.black,
            items: _mqttService.subscribedTopics.map((topic) {
              return DropdownMenuItem(
                value: topic,
                child: Text(
                  topic,
                  style: const TextStyle(fontSize: 19, color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (newTopic) {
              setState(() {
                _selectedTopic = newTopic;
              });
            },
            iconEnabledColor: Colors.white,
          ),
        ),
      ),


      body: Consumer<MQTTService>(
        builder: (context, mqttService, child) {
          List<String> messages = mqttService.getMessagesForTopic(_selectedTopic ?? '');

          return Column(
            children: [
              Expanded(
                child: _selectedTopic == null || _selectedTopic!.isEmpty
                    ? const Center(
                  child: Text(
                    "No topic selected.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
                :ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    Color bubbleColor = Colors.green[200]!; // Default color

                    // Extract opcode from format: #*opcode*data*data**#
                    final RegExp regex = RegExp(r'#\*(\d+)\*');
                    final match = regex.firstMatch(message);
                    final opcode = match != null ? int.tryParse(match.group(1) ?? '') : null;

                    if (opcode == 102) {
                      bubbleColor = Colors.orange[400]!;
                    } else if (opcode == 104) {
                      bubbleColor = Colors.yellow[700]!;
                    }else if (opcode == 117) {
                      bubbleColor = Colors.red[700]!;
                    }else if (opcode == 122) {
                      bubbleColor = Colors.green[700]!;
                    }else if (opcode == 123) {
                      bubbleColor = Colors.blue[600]!;
                    }

                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                )




              ),
              if (messages.isNotEmpty) // ✅ Button appears only if messages exist
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Clear All Messages"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _clearMessages,
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