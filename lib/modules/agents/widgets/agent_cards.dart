// How an agent looks in a list and as an avatar, and a request as a card.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/modules/agents/models/agent_summary.dart';

class AgentCard extends StatelessWidget {
  const AgentCard({super.key, required this.agent, required this.onTap});

  final AgentSummary agent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AgentAvatar(agent: agent, radius: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(agent.typeLabel),
                    if (agent.location.isNotEmpty) Text(agent.location),
                    const SizedBox(height: 6),
                    Text(
                      agent.services.isEmpty
                          ? 'Fashion service agent'
                          : agent.services.take(3).join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class AgentAvatar extends StatelessWidget {
  const AgentAvatar({super.key, required this.agent, required this.radius});

  final AgentSummary agent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = agent.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AgentColors.primary,
      backgroundImage: imageUrl.isEmpty
          ? null
          : CachedNetworkImageProvider(imageUrl),
      child: imageUrl.isEmpty
          ? Icon(
              agent.type == 'hair'
                  ? Icons.content_cut_rounded
                  : Icons.checkroom_outlined,
              color: Colors.white,
              size: radius,
            )
          : null,
    );
  }
}

class AgentRequestCard extends StatelessWidget {
  const AgentRequestCard({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString();
    final type = (data['agentType'] ?? '').toString() == 'hair'
        ? 'Hair'
        : 'Clothes';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (data['service'] ?? '$type agent request').toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Agent: ${data['agentName'] ?? 'Agent'}'),
            if ((data['preferredDate'] ?? '').toString().isNotEmpty)
              Text('Date: ${data['preferredDate']}'),
            if ((data['budget'] ?? '').toString().isNotEmpty)
              Text('Budget: ${data['budget']}'),
          ],
        ),
      ),
    );
  }
}
