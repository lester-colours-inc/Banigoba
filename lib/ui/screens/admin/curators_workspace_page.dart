// Admin dashboard for marketplace curation.
//
// Curators use this workspace to approve public-facing content: hairstyle
// uploads, events, designers, boutiques, and agents. Verification flags stored
// on nested user profile maps control whether those profiles are visible in the
// customer marketplace.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/services/event_service.dart';
import '../../../data/services/notification_service.dart';
import '../events/events_page.dart';
import 'hairstyle_catalog_upload_page.dart';

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
            appBar: AppBar(
              title: const Text('Curators Workspace'),
              actions: [
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  onPressed: () => _signOutAdmin(context),
                ),
              ],
            ),
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

class _CuratorsWorkspaceContent extends StatefulWidget {
  const _CuratorsWorkspaceContent();

  @override
  State<_CuratorsWorkspaceContent> createState() =>
      _CuratorsWorkspaceContentState();
}

class _CuratorsWorkspaceContentState extends State<_CuratorsWorkspaceContent> {
  final _service = EventService();
  int _tab = 0;
  static const _menuItems = [
    _AdminMenuItem(
      label: 'Hair Uploads',
      icon: Icons.content_cut_outlined,
      title: 'Hairstyle Catalog',
    ),
    _AdminMenuItem(
      label: 'Events',
      icon: Icons.event_available_outlined,
      title: 'Event Verification',
    ),
    _AdminMenuItem(
      label: 'Designers',
      icon: Icons.design_services_outlined,
      title: 'Designer Verification',
    ),
    _AdminMenuItem(
      label: 'Shops',
      icon: Icons.storefront_outlined,
      title: 'Shop Verification',
    ),
    _AdminMenuItem(
      label: 'Agents',
      icon: Icons.support_agent_outlined,
      title: 'Agent Verification',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _service.removeExpiredEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curators Workspace'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOutAdmin(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _AdminMenu(
            selectedIndex: _tab,
            items: _menuItems,
            onSelected: (index) => setState(() => _tab = index),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  _menuItems[_tab].title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_tab == 0) const _HairstyleCatalogPanel(),
                if (_tab == 1) _EventVerificationPanel(service: _service),
                if (_tab == 2)
                  const _ProfileVerificationList(
                    profileField: 'designerProfile',
                    titleFallback: 'Designer',
                    emptyText: 'No designer profiles to verify.',
                    profileTypeLabel: 'designer',
                  ),
                if (_tab == 3)
                  const _ProfileVerificationList(
                    profileField: 'shop',
                    titleFallback: 'Shop',
                    emptyText: 'No shop profiles to verify.',
                    profileTypeLabel: 'shop',
                    requireActive: false,
                  ),
                if (_tab == 4)
                  const _ProfileVerificationList(
                    profileField: 'agentProfile',
                    titleFallback: 'Agent',
                    emptyText: 'No agent profiles to verify.',
                    profileTypeLabel: 'agent',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _signOutAdmin(BuildContext context) async {
  try {
    await AuthService().signOut();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not log out. Please try again.')),
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
    required this.title,
  });

  final String label;
  final IconData icon;
  final String title;
}

class _AdminMenu extends StatelessWidget {
  const _AdminMenu({
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<_AdminMenuItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = selectedIndex == index;
          return SizedBox(
            width: 118,
            child: OutlinedButton(
              onPressed: () => onSelected(index),
              style: OutlinedButton.styleFrom(
                backgroundColor: selected
                    ? const Color(0xFF0D0140)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                foregroundColor: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF0D0140)
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventVerificationPanel extends StatelessWidget {
  const _EventVerificationPanel({required this.service});

  final EventService service;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AdminSubheading('Pending Events'),
        const SizedBox(height: 10),
        _PendingEventsList(service: service),
        const SizedBox(height: 24),
        const _AdminSubheading('Approved Events'),
        const SizedBox(height: 10),
        _ApprovedEventsManagementList(service: service),
      ],
    );
  }
}

class _AdminSubheading extends StatelessWidget {
  const _AdminSubheading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }
}

class _HairstyleCatalogPanel extends StatelessWidget {
  const _HairstyleCatalogPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF0D0140),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.content_cut_outlined),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage hairstyle uploads',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Add catalog hairstyles and edit metadata such as length, texture, multiple style types, multiple occasions, colour, and maintenance level.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const TemporaryHairstyleUploadPage(curatorMode: true),
                  ),
                ),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Open Hairstyle Upload'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D0140),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileVerificationList extends StatelessWidget {
  const _ProfileVerificationList({
    required this.profileField,
    required this.titleFallback,
    required this.emptyText,
    required this.profileTypeLabel,
    this.requireActive = true,
  });

  final String profileField;
  final String titleFallback;
  final String emptyText;
  final String profileTypeLabel;
  final bool requireActive;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load $profileTypeLabel profiles.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Each provider type stores its public profile on a different nested
        // field, but the verification card can render all of them using the
        // same normalized shape.
        final profiles =
            snapshot.data!.docs.where((doc) {
              final profile = Map<String, dynamic>.from(
                doc.data()[profileField] as Map? ?? const {},
              );
              if (profile.isEmpty) return false;
              final name = (profile['name'] ?? '').toString().trim();
              final hasProfile =
                  name.isNotEmpty ||
                  (profile['description'] ?? '').toString().trim().isNotEmpty ||
                  (profile['bio'] ?? '').toString().trim().isNotEmpty;
              if (!hasProfile) return false;
              return !requireActive || profile['active'] == true;
            }).toList()..sort((a, b) {
              final aProfile = Map<String, dynamic>.from(
                a.data()[profileField] as Map? ?? const {},
              );
              final bProfile = Map<String, dynamic>.from(
                b.data()[profileField] as Map? ?? const {},
              );
              return _profileName(
                aProfile,
                a.data(),
                titleFallback,
              ).compareTo(_profileName(bProfile, b.data(), titleFallback));
            });

        if (profiles.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text(emptyText)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = profiles[index];
            final data = doc.data();
            final profile = Map<String, dynamic>.from(
              data[profileField] as Map? ?? const {},
            );
            return _ProfileVerificationCard(
              userId: doc.id,
              profileField: profileField,
              profileTypeLabel: profileTypeLabel,
              title: _profileName(profile, data, titleFallback),
              subtitle: _profileSubtitle(profile, data),
              verified: profile['verified'] == true,
            );
          },
        );
      },
    );
  }

  static String _profileName(
    Map<String, dynamic> profile,
    Map<String, dynamic> user,
    String fallback,
  ) {
    return (profile['name'] ??
            profile['shopName'] ??
            user['displayName'] ??
            fallback)
        .toString();
  }

  static String _profileSubtitle(
    Map<String, dynamic> profile,
    Map<String, dynamic> user,
  ) {
    final parts =
        [
          profile['type'],
          profile['location'],
          profile['description'],
          profile['bio'],
        ].map((value) => value?.toString().trim() ?? '').where((value) {
          return value.isNotEmpty;
        }).toList();
    return parts.take(3).join(' • ');
  }
}

