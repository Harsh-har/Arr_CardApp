import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../GetStart_Connect_Initialization_Page/Get_Started_Page.dart';
import 'Home_Screen.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 400), _checkAndNavigate);
  }

  Future<void> _checkAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();

    bool seenGetStarted = prefs.getBool('seen_get_started') ?? false;
    bool loggedIn = prefs.getBool('logged_in') ?? false;

    Widget nextPage;
    if (!seenGetStarted) {
      nextPage = const GetStartedPage();
    } else {
      nextPage = loggedIn ? const ChatScreen(role: '',) : const ChatScreen(role: '',);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => nextPage,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: SvgPicture.asset(
            'assets/Logo/Swaja_Logo.svg',
            width: 200,
            height: 100,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
