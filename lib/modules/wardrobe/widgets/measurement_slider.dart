// One labelled slider on the measurement page.
import 'package:flutter/material.dart';

class MeasurementSlider extends StatelessWidget {
  const MeasurementSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  static const Color primaryColor = Color(0xFF17008A);

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryColor,
              inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
              thumbColor: primaryColor,
              trackHeight: 4,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
