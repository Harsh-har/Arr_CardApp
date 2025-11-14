import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  late Animation<double> _menuSlideAnimation;
  OverlayEntry? _overlayEntry;
  bool _isMenuVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 3.1416).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _menuSlideAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _toggleMenu() {
    if (_isMenuVisible) {
      _controller.reverse();
      _hideMenu();
    } else {
      _showMenu();
      _controller.forward();
    }
  }

  void _showMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isMenuVisible = true);
  }

  void _hideMenu() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() => _isMenuVisible = false);
    });
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

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: offset.dy + 50,
            right: 4,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.translate(
                  offset: Offset(0, _menuSlideAnimation.value),
                  child: Opacity(opacity: _controller.value, child: child),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildMenuItem(Icons.add, const Color(0xFF26A69A), () {
                            widget.isConnected
                                ? widget.onAdd()
                                : _showConnectionMessage(context);
                          }),
                          // if (widget.hasActiveRoom)
                          //   _buildMenuItem(Icons.power_settings_new, Colors.red, widget.onMasterOff),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, Color bgColor, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      width: 35,
      height: 45,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: () {
          _toggleMenu();
          onPressed();
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove();
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
          icon: SvgPicture.asset(
            'assets/icons/Setting_Icon/Vector.svg',
            width: 25,
            height: 25,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: _toggleMenu,
        ),
      ),
    );
  }
}
