import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';
import 'Edit_Name_Page.dart';
import 'Edit_User_Pass_Page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController brokerController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String savedName = "";
  String savedUsername = "";
  String? _nameWarning;
  File? _image;


  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadSavedCredentials();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image');
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _image = File(imagePath);
      });
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedUsername = prefs.getString('mqtt_username') ?? '';
      savedName = prefs.getString('user_name') ?? '';

      // Assign values to controllers
      usernameController.text = savedUsername;
      passwordController.text = prefs.getString('mqtt_password') ?? '';
      nameController.text = savedName;

      // 🔥 New: Load broker + port
      brokerController.text = prefs.getString('mqtt_broker') ?? '';
      portController.text = (prefs.getInt('mqtt_port') ?? 1883).toString();
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Save path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', pickedFile.path);
    }
  }


  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Profile",style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),



              GestureDetector(
                onTap: _pickImage, // Tap avatar to pick
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 5),
              TextButton.icon(
                onPressed: _pickImage, // Tap button to pick
                icon: const Icon(Icons.edit, color: Colors.green),
                label: const Text(
                  "Edit",
                  style: TextStyle(color: Colors.green, fontSize: 15),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Status: ", style: TextStyle(fontSize: 18, color: Colors.white)),
                  Text(
                    mqttService.isConnected ? "Connected " : "Disconnected ",
                    style: TextStyle(fontSize: 19,  fontWeight: FontWeight.bold, color: mqttService.isConnected ? Colors.green : Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name field
              GestureDetector(
                onTap: () async {
                  final updatedName = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditNamePage(),
                    ),
                  );

                  if (updatedName != null && updatedName is String && updatedName.isNotEmpty) {
                    await _loadSavedCredentials();

                    setState(() {
                      nameController.text = updatedName;
                      savedName = updatedName;
                    });
                  }
                },

                child: AbsorbPointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        readOnly: true,
                        decoration: _inputDecoration("Your name"),
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_nameWarning != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            _nameWarning!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditCredentialPage()),
                      );

                      // 🔄 Reload credentials after coming back
                      await _loadSavedCredentials();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Broker
                          Text(
                            "Broker",
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          FutureBuilder<SharedPreferences>(
                            future: SharedPreferences.getInstance(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final prefs = snapshot.data!;
                              final broker = prefs.getString('mqtt_broker') ?? '';
                              return Text(
                                broker.isNotEmpty ? broker : "Not set",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.grey, height: 20),

                          // Port
                          Text(
                            "Port",
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          FutureBuilder<SharedPreferences>(
                            future: SharedPreferences.getInstance(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final prefs = snapshot.data!;
                              final port = prefs.getInt('mqtt_port') ?? 1883;
                              return Text(
                                port.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                          const Divider(color: Colors.grey, height: 20),

                          // Username
                          Text(
                            "Username",
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            usernameController.text.isNotEmpty
                                ? usernameController.text
                                : "Not set",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Divider(color: Colors.grey, height: 20),

                          // Password
                          Text(
                            "Password",
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            passwordController.text.isNotEmpty ? "••••••••" : "Not set",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.grey,
      ), // 👈 Label before focus
      floatingLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ), // 👈 Label when floating
      floatingLabelBehavior: FloatingLabelBehavior.auto, // 👈 this is default, but explicit helps
      filled: false, // 👈 NO background fill
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 3),
      ),
      hintStyle: const TextStyle(color: Colors.tealAccent),
    );
  }

}
