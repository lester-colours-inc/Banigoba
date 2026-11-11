// The form a customer fills to request an agent.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/agents/controllers/agent_request_controller.dart';
import 'package:banigoba/modules/agents/models/agent_summary.dart';
import 'package:banigoba/modules/agents/widgets/agent_form_field.dart';

class AgentRequestPage extends StatelessWidget {
  const AgentRequestPage({super.key, required this.agent});

  final AgentSummary agent;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<AgentRequestController>(
      init: AgentRequestController(agent: agent),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const Text('Agent Request')),
        body: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                agent.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              AgentFormField(
                controller: controller.service,
                label: 'Service needed',
                hint: agent.type == 'hair'
                    ? 'Bridal hair, wig install, wash day styling'
                    : 'Personal shopping, event styling, wardrobe planning',
                required: true,
              ),
              AgentFormField(
                controller: controller.date,
                label: 'Preferred date',
                hint: 'Example: 30 July',
              ),
              AgentFormField(
                controller: controller.budget,
                label: 'Budget',
                hint: 'Example: 50-150',
              ),
              AgentFormField(
                controller: controller.location,
                label: 'Location',
                hint: 'City, salon, home visit, or online',
              ),
              AgentFormField(
                controller: controller.notes,
                label: 'Notes',
                hint: 'Occasion, hair texture, wardrobe goal, timing',
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
                    backgroundColor: AgentColors.primary,
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
