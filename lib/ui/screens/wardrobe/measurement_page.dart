// Calibrates body proportions before outfit generation and recommendations.
import 'dart:typed_data';

import '../../../core/supabase/app_auth.dart';
import '../../../core/supabase/supabase_config.dart';
import 'package:flutter/material.dart';

import '../makeover/style_selection_page.dart';
import '../../widgets/app_network_image.dart';

class MeasurementPage extends StatefulWidget {
  const MeasurementPage({
    super.key,
    this.imageBytes,
    this.imageUrl,
    this.plannedDate,
    this.eventId,
    this.eventName,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;

  @override
  State<MeasurementPage> createState() => _MeasurementPageState();
}

class _MeasurementPageState extends State<MeasurementPage> {
  static final Color _primaryColor = Color(0xFF17008A);
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
      final user = AppAuth.instance.currentUser;
      if (user != null) {
        await supabase.from('user_documents').upsert({
          'user_id': user.uid,
          'kind': 'bodyCalibration',
          'id': 'latest',
          'data': {'height': _height, 'waist': _waist, 'shoulders': _shoulders},
        });
      }

      if (!mounted) return;
      if (_hasSourceImage) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => StyleSelectionPage(
              imageBytes: widget.imageBytes,
              imageUrl: widget.imageUrl,
              plannedDate: widget.plannedDate,
              eventId: widget.eventId,
              eventName: widget.eventName,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Measurements saved successfully.')),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.chevron_left_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyzing Your Measurement',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 0.92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildSourceImage(),
              ),
            ),
            SizedBox(height: 18),
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
            SizedBox(height: 14),
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
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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
      return AppNetworkImage(
        widget.imageUrl!,
        fit: BoxFit.contain,
        fallback: _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return ColoredBox(
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _MeasurementPageState._primaryColor,
              inactiveTrackColor: Theme.of(context).colorScheme.outlineVariant,
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
