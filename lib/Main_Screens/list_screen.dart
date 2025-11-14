import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_control/Control_Box/sensor.dart';

class ListScreen extends StatelessWidget {
  final Function(String) onItemSelected;

  const ListScreen({super.key, required this.onItemSelected});

  static const Map<String, String> svgIconMapping = {
    'Dimmer': 'assets/icons/Card_Icons/ListDimmer.svg',
    'SubNode Supply': 'assets/icons/Card_Icons/ListSubnode.svg',
    'Strip Light': 'assets/icons/Card_Icons/ListStrip.svg',
    'Fan': 'assets/icons/Card_Icons/ListFan.svg',
    'AC': 'assets/icons/Card_Icons/ListAC.svg',
    'Curtains': 'assets/icons/Card_Icons/ListBlinds.svg',
    'Exhaust': 'assets/icons/Card_Icons/ListExhaust.svg',
    'Relay': 'assets/icons/Card_Icons/ListRelay.svg',
    'Sensors (Occupancy)': 'assets/icons/Card_Icons/ListFan.svg',
    'Individual Subnode': 'assets/icons/Card_Icons/ListSubnode.svg',
    'Individual Strip': 'assets/icons/Card_Icons/ListStrip.svg',
    'Group Fan': 'assets/icons/Card_Icons/ListGroupFan.svg',
    'Group Strip': 'assets/icons/Card_Icons/ListGroupStrip.svg',
    'Group Light': 'assets/icons/Card_Icons/ListGroupLight.svg',
    'Group Single Light': 'assets/icons/Card_Icons/ListGroupSingleLight.svg',
    'Sensor': 'assets/icons/Card_Icons/ListSensor.svg',
    'RGB Strip': 'assets/icons/Card_Icons/ListStrip.svg',
    'SMPS' : 'assets/icons/Card_Icons/ListStrip.svg',

  };

  static String getSvgForOption(String option) {
    return svgIconMapping[option] ?? 'assets/icons/Card_Icons/Null.svg';
  }

  static bool isIndividualDevice(String option) {
    return option == 'Individual Subnode' || option == 'Individual Strip';
  }

  final List<String> _options = const [
    'SubNode Supply',
    'Strip Light',
    'Individual Subnode',
    'Individual Strip',
    'Fan',
    'Relay',
    'SMPS',
    'AC',
    'Exhaust',
    'Dimmer',
    'RGB Strip',
    'Curtains',
    'Group Fan',
    'Group Strip',
    'Group Light',
    'Group Single Light',
    'Sensor',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ListView(
        shrinkWrap: true,
        children: _options.map((option) {
          return GestureDetector(
            onTap: () => onItemSelected(option),
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 38,
                    child: Center(
                      child: option == 'RGB Strip'
                          ? ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.red, Colors.green, Colors.blue],
                          stops: [0.25, 0.5, 0.7],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        child: SvgPicture.asset(
                          getSvgForOption(option),
                          width: 30,
                          height: 30,
                          color: Colors.white,
                        ),
                      )
                          : SvgPicture.asset(
                        getSvgForOption(option),
                        width: 30,
                        height: 30,
                        color: isIndividualDevice(option) ? Colors.orange[900] : null,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
