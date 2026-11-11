// An agent's page: who they are, their services, and a way to request them.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/agents/models/agent_summary.dart';
import 'package:banigoba/modules/agents/views/agent_request_page.dart';
import 'package:banigoba/modules/agents/widgets/agent_cards.dart';
import 'package:banigoba/modules/agents/widgets/agent_empty_state.dart';

class AgentDetailPage extends StatelessWidget {
  const AgentDetailPage({super.key, required this.agent});

  final AgentSummary agent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: Text(agent.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  AgentAvatar(agent: agent, radius: 38),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(agent.typeLabel),
                        if (agent.location.isNotEmpty) Text(agent.location),
                        if (agent.rate.isNotEmpty) Text(agent.rate),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Get.to<void>(() => AgentRequestPage(agent: agent)),
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Request Agent'),
            style: FilledButton.styleFrom(
              backgroundColor: AgentColors.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 22),
          if (agent.bio.isNotEmpty) ...[
            const AgentSectionTitle('About'),
            const SizedBox(height: 8),
            Text(agent.bio, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 22),
          ],
          if (agent.services.isNotEmpty) ...[
            const AgentSectionTitle('Services'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: agent.services
                  .map((service) => Chip(label: Text(service)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
