// My Profile Details: the user's face and full-body photos, clothing and shoe
// size, and body measurements (September 2026 request).
//
// Used by the eFitting Room when shopping online and by Fashion Idol / Style
// twin makeovers. Every detail is optional. Photos are saved as soon as they
// upload (they are slow to redo); sizes and measurements are saved with the
// Save button.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/profile_details/controllers/body_profile_controller.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/profile_details/services/body_profile_service.dart';
import 'package:banigoba/modules/profile_details/widgets/body_profile_chrome.dart';
import 'package:banigoba/modules/profile_details/widgets/body_profile_intro_card.dart';
import 'package:banigoba/modules/profile_details/widgets/body_profile_sections.dart';
import 'package:banigoba/modules/profile_details/widgets/how_to_measure_sheet.dart';

export 'package:banigoba/modules/profile_details/controllers/body_profile_controller.dart'
    show ProfileImagePicker;

class BodyProfilePage extends StatelessWidget {
  const BodyProfilePage({super.key, this.store, this.pickImage});

  /// Injected in tests; defaults to the signed-in user's saved details.
  final BodyProfileStore? store;

  /// Injected in tests; defaults to the device camera and gallery.
  final ProfileImagePicker? pickImage;

  static const int maxPhotoBytes = BodyProfileController.maxPhotoBytes;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<BodyProfileController>(
      init: BodyProfileController(store: store, pickImage: pickImage),
      global: false,
      builder: (controller) => _BodyProfileView(controller: controller),
    );
  }
}

class _BodyProfileView extends StatelessWidget {
  const _BodyProfileView({required this.controller});

  final BodyProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !controller.hasUnsavedChanges.value,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.confirmLeave();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('My Profile Details')),
          body: _body(context),
          bottomNavigationBar:
              controller.isLoading.value || controller.loadError.isNotEmpty
              ? null
              : BodyProfileSaveBar(
                  isSaving: controller.isSaving.value,
                  onSave: controller.save,
                ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = controller.loadError.value;
    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.load,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final hasExtras = BodyMeasurement.extra.any(
      (measurement) => controller.measurements[measurement]!.text.isNotEmpty,
    );
    // Not a lazy ListView: every field must stay mounted so the Form can
    // validate the ones scrolled out of view.
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Counts what is typed as well as what is saved.
            Obx(() {
              final _ = controller.edits.value;
              return BodyProfileIntroCard(
                detailsAdded: controller.formProfile().detailsAdded,
              );
            }),
            const BodyProfileSectionTitle('Photos'),
            BodyProfilePhotos(controller: controller),
            const BodyProfileSectionTitle('Sizes'),
            BodyProfileSizes(controller: controller),
            BodyProfileSectionTitle(
              'Measurements',
              action: TextButton.icon(
                onPressed: () => showHowToMeasureSheet(context),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('How to measure'),
              ),
            ),
            BodyMeasurementGrid(
              controller: controller,
              measurements: BodyMeasurement.requested,
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const ValueKey('more_measurements'),
                initiallyExpanded: hasExtras,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text(
                  'More measurements',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Chest, hips and inside leg'),
                children: [
                  BodyMeasurementGrid(
                    controller: controller,
                    measurements: BodyMeasurement.extra,
                  ),
                ],
              ),
            ),
            const BodyProfileSectionTitle('Anything else'),
            TextFormField(
              key: const ValueKey('profile_notes'),
              controller: controller.notes,
              onChanged: controller.markChanged,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. long arms, broad back, prefer a loose fit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
