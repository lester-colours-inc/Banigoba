// The Makeover brief: photo, how to create the look, and what should change.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/core/style/style_catalogue.dart';
import 'package:banigoba/modules/makeover/controllers/makeover_controller.dart';
import 'package:banigoba/modules/makeover/widgets/look_source_picker.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_controls.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_views.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_look_hero.dart';
import 'package:banigoba/modules/provider/models/look_request.dart';

class MakeoverBrief extends StatelessWidget {
  const MakeoverBrief({super.key, required this.controller});

  final MakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return controller.isTryOn
        ? _TryOnBrief(controller: controller)
        : _DefaultBrief(controller: controller);
  }
}

/// Photo, then how (describe it, or a look you love), then what should
/// change: one clear path from top to bottom (October 2026 review, M-4).
class _DefaultBrief extends StatelessWidget {
  const _DefaultBrief({required this.controller});

  final MakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scope = controller.scope.value;
      final uploading = controller.isUploadingPhoto.value;
      final trends = curatedTrends
          .where((trend) => scope == null || trend.fitsScope(scope))
          .toList();

      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          MakeoverPhotoCard(
            photoUrl: controller.photoUrl.value,
            isLoading: controller.isLoadingPhoto.value || uploading,
            isEditingLook: controller.isEditing,
            onUpload: uploading
                ? null
                : () => controller.pickPhoto(ImageSource.gallery),
            onTakePhoto: uploading
                ? null
                : () => controller.pickPhoto(ImageSource.camera),
          ),
          const SizedBox(height: 28),
          const MakeoverSectionTitle('How do you want to create your look?'),
          const SizedBox(height: 14),
          LookSourcePicker(
            method: controller.method.value,
            onMethodChanged: controller.selectMethod,
            scope: scope ?? LookScope.fullLook,
            describeController: controller.describe,
            idolController: controller.idol,
            archetypes: styleArchetypes,
            selectedArchetype: controller.archetype.value,
            onArchetypeChanged: controller.selectArchetype,
            twin: TwinState(
              imageUrl: controller.twinUrl.value,
              isUploading: controller.isUploadingTwin.value,
              onPickFromCommunity: controller.pickTwinFromCommunity,
              onPickFromPhotos: controller.pickTwinFromPhotos,
            ),
            trends: trends,
            selectedTrend: controller.trend.value,
            onTrendChanged: controller.selectTrend,
            weather: controller.weather.value,
            onRetryWeather: controller.fetchWeather,
          ),
          const SizedBox(height: 32),
          ..._scopeAndError(controller, scope),
        ],
      );
    });
  }
}

/// Try on: the chosen look large at the top, then the user's photo, then
/// what to copy. No idea sources or gallery prompt; they don't apply.
class _TryOnBrief extends StatelessWidget {
  const _TryOnBrief({required this.controller});

  final MakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final uploading = controller.isUploadingPhoto.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          TryOnLookHero(imageUrl: controller.twinUrl.value),
          const SizedBox(height: 24),
          MakeoverPhotoCard(
            photoUrl: controller.photoUrl.value,
            isLoading: controller.isLoadingPhoto.value || uploading,
            onUpload: uploading
                ? null
                : () => controller.pickPhoto(ImageSource.gallery),
            onTakePhoto: uploading
                ? null
                : () => controller.pickPhoto(ImageSource.camera),
          ),
          const SizedBox(height: 28),
          ..._scopeAndError(
            controller,
            controller.scope.value,
            title: 'What do you want to try on?',
          ),
        ],
      );
    });
  }
}

List<Widget> _scopeAndError(
  MakeoverController controller,
  LookScope? scope, {
  String title = 'What should change?',
}) {
  final steps = scope?.parts ?? const <LookPart>[];
  final error = controller.error.value;
  return [
    MakeoverSectionTitle(
      title,
      subtitle: steps.length > 1
          ? 'One item at a time: '
                '${steps.map((part) => part.label).join(' · ')}'
          : 'Pick one before you generate.',
    ),
    const SizedBox(height: 16),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in LookScope.values)
          MakeoverPill(
            key: ValueKey('look_scope_${option.name}'),
            label: option.label,
            selected: option == scope,
            onTap: () => controller.selectScope(option),
          ),
      ],
    ),
    if (error.isNotEmpty) ...[
      const SizedBox(height: 16),
      MakeoverErrorBanner(message: error),
    ],
  ];
}

/// The "Generate my look" bar under the brief, with a hint on what is missing.
class MakeoverGenerateBar extends StatelessWidget {
  const MakeoverGenerateBar({super.key, required this.controller});

  final MakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final request = controller.request;
      final hint = controller.generateHint;

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  hint,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            MakeoverPrimaryButton(
              key: const ValueKey('makeover_generate'),
              label: controller.isEditing
                  ? 'Edit my look'
                  : controller.isTryOn
                  ? 'Try it on me'
                  : 'Generate my look',
              onPressed: request != null && request.isReady
                  ? controller.start
                  : null,
            ),
          ],
        ),
      );
    });
  }
}