class _ProfileVerificationCard extends StatelessWidget {
  const _ProfileVerificationCard({
    required this.userId,
    required this.profileField,
    required this.profileTypeLabel,
    required this.title,
    required this.subtitle,
    required this.verified,
  });

  final String userId;
  final String profileField;
  final String profileTypeLabel;
  final String title;
  final String subtitle;
  final bool verified;

  Future<void> _setVerified(BuildContext context, bool value) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      // Use update() for dotted paths so Firestore changes the nested profile
      // map that marketplace screens read, e.g. shop.verified.
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        '$profileField.verified': value,
        '$profileField.verificationStatus': value ? 'verified' : 'unverified',
        '$profileField.verifiedAt': value ? FieldValue.serverTimestamp() : null,
        '$profileField.verifiedBy': value ? adminId : null,
      });

      if (value && profileField == 'shop') {
        try {
          // Approval should succeed even if the notification write is denied,
          // so keep this secondary side effect isolated.
          await NotificationService().addNotification(
            receiverId: userId,
            title: 'Boutique approved',
            body:
                'approved your boutique. Customers can now discover your shop.',
            type: 'shop_approval',
            extraData: {
              'fromId': adminId,
              'fromName': 'Curators Workspace',
              'sellerId': userId,
              'shopName': title,
            },
          );
        } catch (error) {
          debugPrint('Shop approval notification failed: $error');
        }
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '$title verified successfully.'
                : '$title verification removed.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update verification: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: verified
                      ? Colors.green
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: verified
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  child: Icon(
                    verified
                        ? Icons.verified_outlined
                        : Icons.pending_actions_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        verified
                            ? 'Verified $profileTypeLabel'
                            : 'Waiting for $profileTypeLabel verification',
                        style: TextStyle(
                          color: verified ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(subtitle),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: verified
                        ? () => _setVerified(context, false)
                        : null,
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Unverify'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: verified
                        ? null
                        : () => _setVerified(context, true),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Verify'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D0140),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingEventsList extends StatelessWidget {
  const _PendingEventsList({required this.service});

  final EventService service;

  @override
  Widget build(BuildContext context) {
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

class _ApprovedEventsManagementList extends StatelessWidget {
  const _ApprovedEventsManagementList({required this.service});

  final EventService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.watchApprovedManageableEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load approved events.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final events =
            snapshot.data!.docs.where((doc) {
              final eventDate = doc.data()['eventDateTime'] as Timestamp?;
              return eventDate == null || eventDate.toDate().isAfter(now);
            }).toList()..sort((a, b) {
              final aTime = a.data()['eventDateTime'] as Timestamp?;
              final bTime = b.data()['eventDateTime'] as Timestamp?;
              return (aTime?.millisecondsSinceEpoch ?? 0).compareTo(
                bTime?.millisecondsSinceEpoch ?? 0,
              );
            });

        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('No approved events are live.')),
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
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Unpublish'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => service.removeEvent(doc.id),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
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
