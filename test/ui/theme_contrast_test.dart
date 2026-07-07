// Guards basic theme accessibility by checking important foreground/background
// pairs against WCAG AA contrast.
import 'package:banigoba/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('${brightness.name} theme meets WCAG AA contrast', () {
      final colors = MyApp.buildTheme(brightness).colorScheme;

      _expectContrast(colors.onSurface, colors.surface, 4.5);
      _expectContrast(colors.onSurfaceVariant, colors.surface, 4.5);
      _expectContrast(colors.onPrimary, colors.primary, 4.5);
      _expectContrast(colors.onPrimaryContainer, colors.primaryContainer, 4.5);
      _expectContrast(colors.onInverseSurface, colors.inverseSurface, 4.5);
    });
  }

  test('contrast helper identifies valid and invalid color pairs', () {
    expect(
      _contrastRatio(Colors.black, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(_contrastRatio(Colors.black, Colors.black), lessThan(4.5));
  });
}

void _expectContrast(Color foreground, Color background, double minimum) {
  // WCAG contrast ratio is calculated from relative luminance.
  final ratio = _contrastRatio(foreground, background);

  expect(
    ratio,
    greaterThanOrEqualTo(minimum),
    reason:
        'Contrast ratio ${ratio.toStringAsFixed(2)} is below '
        '${minimum.toStringAsFixed(1)}:1.',
  );
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background
      : foreground;
  final ratio =
      (lighter.computeLuminance() + 0.05) / (darker.computeLuminance() + 0.05);

  return ratio;
}
