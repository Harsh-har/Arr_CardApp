import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'MQTT_STRUCTURE/MQTT_SETUP.dart';
import 'Main_Screens/Card_Map_Base_Screen_Widget/Provider_Loader.dart';
import 'Main_Screens/Scenes/Active_Provider.dart';
import 'Main_Screens/splash.dart';
import 'Temprature_Box/CardBaseTempratrure/Weather_Provider.dart';
import 'Temprature_Box/Weather_Provider.dart';

/// ✅ Define navigatorKey globally
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MQTTService()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => CardBaseWeatherProvider()),
        ChangeNotifierProvider(create: (_) => ActiveRoomProvider()),
        ChangeNotifierProvider(create: (context) => ProviderLoader()),
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}
