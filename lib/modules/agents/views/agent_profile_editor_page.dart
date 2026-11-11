// An agent edits their public profile.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/agents/controllers/agent_profile_editor_controller.dart';
import 'package:banigoba/modules/agents/models/agent_summary.dart';
import 'package:banigoba/modules/agents/widgets/agent_form_field.dart';

class AgentProfileEditorPage extends StatelessWidget {
  const AgentProfileEditorPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<AgentProfileEditorController>(
      init: AgentProfileEditorController(),
      global: false,
      builder: (controller) => Obx(() {
        if (controller.loading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final isHair = controller.type.value == 'hair';
        return Scaffold(
          appBar: AppBar(title: const Text('Agent Profile')),
          body: Form(
            key: controller.formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'hair',
                      icon: Icon(Icons.content_cut_rounded),
                      label: Text('Hair'),
                    ),
                    ButtonSegment(
                      value: 'clothes',
                      icon: Icon(Icons.checkroom_outlined),
                      label: Text('Clothes'),
                    ),
                  ],
                  selected: {controller.type.value},
                  onSelectionChanged: (value) =>
                      controller.setType(value.first),
                ),
                const SizedBox(height: 16),
                AgentFormField(
                  controller: controller.name,
                  label: 'Agent or studio name',
                  required: true,
                ),
                AgentFormField(
                  controller: controller.bio,
                  label: 'Bio',
                  hint: isHair
                      ? 'Tell customers about your hair services'
                      : 'Tell customers about your styling services',
                  maxLines: 4,
                  required: true,
                ),
                AgentFormField(
                  controller: controller.location,
                  label: 'Location',
                ),
                AgentFormField(
                  controller: controller.services,
                  label: 'Services',
                  hint: isHair
                      ? 'Braids, wigs, bridal hair, natural hair'
                      : 'Personal shopping, wardrobe edit, event styling',
                ),
                AgentFormField(
                  controller: controller.rate,
                  label: 'Rate or price range',
                  hint: 'Example: 50-150',
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
                        : 'Save Agent Profile',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AgentColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
