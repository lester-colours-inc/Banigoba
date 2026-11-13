// Under the Style idol field: find one of the idol's looks on the web, and
// show the chosen one with a way to change or remove it.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/makeover/widgets/makeover_controls.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

/// The idol's chosen web look and how to change it; owned by the page.
@immutable
class IdolLookState {
  const IdolLookState({
    this.imageUrl = '',
    required this.onFindOnWeb,
    required this.onClear,
  });

  final String imageUrl;
  final VoidCallback onFindOnWeb;
  final VoidCallback onClear;
}

class IdolWebLook extends StatelessWidget {
  const IdolWebLook({
    super.key,
    required this.state,
    required this.idolName,
    required this.enabled,
  });

  final IdolLookState state;
  final String idolName;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = idolName.trim();

    if (state.imageUrl.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: MakeoverPill(
          key: const ValueKey('look_idol_web'),
          icon: Icons.travel_explore,
          label: name.isEmpty
              ? 'Find looks on the web'
              : "Find $name's looks on the web",
          selected: false,
          onTap: enabled ? state.onFindOnWeb : null,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            key: const ValueKey('look_idol_web_preview'),
            width: 64,
            height: 86,
            child: AppNetworkImage(
              state.imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              fallback: ColoredBox(
                color: colors.surfaceContainerHigh,
                child: Icon(Icons.broken_image_outlined, color: colors.outline),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Your idol look' : "$name's look",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "We'll copy this outfit onto you, never the person.",
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    key: const ValueKey('look_idol_web_change'),
                    onPressed: enabled ? state.onFindOnWeb : null,
                    icon: const Icon(Icons.travel_explore, size: 18),
                    label: const Text('Change'),
                  ),
                  TextButton.icon(
                    key: const ValueKey('look_idol_web_remove'),
                    onPressed: enabled ? state.onClear : null,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
