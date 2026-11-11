// UI-07 compare and UI-08 refine: the original beside each alternative, why it
// works, and refining one domain while keeping the other.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/create_makeover_controller.dart';
import 'package:banigoba/modules/makeover/models/makeover_job.dart';
import 'package:banigoba/modules/makeover/widgets/create_makeover_parts.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class CreateMakeoverCompare extends StatelessWidget {
  const CreateMakeoverCompare({super.key, required this.controller});

  final CreateMakeoverController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final job = controller.job.value;
      if (job == null || job.alternatives.isEmpty) {
        return const SizedBox.shrink();
      }
      final busy = controller.isBusy.value;
      final error = controller.error.value;
      final selected =
          job.alternatives[controller.selectedAlternative.value.clamp(
            0,
            job.alternatives.length - 1,
          )];

      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Original is always present and always labelled.
          Text(
            'Compare',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _ComparePanel(
                  label: 'Original',
                  imageUrl: job.sourceImageUrl,
                  isSelected: false,
                  onTap: null,
                ),
                for (final alternative in job.alternatives)
                  _ComparePanel(
                    label: alternative.label,
                    imageUrl: alternative.imageUrl,
                    isSelected: alternative.index == selected.index,
                    onTap: () =>
                        controller.selectAlternative(alternative.index),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FocusSelector(controller: controller, job: job),
          const SizedBox(height: 16),
          _WhyThisWorks(controller: controller, job: job),
          const SizedBox(height: 20),
          Text(
            'Refine',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Change one domain and keep the other. Your selections are '
            'preserved either way.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (job.intent.wantsClothing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: busy ? null : controller.chooseGarmentsThenRefine,
                icon: const Icon(Icons.checkroom_outlined, size: 18),
                label: const Text('Change clothing only'),
              ),
            ),
          if (job.intent.wantsHair)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: busy ? null : controller.editHairThenRefine,
                icon: const Icon(Icons.content_cut_outlined, size: 18),
                label: const Text('Change hair only'),
              ),
            ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            MakeoverErrorBanner(error),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => controller.saveAndChooseVisibility(selected),
            icon: const Icon(Icons.bookmark_outline),
            label: const Text('Save this look'),
          ),
          const SizedBox(height: 32),
        ],
      );
    });
  }
}

/// Segmented control for whole look / clothing / hair (UI-07).
class _FocusSelector extends StatelessWidget {
  const _FocusSelector({required this.controller, required this.job});

  final CreateMakeoverController controller;
  final MakeoverJob job;

  @override
  Widget build(BuildContext context) {
    final domains = job.intent.requestedDomains;
    if (domains.length < 2) return const SizedBox.shrink();

    return Obx(
      () => SegmentedButton<MakeoverDomain?>(
        segments: [
          const ButtonSegment(value: null, label: Text('Whole look')),
          for (final domain in domains)
            ButtonSegment(value: domain, label: Text(domain.label)),
        ],
        selected: {controller.compareFocus.value},
        onSelectionChanged: (selection) => controller.focusOn(selection.first),
      ),
    );
  }
}

/// Explains coordination and context rather than attractiveness.
class _WhyThisWorks extends StatelessWidget {
  const _WhyThisWorks({required this.controller, required this.job});

  final CreateMakeoverController controller;
  final MakeoverJob job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intent = job.intent;

    return Obx(() {
      final focus = controller.compareFocus.value;
      final reasons = <String>[
        if (focus == null || focus == MakeoverDomain.clothing)
          if (intent.wantsClothing)
            'Clothing: ${intent.garments.map((g) => (g['name'] ?? 'item').toString()).join(', ')}',
        if (focus == null || focus == MakeoverDomain.hair)
          if (intent.wantsHair) 'Hair: ${intent.hairPrompt}',
        if (intent.occasion.isNotEmpty) 'Chosen for: ${intent.occasion}',
        if (intent.desiredFeeling.isNotEmpty)
          'You wanted to feel: ${intent.desiredFeeling}',
        if (intent.modestyPreference.isNotEmpty)
          'Respecting: ${intent.modestyPreference}',
        if (intent.exclusions.isNotEmpty)
          'Avoiding: ${intent.exclusions.join(', ')}',
      ];

      if (reasons.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why this works',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(reason, style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      );
    });
  }
}

/// One panel in the horizontal compare strip.
class _ComparePanel extends StatelessWidget {
  const _ComparePanel({
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: imageUrl.isEmpty
                  ? const Center(child: Icon(Icons.image_outlined))
                  : AppNetworkImage(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fallback: const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
