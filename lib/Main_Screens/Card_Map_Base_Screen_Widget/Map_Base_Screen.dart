import 'package:flutter/material.dart';

class OfficeMap extends StatefulWidget {
  const OfficeMap({super.key});

  @override
  State<OfficeMap> createState() => _OfficeMapState();
}

class _OfficeMapState extends State<OfficeMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "This Map feature is not available yet.\nPlease get back to Card view.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "🚧",
                style: TextStyle(
                  fontSize: 120, // large emoji
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
