import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login_Page.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  Future<void> _continue(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_get_started', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginCredentialPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,


      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Swaja Connect",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          FeatureTile(
                            title: "All-in-One Device Control",
                            description:
                            "Control all your SWARO devices from a single app – turn devices ON/OFF effortlessly.",
                          ),
                          FeatureTile(
                            title: "Real-Time Monitoring",
                            description:
                            "See the live status of each device, including whether it’s active and its brightness levels.",
                          ),
                          FeatureTile(
                            title: "Scenes & Automation",
                            description:
                            "Trigger predefined “Scenes” to automate multiple devices at once for convenience.",
                          ),
                          FeatureTile(
                            title: "Adjust Settings on the Fly",
                            description:
                            "Customize brightness and other parameters for each device in real time.",
                          ),
                          FeatureTile(
                            title: "Room-Based Organization",
                            description:
                            "Group devices by rooms to manage them efficiently and intuitively.",
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 🔹 Bottom Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 20, bottom: 40, right: 20 ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _continue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "© 2021 Swaja Robotics PVT. LTD.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


class FeatureTile extends StatelessWidget {
  final String title;
  final String description;

  const FeatureTile({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• $title",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 19,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(
              description,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black54,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
