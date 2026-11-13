// A small round swatch for a catalogue colour name ("navy", "olive"...).
// Unknown names fall back to a neutral ring so the chip still reads.
import 'package:flutter/material.dart';

const Map<String, Color> _swatches = {
  'black': Color(0xFF111111),
  'white': Color(0xFFFFFFFF),
  'grey': Color(0xFF9E9E9E),
  'gray': Color(0xFF9E9E9E),
  'charcoal': Color(0xFF36454F),
  'navy': Color(0xFF1F2A55),
  'blue': Color(0xFF2F6FD6),
  'light blue': Color(0xFF9CC7F0),
  'denim': Color(0xFF4A6A9B),
  'teal': Color(0xFF138A8A),
  'green': Color(0xFF3B8F4A),
  'olive': Color(0xFF7A7A3A),
  'khaki': Color(0xFFC3B091),
  'beige': Color(0xFFE6D5B8),
  'cream': Color(0xFFF5EEDC),
  'ivory': Color(0xFFFFFDF0),
  'tan': Color(0xFFC8A27A),
  'camel': Color(0xFFC19A6B),
  'brown': Color(0xFF7B4B2A),
  'red': Color(0xFFD23B3B),
  'maroon': Color(0xFF7A1F2B),
  'burgundy': Color(0xFF7A1F3D),
  'pink': Color(0xFFF2A2C0),
  'purple': Color(0xFF7E57C2),
  'lavender': Color(0xFFC9B8E8),
  'orange': Color(0xFFF08A24),
  'yellow': Color(0xFFF2CF3B),
  'mustard': Color(0xFFD6A62C),
  'gold': Color(0xFFD4AF37),
  'silver': Color(0xFFC0C0C0),
};

/// Colour for a catalogue colour name, or null when unknown.
Color? swatchColour(String name) => _swatches[name.trim().toLowerCase()];

class ColourSwatch extends StatelessWidget {
  const ColourSwatch({super.key, required this.name, this.size = 16});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colour = swatchColour(name);
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colour,
        gradient: colour == null
            ? const SweepGradient(
                colors: [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
              )
            : null,
        border: Border.all(color: outline),
      ),
    );
  }
}
