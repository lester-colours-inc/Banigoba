// Pieces of the style selection page: the photo, the context chips, the
// action buttons and the "coming soon" section tiles.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/style_selection_controller.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

const Color styleSelectionPrimary = Color(0xFF0D0140);

class StyleHeroCard extends StatelessWidget {
  const StyleHeroCard({super.key, required this.controller});

  final StyleSelectionController controller;

  @override
  Widget build(BuildContext context) {
    final bytes = controller.imageBytes;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  bytes != null
                      ? Image.memory(
                          bytes,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        )
                      : AppNetworkImage(
                          controller.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          fallback: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: ElevatedButton.icon(
                      onPressed: controller.openTryOn,
                      icon: const Icon(Icons.checkroom, size: 18),
                      label: const Text('Try On'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: styleSelectionPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class StyleInfoRow extends StatelessWidget {
  const StyleInfoRow({super.key, required this.controller});

  final StyleSelectionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            flex: 3,
            child: _InfoChip(
              icon: Icons.cloud_outlined,
              label: controller.weatherLabel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _InfoChip(
              icon: Icons.calendar_today_outlined,
              label: controller.eventLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: styleSelectionPrimary, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class StyleActionButtons extends StatelessWidget {
  const StyleActionButtons({super.key, required this.controller});

  final StyleSelectionController controller;

  @override
  Widget build(BuildContext context) {
    final actions = <String, VoidCallback>{
      'Quick Wear': controller.openQuickWear,
      'Customize': () {},
      'Try On': controller.openTryOn,
      'Find Shops': controller.openShops,
    };
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final entry in actions.entries)
          SizedBox(
            width: (MediaQuery.of(context).size.width - 68) / 2,
            child: ElevatedButton(
              onPressed: entry.value,
              style: ElevatedButton.styleFrom(
                backgroundColor: styleSelectionPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                entry.key,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StyleSectionTile extends StatelessWidget {
  const StyleSectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDED6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: styleSelectionPrimary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
