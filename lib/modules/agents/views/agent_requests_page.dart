// The customer's own agent requests, newest first.
import 'package:flutter/material.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/rows.dart';
import 'package:banigoba/modules/agents/widgets/agent_cards.dart';
import 'package:banigoba/modules/agents/widgets/agent_empty_state.dart';
import 'package:banigoba/modules/provider/services/request_service.dart';

class AgentRequestsPage extends StatelessWidget {
  const AgentRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Agent Requests')),
      body: user == null
          ? const AgentEmptyState(
              icon: Icons.lock_outline,
              title: 'Sign in to see your agent requests.',
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: const RequestService(RequestKind.hair)
                  .watchForCustomer(user.uid)
                  .map(
                    (requests) => requests.toList()
                      ..sort(
                        (a, b) => (asDateTime(b['createdAt']) ?? DateTime(0))
                            .compareTo(
                              asDateTime(a['createdAt']) ?? DateTime(0),
                            ),
                      ),
                  ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const AgentEmptyState(
                    icon: Icons.warning_amber_rounded,
                    title: 'Requests could not be loaded.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!;
                if (requests.isEmpty) {
                  return const AgentEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No agent requests yet.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      AgentRequestCard(data: requests[index]),
                );
              },
            ),
    );
  }
}
