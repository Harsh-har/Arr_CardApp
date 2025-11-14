import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditCredentialPage extends StatefulWidget {
  const EditCredentialPage({super.key});

  @override
  State<EditCredentialPage> createState() => _EditCredentialPageState();
}

class _EditCredentialPageState extends State<EditCredentialPage> {
  final TextEditingController brokerController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      brokerController.text = prefs.getString('mqtt_broker') ?? '';
      portController.text = (prefs.getInt('mqtt_port') ?? 1883).toString();
      usernameController.text = prefs.getString('mqtt_username') ?? '';
      passwordController.text = prefs.getString('mqtt_password') ?? '';
    });
  }

  Future<void> _saveCredentials() async {
    if (brokerController.text.trim().isEmpty ||
        portController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showFadeMessage("⚠️ All fields are required!");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_broker', brokerController.text.trim());
    await prefs.setInt('mqtt_port', int.tryParse(portController.text.trim()) ?? 1883);
    await prefs.setString('mqtt_username', usernameController.text.trim());
    await prefs.setString('mqtt_password', passwordController.text.trim());

    _showFadeMessage("✅ Credentials Saved!");
    Navigator.pop(context, true); // return to previous screen
  }

  void _showFadeMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Edit Credentials", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Broker IP
              TextField(
                controller: brokerController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                ],
                decoration: _inputDecoration("Broker IP (e.g., 192.168.1.200)"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),

              // Port
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Port (e.g., 1883)"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),

              // Username
              TextField(
                controller: usernameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9_]")),
                ],
                decoration: _inputDecoration("Username"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: _inputDecoration("Password"),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),

              const Text(
                "These credentials are required to authenticate with the MQTT broker over Wi-Fi, enabling a secure connection between your devices.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.start,
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(right: 25, left: 25, bottom: 50),
        child: SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _saveCredentials,
            child: const Text(
              "Save",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      floatingLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: false,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade800, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green.shade500, width: 2),
      ),
      hintStyle: const TextStyle(color: Colors.white54),
    );
  }
}
