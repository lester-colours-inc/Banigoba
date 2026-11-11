// The before/after panel of the avatar try-on: the avatar on the left, the
// generated look on the right, the other angles, and keep/discard.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/avatar_try_on_controller.dart';
import 'package:banigoba/modules/makeover/services/turn_around_service.dart';
import 'package:banigoba/modules/makeover/widgets/before_after_view.dart';
import 'package:banigoba/modules/makeover/widgets/turn_around_viewer.dart';

const Color tryOnPrimary = Color(0xFF0D0140);

/// When both engines have run, the providers become a chip row so the same
/// transformation view can switch between the two looks.
class TryOnPanel extends StatelessWidget {
  const TryOnPanel({super.key, required this.controller});

  final AvatarTryOnController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final providers = controller.resultProviders;
      if (providers.isEmpty) return const SizedBox.shrink();
      final visible = controller.visibleResult.value;
      final provider = controller.results.value.containsKey(visible)
          ? visible!
          : providers.first;
      final resultUrl = controller.results.value[provider];
      final avatarUrl = controller.avatarImageUrl.value;
      if (resultUrl == null || avatarUrl == null) {
        return const SizedBox.shrink();
      }
      final colors = Theme.of(context).colorScheme;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          const _PanelHeader(),
          if (providers.length > 1) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (final option in providers) ...[
                  _ProviderChip(
                    controller: controller,
                    provider: option,
                    isSelected: option == provider,
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'See the Transformation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Drag the handle to compare, or tap to see the look full screen.',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          BeforeAfterView(
            key: ValueKey(resultUrl),
            beforeImageUrl: avatarUrl,
            afterImageUrl: resultUrl,
            onTapAfter: () => controller.openFullScreenResult(provider),
          ),
          _TurnAroundSection(controller: controller, provider: provider),
          const SizedBox(height: 16),
          _Actions(controller: controller, provider: provider),
        ],
      );
    });
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Try On: Before & After',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 13,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 5),
              Text(
                'AI generated',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Switches the panel between the engines' looks.
class _ProviderChip extends StatelessWidget {
  const _ProviderChip({
    required this.controller,
    required this.provider,
    required this.isSelected,
  });

  final AvatarTryOnController controller;
  final TryOnProvider provider;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => Obx(() => _content(context));

  Widget _content(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: isSelected ? null : () => controller.showResult(provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? tryOnPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? tryOnPrimary : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : colors.onSurfaceVariant,
              ),
            ),
            if (controller.savedResults.value.contains(provider)) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                size: 14,
                color: isSelected ? Colors.white : colors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TurnAroundSection extends StatelessWidget {
  const _TurnAroundSection({required this.controller, required this.provider});

  final AvatarTryOnController controller;
  final TryOnProvider provider;

  @override
  Widget build(BuildContext context) => Obx(() => _content(context));

  Widget _content(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final views = controller.turns.value[provider];
    final isMaking = controller.turningProvider.value == provider;
    final madeAny = views != null && views.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'See every angle',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          madeAny
              ? 'Drag left or right to turn around. The sides and back are '
                    'estimated by AI, because the items are only shown from '
                    'the front.'
              : 'Turn around to see the side and back views. The sides and '
                    'back are estimated by AI.',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (madeAny)
          TurnAroundViewer(
            key: ValueKey('turn_${controller.results.value[provider]}'),
            views: views,
            isMakingMore: isMaking,
          ),
        if (!isMaking &&
            (views == null || views.length < TurnView.values.length))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              key: const ValueKey('turn_me_around'),
              onPressed: () => controller.turnAround(provider),
              icon: const Icon(Icons.threesixty),
              label: Text(
                madeAny ? 'Make the missing angles' : 'Turn me around',
              ),
            ),
          ),
        if (isMaking && !madeAny)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// Discard or keep the look currently on screen.
class _Actions extends StatelessWidget {
  const _Actions({required this.controller, required this.provider});

  final AvatarTryOnController controller;
  final TryOnProvider provider;

  @override
  Widget build(BuildContext context) => Obx(() => _content(context));

  Widget _content(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isSaved = controller.savedResults.value.contains(provider);
    final isSaving = controller.savingProvider.value == provider;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving
                ? null
                : () => controller.discardResult(provider),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              backgroundColor: colors.surfaceContainerLow,
              minimumSize: const Size(0, 54),
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isSaving || isSaved
                ? null
                : () => controller.saveCompletedOutfit(provider),
            style: FilledButton.styleFrom(
              backgroundColor: tryOnPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isSaved ? Icons.check_circle : Icons.save_outlined),
            label: Text(
              isSaved ? 'Saved' : 'Save Look',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
