// A tappable card on Business mode's home.
import 'package:flutter/material.dart';

class ProviderNavCard extends StatelessWidget {
  const ProviderNavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  static const Color primary = Color(0xFF0D0140);

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Replaces the arrow, e.g. a count badge.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
