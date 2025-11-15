import 'package:flutter/material.dart';

class TabSelector extends StatelessWidget {
  final bool showDevices;
  final Function(bool) onTabChanged;

  const TabSelector({
    super.key,
    required this.showDevices,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Devices Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF121212),
              minimumSize: const Size(125, 40),
              side: showDevices
                  ? const BorderSide(color: Colors.blueAccent, width: 1.7) // Thicker border
                  : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // More curves (adjust radius as needed)
              ),
            ),
            onPressed: () {
              if (!showDevices) {
                onTabChanged(true); // true = Devices
              }
            },
            child: Text(
              "Devices",
              style: TextStyle(
                color: showDevices ? Colors.white : Colors.grey,
              ),
            ),
          ),

          const SizedBox(width: 5),

          // Spaces Button
          // ElevatedButton(
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Color(0xFF121212),
          //     minimumSize: const Size(125, 40),
          //     side: !showDevices
          //         ? const BorderSide(color: Colors.blueAccent, width: 1.7)
          //         : BorderSide.none,
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(16),
          //     ),
          //   ),
          //   onPressed: () {
          //     if (showDevices) {
          //       onTabChanged(false); // false = Spaces
          //     }
          //   },
          //   child: Text(
          //     "Spaces",
          //     style: TextStyle(
          //       color: !showDevices ? Colors.white : Colors.grey,
          //     ),
          //   ),
          // ),

          const SizedBox(width: 5),
        ],
      )

    );
  }
}
