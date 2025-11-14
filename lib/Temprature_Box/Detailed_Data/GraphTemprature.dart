import 'package:flutter/material.dart';

class TempGraph extends StatelessWidget {
  final List<double> dataPoints;
  final String parameterType;

  const TempGraph({
    super.key,
    required this.dataPoints,
    required this.parameterType,
  });

  @override
  Widget build(BuildContext context) {
    final double currentValue =
    dataPoints.isNotEmpty ? dataPoints.last.clamp(0, 100) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1034),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1034),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          parameterType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 20),
          child: Row(
            children: [
              // Left percentage scale
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(11, (i) {
                  final percent = (100 - (i * 10));
                  return Text(
                    "$percent%",
                    style: TextStyle(
                      color: percent == currentValue.toInt()
                          ? Colors.cyanAccent
                          : Colors.white70,
                      fontSize: percent == currentValue.toInt() ? 16 : 12,
                      fontWeight: percent == currentValue.toInt()
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }),
              ),

              // Middle gauge line
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gradient line
                    Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.pinkAccent, Colors.cyanAccent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),


                    Positioned(
                      top: (1 - currentValue / 100) *
                          (MediaQuery.of(context).size.height - 220),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.cyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("CURRENT TEMPERATURE",
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    Text(
                      "${currentValue.toStringAsFixed(0)}%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
