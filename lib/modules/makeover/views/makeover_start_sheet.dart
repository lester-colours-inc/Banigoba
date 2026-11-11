// The first question when starting a makeover: hair, or the outfit and the
// rest? People think about their hair and face every morning more than
// their full outfit, so hair gets its own clear door (October 2026 review,
// M-1: one large button that then asks).
import 'package:flutter/material.dart';

import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/makeover/views/makeover_page.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_controls.dart';

enum MakeoverStart { hairstyle, outfit }

/// Asks which kind of makeover, then opens it. Does nothing if dismissed.
Future<void> startMakeover(BuildContext context) async {
  final navigator = Navigator.of(context);
  final choice = await showModalBottomSheet<MakeoverStart>(
    context: context,
    showDragHandle: true,
    builder: (_) => const MakeoverStartSheet(),
  );
  if (choice == null) return;
  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => MakeoverPage(
        // Hair is decided here; for the outfit the user picks exactly what
        // should change on the next screen.
        initialScope: choice == MakeoverStart.hairstyle ? LookScope.hair : null,
      ),
    ),
  );
}

class MakeoverStartSheet extends StatelessWidget {
  const MakeoverStartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What would you like to change?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _StartOption(
              key: const ValueKey('makeover_start_hairstyle'),
              icon: Icons.face_retouching_natural,
              title: 'Hairstyle',
              subtitle: 'Try a new hairstyle on your own photo',
              onTap: () => Navigator.pop(context, MakeoverStart.hairstyle),
            ),
            const SizedBox(height: 12),
            _StartOption(
              key: const ValueKey('makeover_start_outfit'),
              icon: Icons.checkroom,
              title: 'Outfit & more',
              subtitle: 'Clothes, shoes, accessories or a full look',
              onTap: () => Navigator.pop(context, MakeoverStart.outfit),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartOption extends StatelessWidget {
  const _StartOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kMakeoverNavy,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
