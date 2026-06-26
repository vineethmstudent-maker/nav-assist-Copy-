import 'package:flutter/material.dart';

class SensorBar extends StatelessWidget {
  final String label;
  final double distance;
  final double maxDistance;

  const SensorBar({
    super.key,
    required this.label,
    required this.distance,
    this.maxDistance = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final value = (1.0 - (distance / maxDistance)).clamp(0.0, 1.0);
    
    Color barColor;
    if (distance > 150) {
      barColor = Colors.green;
    } else if (distance >= 80) {
      barColor = Colors.amber;
    } else {
      barColor = Colors.red;
    }

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: value,
            color: barColor,
            backgroundColor: Colors.grey.shade700,
            minHeight: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${distance.round()}cm',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
