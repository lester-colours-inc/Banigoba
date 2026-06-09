// Calibrates body proportions before outfit generation and recommendations.
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../makeover/style_selection_page.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({super.key, this.imageBytes, this.imageUrl});

  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  static const _primaryColor = Color(0xFF17008A);
  double _height = 0.68;
  double _waist = 0.48;
  double _shoulders = 0.46;
  bool _isSaving = false;

  bool get _hasSourceImage =>
      widget.imageBytes != null || widget.imageUrl != null;

  Future<void> _confirmMeasurements() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'bodyCalibration': {
            'height': _height,
            'waist': _waist,
            'shoulders': _shoulders,
          },
          'bodyCalibrationUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      if (_hasSourceImage) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => StyleSelectionPage(
              imageBytes: widget.imageBytes,
              imageUrl: widget.imageUrl,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurements saved successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save measurements: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: const Text(
          'My Fashion Style',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Cart',
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
              const Positioned(
                right: 10,
                top: 9,
                child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
              ),
            ],
          ),
          IconButton.filledTonal(
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
            ),
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.black),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyzing Your Measurement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 0.92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildSourceImage(),
              ),
            ),
            const SizedBox(height: 18),
            _MeasurementSlider(
              label: 'Height',
              value: _height,
              onChanged: (value) => setState(() => _height = value),
            ),
            _MeasurementSlider(
              label: 'Waist',
              value: _waist,
              onChanged: (value) => setState(() => _waist = value),
            ),
            _MeasurementSlider(
              label: 'Shoulders',
              value: _shoulders,
              onChanged: (value) => setState(() => _shoulders = value),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: 190,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirmMeasurements,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Measurement',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceImage() {
    if (widget.imageBytes != null) {
      return Image.memory(widget.imageBytes!, fit: BoxFit.contain);
    }
    if (widget.imageUrl != null) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return const ColoredBox(
      color: Color(0xFF9A84F5),
      child: Center(
        child: Icon(Icons.person_outline, size: 140, color: Colors.white70),
      ),
    );
  }
}

class _MeasurementSlider extends StatelessWidget {
  const _MeasurementSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

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
              activeTrackColor: _MeasurementPageState._primaryColor,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: _MeasurementPageState._primaryColor,
              trackHeight: 4,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}
