// Colours shared by the profile screen's widgets.
import 'package:flutter/material.dart';

const Color profilePrimaryColor = Color(0xFF0D0140);
const Color profileAccent = Color(0xFFF2A93B);

/// Text and icon colour that reads on the pale banner in both themes.
Color profileInk(ColorScheme colors) => colors.brightness == Brightness.dark
    ? colors.onSurface
    : profilePrimaryColor;
