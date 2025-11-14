import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSwaro extends StatelessWidget {
  const AboutSwaro({super.key});

  void _launchWebsite(BuildContext context) async {
    final Uri url = Uri.parse('https://sites.google.com/swaja.com/swaja/home');

    final bool launched = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch the website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: const Text("ABOUT US"),
        backgroundColor: Colors.teal.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Swaja Innovations',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'At Swaja, we build intelligent automation and smart solutions tailored for modern living and industrial needs. Our mission is to bridge the gap between innovation and practical implementation, bringing cutting-edge technology to life.',
              style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const Text(
              'Our Vision',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'To become a global leader in smart systems and automation by delivering reliable, scalable, and user-friendly products.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _launchWebsite(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text(
                "Visit Our Website",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
