import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/event_service.dart';
import '../events/events_page.dart';
import '../wardrobe/measurement_page.dart';

class CuratorsWorkspacePage extends StatelessWidget {
  const CuratorsWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in as an admin to continue.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final isAdmin = data['isAdmin'] == true || data['role'] == 'admin';
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Curators Workspace')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Admin access is required to open Curators Workspace.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return const _CuratorsWorkspaceContent();
      },
    );
  }
}

class _CuratorsWorkspaceContent extends StatelessWidget {
  const _CuratorsWorkspaceContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Curators Workspace')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 18),
          const Text(
            'Pending Event Approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const _PendingEventsList(),
        ],
      ),
    );
  }
}

class _PendingEventsList extends StatelessWidget {
  const _PendingEventsList();

  @override
  Widget build(BuildContext context) {
    final service = EventService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchPendingEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load pending events.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aTime = a.data()['submittedAt'] as Timestamp?;
            final bTime = b.data()['submittedAt'] as Timestamp?;
            return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
              aTime?.millisecondsSinceEpoch ?? 0,
            );
          });

        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No events waiting for approval.')),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final doc = events[index];
            return EventCard(
              data: doc.data(),
              adminActions: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => service.disapproveEvent(doc.id),
                      icon: const Icon(Icons.close),
                      label: const Text('Disapprove'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => service.approveEvent(doc.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0D0140),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
