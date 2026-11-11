// Curators' hairstyle catalogue: upload, edit and browse the hairstyles the
// AI hair makeover offers. Moved here from the retired My Hair Style flow
// (October 2026 review, F-4); only the curators' workspace opens it.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/admin/controllers/hairstyle_upload_controller.dart';
import 'package:banigoba/modules/admin/models/hairstyle_catalog_options.dart';
import 'package:banigoba/modules/admin/widgets/hair_upload_fields.dart';
import 'package:banigoba/modules/admin/widgets/uploaded_hairstyles_section.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class TemporaryHairstyleUploadPage extends StatelessWidget {
  const TemporaryHairstyleUploadPage({
    super.key,
    this.docId,
    this.initialData,
    this.curatorMode = false,
  });

  final String? docId;
  final Map<String, dynamic>? initialData;
  final bool curatorMode;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: it is opened with a hairstyle to edit, or none.
    return GetBuilder<HairstyleUploadController>(
      init: HairstyleUploadController(
        docId: docId,
        initialData: initialData,
        curatorMode: curatorMode,
      ),
      global: false,
      builder: (controller) => _HairstyleUploadView(controller: controller),
    );
  }
}

class _HairstyleUploadView extends StatelessWidget {
  const _HairstyleUploadView({required this.controller});

  final HairstyleUploadController controller;

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back sits top-left, where users expect it.
                      IconButton(
                        tooltip: 'Back',
                        onPressed: Get.back<void>,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.isEditing ? 'Edit Hairstyle' : 'Upload Hairstyle',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
                child: _form(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final c = controller;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => GestureDetector(
            onTap: c.saving.value ? null : c.pickImage,
            child: Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: _imagePreview(context),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: c.name,
          textCapitalization: TextCapitalization.words,
          decoration: _fieldDecoration('Display Name'),
        ),
        const SizedBox(height: 14),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UploadDropdown(
                label: 'Length',
                value: c.length.value,
                options: hairCatalogLengths,
                onChanged: (v) => c.length.value = v,
              ),
              UploadDropdown(
                label: 'Gender',
                value: c.gender.value,
                options: hairCatalogGenders,
                onChanged: (v) => c.gender.value = v,
              ),
              UploadDropdown(
                label: 'Hair Type / Texture',
                value: c.hairType.value,
                options: hairCatalogTypes,
                onChanged: (v) => c.hairType.value = v,
              ),
              UploadMultiSelect(
                label: 'Style Type',
                selected: c.styleTypes.value,
                options: hairCatalogStyleTypes,
                onChanged: (v) => c.styleTypes.value = v,
              ),
              UploadDropdown(
                label: 'Cut Type Group',
                value: c.cutTypeGroup.value,
                options: hairCatalogCutTypes.keys.toList(),
                onChanged: c.chooseCutGroup,
              ),
              UploadDropdown(
                label: 'Cut Type',
                value: c.cutType.value,
                options: hairCatalogCutTypes[c.cutTypeGroup.value]!,
                onChanged: (v) => c.cutType.value = v,
              ),
              UploadMultiSelect(
                label: 'Occasion',
                selected: c.occasions.value,
                options: hairCatalogOccasions,
                onChanged: (v) => c.occasions.value = v,
              ),
              UploadDropdown(
                label: 'Colour',
                value: c.colour.value,
                options: hairCatalogColours,
                onChanged: (v) => c.colour.value = v,
              ),
              UploadDropdown(
                label: 'Maintenance Level',
                value: c.maintenanceLevel.value,
                options: hairCatalogMaintenanceLevels,
                onChanged: (v) => c.maintenanceLevel.value = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: c.saving.value ? null : Get.back<void>,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hairNavy,
                    side: const BorderSide(color: hairNavy),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HairButton(
                  label: c.isEditing ? 'Update' : 'Save',
                  icon: c.isEditing
                      ? Icons.save_outlined
                      : Icons.cloud_upload_outlined,
                  color: hairOrange,
                  loading: c.saving.value,
                  onPressed: c.save,
                ),
              ),
            ],
          ),
        ),
        if (!c.isEditing) ...[
          const SizedBox(height: 28),
          UploadedHairstylesSection(
            curatorMode: c.curatorMode,
            onEdit: c.openEditor,
          ),
        ],
      ],
    );
  }

  Widget _imagePreview(BuildContext context) {
    final c = controller;
    final bytes = c.previewBytes.value;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    }
    if (c.existingImageUrl.value.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AppNetworkImage(
          c.existingImageUrl.value,
          fit: BoxFit.cover,
          fallback: _placeholder(context),
        ),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 58,
          color: colors.outline,
        ),
        const SizedBox(height: 10),
        Text(
          controller.isEditing
              ? 'Tap to replace image'
              : 'Choose Hairstyle Image',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
