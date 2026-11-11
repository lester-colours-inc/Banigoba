// UI-04: the single brief. Clothing and hair render as visually equal cards;
// neither is the primary domain.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/modules/makeover/controllers/create_makeover_controller.dart';
import 'package:banigoba/modules/makeover/widgets/create_makeover_parts.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class CreateMakeoverBrief extends StatelessWidget {
  const CreateMakeoverBrief({super.key, required this.controller});

  final CreateMakeoverController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Where are you going, and how do you want to feel?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.occasion,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Occasion',
            hintText: 'Wedding, work, dinner, a normal Tuesday',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.feeling,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'How you want to feel (optional)',
            hintText: 'Relaxed, sharp, celebratory',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        const MakeoverSectionHeader(
          title: 'Clothing and hair',
          subtitle:
              'Choose either or both. Anything you leave empty stays exactly as '
              'it is in your photo.',
        ),
        const SizedBox(height: 12),
        _ClothingCard(controller: controller),
        const SizedBox(height: 12),
        _HairCard(controller: controller),
        const SizedBox(height: 24),
        const MakeoverSectionHeader(title: 'Your photo'),
        const SizedBox(height: 12),
        _PhotoSection(controller: controller),
        const SizedBox(height: 24),
        const MakeoverSectionHeader(
          title: 'Preferences',
          subtitle: 'These constrain what the styling may suggest.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.modesty,
          decoration: const InputDecoration(
            labelText: 'Coverage or modesty preference (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.exclusions,
          decoration: const InputDecoration(
            labelText: 'Anything to avoid (optional)',
            hintText: 'Comma separated',
            border: OutlineInputBorder(),
          ),
        ),
        Obx(
          () => controller.error.value.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: MakeoverErrorBanner(controller.error.value),
                ),
        ),
        const SizedBox(height: 24),
        _StartButton(controller: controller),
        const SizedBox(height: 8),
        Text(
          'Your photo and results stay private until you choose to share them.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.controller});

  final CreateMakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.typing.value; // follow the occasion and hair text
      return FilledButton.icon(
        onPressed: controller.canStart ? controller.start : null,
        icon: controller.isBusy.value
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(controller.startButtonLabel),
      );
    });
  }
}

/// Equal-weight card for a transformation domain.
class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.child,
  });

  final IconData icon;
  final String title;
  final bool isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colors.primary : colors.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ClothingCard extends StatelessWidget {
  const _ClothingCard({required this.controller});

  final CreateMakeoverController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final names = controller.garments.value
          .map((garment) => (garment['name'] ?? 'Item').toString())
          .toList();
      final busy = controller.isBusy.value;
      return _DomainCard(
        icon: Icons.checkroom_outlined,
        title: 'Clothing',
        isActive: names.isNotEmpty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (names.isEmpty)
              Text(
                'No items chosen. Your clothing will not be changed.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: names
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : controller.chooseGarments,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(names.isEmpty ? 'Choose items' : 'Change items'),
                ),
                if (names.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: busy ? null : controller.clearGarments,
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _HairCard extends StatelessWidget {
  const _HairCard({required this.controller});

  final CreateMakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.typing.value; // follow the hair text
      return _DomainCard(
        icon: Icons.content_cut_outlined,
        title: 'Hair',
        isActive: controller.hair.text.trim().isNotEmpty,
        child: TextField(
          controller: controller.hair,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Hair goal',
            hintText: 'Shoulder-length braids, faded cut, natural curls',
            border: OutlineInputBorder(),
            helperText: 'Leave empty to keep your hair as it is',
          ),
        ),
      );
    });
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.controller});

  final CreateMakeoverController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      if (controller.isLoadingSource.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final url = controller.sourceImageUrl.value;
      final busy = controller.isBusy.value;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: 92,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: url.isEmpty
                ? Icon(Icons.person_outline, color: colors.onSurfaceVariant)
                : AppNetworkImage(
                    url,
                    fit: BoxFit.cover,
                    fallback: const Icon(Icons.broken_image_outlined),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => controller.pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Take a photo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => controller.pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Choose from gallery'),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
