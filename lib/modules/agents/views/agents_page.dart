// Agents: find hair and clothes agents, and request one.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/agents/controllers/agents_controller.dart';
import 'package:banigoba/modules/agents/models/agent_summary.dart';
import 'package:banigoba/modules/agents/views/agent_detail_page.dart';
import 'package:banigoba/modules/agents/views/agent_profile_editor_page.dart';
import 'package:banigoba/modules/agents/views/agent_requests_page.dart';
import 'package:banigoba/modules/agents/widgets/agent_cards.dart';
import 'package:banigoba/modules/agents/widgets/agent_empty_state.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/views/provider_setup.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

export 'package:banigoba/modules/agents/views/agent_profile_editor_page.dart'
    show AgentProfileEditorPage;

class AgentsPage extends StatelessWidget {
  const AgentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<AgentsController>(
      init: AgentsController(),
      global: false,
      builder: (controller) => _AgentsView(controller: controller),
    );
  }
}

class _AgentsView extends StatelessWidget {
  const _AgentsView({required this.controller});

  final AgentsController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Agents',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surface,
        actions: [
          IconButton(
            tooltip: 'Create agent profile',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => openProviderSetup(
              context,
              ProviderRole.salon,
              editor: () => const AgentProfileEditorPage(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search agents, service, location',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    controller: controller,
                    label: 'Hair Agents',
                    index: 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TabButton(
                    controller: controller,
                    label: 'Clothes Agents',
                    index: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.to<void>(() => const AgentRequestsPage()),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('My Agent Requests'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _AgentsList(controller: controller)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.controller,
    required this.label,
    required this.index,
  });

  final AgentsController controller;
  final String label;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final selected = controller.tab.value == index;
      return FilledButton(
        onPressed: () => controller.setTab(index),
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? AgentColors.primary
              : colors.surfaceContainerLow,
          foregroundColor: selected ? Colors.white : colors.onSurface,
          elevation: 0,
        ),
        child: Text(label),
      );
    });
  }
}

class _AgentsList extends StatelessWidget {
  const _AgentsList({required this.controller});

  final AgentsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final type = controller.selectedAgentType;
      return StreamBuilder<List<Map<String, dynamic>>>(
        // One stream per tab; the key restarts it when the tab changes.
        key: ValueKey(type),
        stream: ProfileService()
            .watchVerifiedProviders('salon')
            .map(
              (agents) => [
                for (final agent in agents)
                  if ((agent['agentProfile'] as Map?)?['type'] == type) agent,
              ],
            ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AgentEmptyState(
              icon: Icons.warning_amber_rounded,
              title: 'Agents could not be loaded.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Obx(() {
            final agents =
                snapshot.data!
                    .map((profile) => AgentSummary.fromProfile(profile))
                    .where(controller.matchesQuery)
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

            if (agents.isEmpty) {
              final typeLabel = type == 'hair' ? 'hair' : 'clothes';
              return AgentEmptyState(
                icon: type == 'hair'
                    ? Icons.content_cut_rounded
                    : Icons.checkroom_outlined,
                title: controller.query.value.isEmpty
                    ? 'No $typeLabel agents yet.'
                    : 'No $typeLabel agents match your search.',
                actionLabel: 'Create Agent Profile',
                onAction: () => openProviderSetup(
                  context,
                  ProviderRole.salon,
                  editor: () => const AgentProfileEditorPage(),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              itemCount: agents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final agent = agents[index];
                return AgentCard(
                  agent: agent,
                  onTap: () =>
                      Get.to<void>(() => AgentDetailPage(agent: agent)),
                );
              },
            );
          });
        },
      );
    });
  }
}
