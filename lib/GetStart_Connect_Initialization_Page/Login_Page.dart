import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../Main_Screens/Home_Screen.dart';

class LoginCredentialPage extends StatefulWidget {
  const LoginCredentialPage({super.key});

  @override
  _CredentialScreenState createState() => _CredentialScreenState();
}

class _CredentialScreenState extends State<LoginCredentialPage> {
  final TextEditingController brokerController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String? _nameWarning;

  // Validation flags
  bool _isNameValid = true;
  bool _isBrokerValid = true;
  bool _isPortValid = true;
  bool _isUsernameValid = true;
  bool _isPasswordValid = true;

  @override
  void initState() {
    super.initState();

    // Name validation
    nameController.addListener(() {
      final name = nameController.text.trim();
      setState(() {
        _isNameValid = name.isNotEmpty && name.length <= 10;
        _nameWarning = name.length > 10 ? "⚠️ Maximum 10 characters allowed!" : null;
      });
    });
    brokerController.addListener(_validateFields);
    portController.addListener(_validateFields);
    usernameController.addListener(_validateFields);
    passwordController.addListener(_validateFields);

  }

  void _validateFields() {
    final name = nameController.text.trim();
    setState(() {
      _isNameValid = name.isNotEmpty && name.length <= 10;
      _nameWarning = name.length > 10 ? "⚠️ Maximum 10 characters allowed!" : null;
      _isBrokerValid = brokerController.text.trim().isNotEmpty;
      _isPortValid = portController.text.trim().isNotEmpty;
      _isUsernameValid = usernameController.text.trim().isNotEmpty;
      _isPasswordValid = passwordController.text.trim().isNotEmpty;
    });
  }

  Future<void> _saveCredentials() async {
    if (!_isNameValid || !_isBrokerValid || !_isPortValid || !_isUsernameValid || !_isPasswordValid) {
      _showFadeMessage("⚠️ Please fill all fields correctly!");
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('mqtt_broker', brokerController.text.trim());
    await prefs.setInt('mqtt_port', int.tryParse(portController.text.trim()) ?? 1883);
    await prefs.setString('mqtt_username', usernameController.text.trim());
    await prefs.setString('mqtt_password', passwordController.text.trim());
    await prefs.setString('user_name', nameController.text.trim());
    await prefs.setBool('logged_in', true);

    _showFadeMessage("✅ Credentials Saved!");

    final mqttService = Provider.of<MQTTService>(context, listen: false);
    mqttService.connect(
      usernameController.text.trim(),
      passwordController.text.trim(),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen(role: '',)),
      );
    });
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

  InputDecoration _inputDecoration(String label, {bool isValid = true}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      floatingLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey , width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
      ),
      hintStyle: const TextStyle(color: Colors.tealAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool allFieldsValid =
        nameController.text.trim().isNotEmpty &&
            nameController.text.trim().length <= 10 &&
            brokerController.text.trim().isNotEmpty &&
            portController.text.trim().isNotEmpty &&
            usernameController.text.trim().isNotEmpty &&
            passwordController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome to SWAJA",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                  // border: Border.all(color: Colors.white70, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 4,
                      spreadRadius: 3,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Let's Get Started",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextField(
                      controller: nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9 ]")),
                      ],
                      decoration: _inputDecoration("Your name", isValid: _isNameValid),
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
                    const SizedBox(height: 20),

                    // Broker
                    TextField(
                      controller: brokerController,
                      decoration: _inputDecoration("Broker IP (e.g., 192.168.1.200)", isValid: _isBrokerValid),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // Port
                    TextField(
                      controller: portController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Port (e.g., 1883)", isValid: _isPortValid),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // Username
                    TextField(
                      controller: usernameController,
                      decoration: _inputDecoration("Username", isValid: _isUsernameValid),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputDecoration("Password", isValid: _isPasswordValid),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 35),

                    // Buttons
                    if (allFieldsValid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: allFieldsValid ? _saveCredentials : null,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: allFieldsValid ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                                decoration: BoxDecoration(
                                  gradient:  LinearGradient(
                                    colors: [Colors.white, Colors.grey.shade300],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Connect",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Flexible(
                    child: Text(
                      "Please ensure your credentials are entered correctly before connecting.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

      ),
    );
  }
}


