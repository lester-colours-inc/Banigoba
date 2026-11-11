// A number field for one body measurement, with its unit and range check.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:banigoba/modules/profile_details/models/body_profile.dart';

class MeasurementField extends StatelessWidget {
  const MeasurementField({
    super.key,
    required this.measurement,
    required this.controller,
    this.onChanged,
    this.enabled = true,
  });

  final BodyMeasurement measurement;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('measurement_${measurement.key}'),
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => measurement.validate(value ?? ''),
      decoration: InputDecoration(
        labelText: measurement.label,
        suffixText: measurement.unit,
        errorMaxLines: 2,
      ),
    );
  }
}
