import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Profile_Page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String savedName = '';
  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadDarkModePreference();
    _loadProfileImage();
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

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    setState(() {
      savedName = name;
    });
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? true;
    });
  }

  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: _isDarkMode ? Colors.white : Colors.black),
        title: Text(
          'Settings',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.try_sms_star_outlined),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const QrScanPage()),
          //     );
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.maps_home_work_outlined),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const SwajaMapScreen()),
          //     );
          //   },
          // ),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  ).then((_) {
                    _loadUserProfile();
                    _loadProfileImage();
                    setState(() {});
                  });
                },
                child: _buildHeader(_isDarkMode ? Colors.grey[850] : Colors.grey[200]),
              ),
              const SizedBox(height: 24),

              // Sections
              _buildSectionTitle("Account"),
              _buildSettingsTile(Icons.person, "Edit Profile", onTap: () {}),
              _buildSettingsTile(Icons.lock, "Change Password", onTap: () {}),
              const SizedBox(height: 24),

              _buildSectionTitle("Preferences"),
              SwitchListTile(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  _saveDarkModePreference(value);
                },
                title: Text(
                  "Dark Mode",
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                secondary: Icon(
                  Icons.brightness_6,
                  color: _isDarkMode ? Colors.white70 : Colors.black,
                ),
              ),
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                title: Text(
                  "Enable Notifications",
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                secondary: Icon(
                  Icons.notifications_active,
                  color: _isDarkMode ? Colors.white70 : Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("About"),
              _buildSettingsTile(
                Icons.info_outline,
                "App Version",
                trailing: Text(
                  "1.0.0",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: _isDarkMode ? Colors.white60 : Colors.black,
                  ),
                ),
              ),
              _buildSettingsTile(Icons.privacy_tip_outlined, "Privacy Policy"),
              const SizedBox(height: 16),
            ],
          ),

          // Single overlay for all sections
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              alignment: const Alignment(0, -0.1),
              child: const Text(
                "⚠️ Access Restricted\nThese sections are currently unavailable.\nYou can only access and update your Profile at this time.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color? background) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF050505),
            Color(0xFF1A1A1A),
            Color(0xFF1A1A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey,
            backgroundImage: _image != null ? FileImage(_image!) : null,
            child: _image == null
                ? const Icon(Icons.person, size: 40, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              savedName.isNotEmpty ? savedName : 'Your Name',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: _isDarkMode ? Colors.white70 : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title,
      {VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: _isDarkMode ? Colors.white70 : Colors.black87),
      title: Text(
        title,
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
