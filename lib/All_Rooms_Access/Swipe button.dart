// import 'package:flutter/material.dart';
//
// class MasterOffSwipeScreen extends StatefulWidget {
//   final VoidCallback onConfirm;
//
//   const MasterOffSwipeScreen({super.key, required this.onConfirm});
//
//   @override
//   _MasterOffSwipeScreenState createState() => _MasterOffSwipeScreenState();
// }
//
// class _MasterOffSwipeScreenState extends State<MasterOffSwipeScreen>
//     with SingleTickerProviderStateMixin {
//   double dragPosition = 0.0;
//   final double buttonSize = 100.0;
//   final double dragThreshold = 200.0;
//
//   late AnimationController _arrowController;
//   late Animation<double> _arrowAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _arrowController =
//     AnimationController(vsync: this, duration: const Duration(seconds: 1))
//       ..repeat();
//     _arrowAnimation = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   void dispose() {
//     _arrowController.dispose();
//     super.dispose();
//   }
//
//   void _onDragUpdate(DragUpdateDetails details) {
//     setState(() {
//       dragPosition -= details.primaryDelta!;
//       if (dragPosition < 0) dragPosition = 0;
//       if (dragPosition > 300 - buttonSize) {
//         dragPosition = 300 - buttonSize;
//       }
//     });
//   }
//
//   void _onDragEnd(DragEndDetails details) {
//     if (dragPosition >= dragThreshold) {
//       widget.onConfirm();
//       Navigator.pop(context);
//     } else {
//       setState(() => dragPosition = 0);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final buttonColor = Color.lerp(
//       Colors.green,
//       Colors.red,
//       dragPosition / (300 - buttonSize),
//     );
//
//     return GestureDetector(
//       onTap: () => Navigator.pop(context),
//       child: Material(
//         color: Colors.black54,
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             const Positioned(
//               top: 100,
//               child: Text(
//                 "Slide Up to MASTER OFF",
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//
//             // Slider area (disable outside tap here)
//             Positioned(
//               bottom: 250,
//               child: GestureDetector(
//                 onTap: () {}, // Block tap so it won't close
//                 child: Stack(
//                   alignment: Alignment.bottomCenter,
//                   children: [
//                     // Pill
//                     Container(
//                       width: 110,
//                       height: 300,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.11),
//                         borderRadius: BorderRadius.circular(55),
//                       ),
//                       child: Stack(
//                         alignment: Alignment.bottomCenter,
//                         children: [
//                           AnimatedBuilder(
//                             animation: _arrowAnimation,
//                             builder: (context, child) {
//                               return Positioned(
//                                 bottom: (_arrowAnimation.value *
//                                     (300 - buttonSize)),
//                                 child: const Icon(Icons.keyboard_arrow_up,
//                                     color: Colors.white70, size: 50),
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Swipe button
//                     Positioned(
//                       bottom: dragPosition,
//                       child: GestureDetector(
//                         onVerticalDragUpdate: _onDragUpdate,
//                         onVerticalDragEnd: _onDragEnd,
//                         child: Container(
//                           width: buttonSize,
//                           height: buttonSize,
//                           decoration: BoxDecoration(
//                             color: buttonColor,
//                             shape: BoxShape.circle,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: buttonColor!.withOpacity(0.6),
//                                 blurRadius: 20,
//                                 spreadRadius: 5,
//                               ),
//                             ],
//                           ),
//                           child: const Center(
//                             child: Icon(Icons.power_settings_new,
//                                 color: Colors.white, size: 50),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
