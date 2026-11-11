// The form a customer fills to ask a designer for a custom piece.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/designers/controllers/design_request_controller.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/designers/widgets/designer_form_field.dart';

class DesignRequestPage extends StatelessWidget {
  const DesignRequestPage({super.key, required this.designer});

  final DesignerSummary designer;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<DesignRequestController>(
      init: DesignRequestController(designer: designer),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const Text('Custom Design Request')),
        body: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                designer.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DesignerFormField(
                controller: controller.occasion,
                label: 'Occasion or piece',
                hint: 'Wedding dress, graduation suit, event outfit',
                required: true,
              ),
              DesignerFormField(
                controller: controller.budget,
                label: 'Budget',
                hint: 'Example: 150-300',
              ),
              DesignerFormField(
                controller: controller.deadline,
                label: 'Deadline',
                hint: 'Example: 30 July',
              ),
              DesignerFormField(
                controller: controller.measurements,
                label: 'Measurements and fit notes',
                hint: 'Add sizes, fit preference, or saved measurement notes',
                maxLines: 3,
              ),
              DesignerFormField(
                controller: controller.inspiration,
                label: 'Inspiration image links',
                hint: 'Paste links separated by commas',
                maxLines: 2,
              ),
              DesignerFormField(
                controller: controller.notes,
                label: 'Design notes',
                hint: 'Fabric, colors, cultural details, modesty, styling',
                maxLines: 4,
              ),
              const SizedBox(height: 10),
              Obx(
                () => FilledButton.icon(
                  onPressed: controller.saving.value ? null : controller.submit,
                  icon: controller.saving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    controller.saving.value ? 'Sending...' : 'Send Request',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignerColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
