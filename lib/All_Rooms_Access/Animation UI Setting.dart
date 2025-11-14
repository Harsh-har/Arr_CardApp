import 'package:flutter/material.dart';

class RotatingSettingsMenu extends StatefulWidget {
  final bool isConnected;
  final VoidCallback onAdd;

  const RotatingSettingsMenu({
    super.key,
    required this.isConnected,
    required this.onAdd,
  });

  @override
  _RotatingSettingsMenuState createState() => _RotatingSettingsMenuState();
}

class _RotatingSettingsMenuState extends State<RotatingSettingsMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 3.1416)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _showConnectionMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ First connect to the broker!"),
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 800),
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
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (_, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: IconButton(
          icon: const Icon(
            Icons.add,
            size: 28,
            color: Colors.white,
          ),
          onPressed: () {
            if (widget.isConnected) {
              widget.onAdd(); // Direct add
            } else {
              _showConnectionMessage(context);
            }
          },
        ),
      ),
    );
  }
}
