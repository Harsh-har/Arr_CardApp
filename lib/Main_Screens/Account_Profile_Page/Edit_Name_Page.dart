import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/global_controller.dart';

class EditNamePage extends StatefulWidget {
  const EditNamePage({super.key});

  @override
  State<EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends State<EditNamePage> {
  final TextEditingController nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  String savedName = "";
  String? _nameWarning;
  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();
    _loadSavedName();

    // Auto focus when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });

    // Validation for max 10 characters
    nameController.addListener(() {
      final name = nameController.text;
      if (name.length > 10) {
        setState(() {
          _nameWarning = "⚠️ Maximum 10 characters allowed!";
          _isNameValid = false;
        });
      } else {
        setState(() {
          _nameWarning = null;
          _isNameValid = true;
        });
      }
    });
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedName = prefs.getString('user_name') ?? '';
      nameController.text = savedName;
    });
  }

  Future<void> _saveName() async {
    if (nameController.text.trim().isEmpty) {
      _showFadeMessage("⚠️ Name is required!");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String trimmedName = nameController.text.trim();
    await prefs.setString('user_name', trimmedName);

    usernameNotifier.value = trimmedName;

    setState(() {
      savedName = trimmedName;
    });

    // Return the new name to ProfilePage
    Navigator.pop(context, trimmedName);
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
        title: const Text("Edit Name", style: TextStyle(color: Colors.white)),
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
              // Name field
              TextField(
                controller: nameController,
                focusNode: _nameFocusNode,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9 ]")),
                ],
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
              const SizedBox(height: 10),

              // 👇 Info text under the field
              const Text(
                "Your name will appear on the home screen along with a warm greeting.",
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
            onPressed: _isNameValid ? _saveName : null,
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

      // Remove default borders
      border: InputBorder.none,
      enabledBorder: InputBorder.none,

      // Show only when focused
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green.shade500, width: 2),
      ),

      hintStyle: const TextStyle(color: Colors.white),
    );
  }
}
