// A designer edits their public profile and portfolio pieces.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/designers/controllers/designer_profile_editor_controller.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/designers/widgets/designer_form_field.dart';
import 'package:banigoba/modules/designers/widgets/piece_editor_card.dart';

class DesignerProfileEditorPage extends StatelessWidget {
  const DesignerProfileEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<DesignerProfileEditorController>(
      init: DesignerProfileEditorController(),
      global: false,
      builder: (controller) => _EditorView(controller: controller),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView({required this.controller});

  final DesignerProfileEditorController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Designer Profile')),
        body: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DesignerFormField(
                controller: controller.name,
                label: 'Designer or studio name',
                required: true,
              ),
              DesignerFormField(
                controller: controller.bio,
                label: 'Bio',
                hint: 'Tell customers what you design',
                maxLines: 4,
                required: true,
              ),
              DesignerFormField(
                controller: controller.location,
                label: 'Location',
              ),
              DesignerFormField(
                controller: controller.specialties,
                label: 'Specialties',
                hint: 'Bridal, streetwear, tailoring, gowns',
              ),
              DesignerFormField(
                controller: controller.priceRange,
                label: 'Price range',
                hint: 'Example: 100-500',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Portfolio Pieces',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.addPiece,
                    icon: const Icon(Icons.add),
                    label: const Text('Add a Piece'),
                  ),
                ],
              ),
              if (controller.pieces.isEmpty)
                Text(
                  'Show off a piece with a picture, its size, measurements, '
                  'fabric and where it was made.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (
                  int index = 0;
                  index < controller.pieces.length;
                  index += 1
                )
                  PieceEditorCard(
                    entry: controller.pieces[index],
                    onRemove: () => controller.removePiece(index),
                  ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: controller.saving.value ? null : controller.save,
                icon: controller.saving.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  controller.saving.value
                      ? 'Saving...'
                      : 'Save Designer Profile',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignerColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
