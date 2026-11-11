// The Designer side of Fashion Designers: profile panel, messages and the
// requests customers sent.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/designers/controllers/fashion_designers_controller.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/designers/views/designer_profile_editor_page.dart';
import 'package:banigoba/modules/designers/widgets/design_request_card.dart';
import 'package:banigoba/modules/designers/widgets/designer_empty_state.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/request_service.dart';
import 'package:banigoba/modules/provider/views/provider_setup.dart';
import 'package:banigoba/modules/shop/views/shop_chat_page.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

class DesignerWorkspace extends StatelessWidget {
  const DesignerWorkspace({super.key, required this.controller});

  final FashionDesignersController controller;

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      return const DesignerEmptyState(
        icon: Icons.lock_outline,
        title: 'Sign in to manage your designer workspace.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      children: [
        _ProfilePanel(userId: user.uid),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: DesignerColors.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.chat_bubble_outline),
            ),
            title: const Text(
              'Messages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Reply to customers about their custom designs.',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Get.to<void>(() => const ShopChatInboxPage(sellerOnly: true)),
          ),
        ),
        const SizedBox(height: 18),
        const DesignerSectionTitle('Incoming Requests'),
        const SizedBox(height: 12),
        _IncomingRequests(controller: controller, designerId: user.uid),
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().watch(userId),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final profile = Map<String, dynamic>.from(
          data['designerProfile'] as Map? ?? const {},
        );
        final active = profile['active'] == true;
        final name = (profile['name'] ?? data['displayName'] ?? 'Designer')
            .toString();
        final bio = (profile['bio'] ?? '').toString();
        final specialties = toStringList(profile['specialties']);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      active
                          ? Icons.verified_outlined
                          : Icons.design_services_outlined,
                      color: DesignerColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        active ? name : 'Create your designer profile',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (specialties.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties
                        .take(4)
                        .map((item) => Chip(label: Text(item)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => openProviderSetup(
                      context,
                      ProviderRole.designer,
                      editor: () => const DesignerProfileEditorPage(),
                    ),
                    icon: Icon(active ? Icons.edit_outlined : Icons.add),
                    label: Text(
                      active ? 'Edit Designer Profile' : 'Create Profile',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignerColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IncomingRequests extends StatelessWidget {
  const _IncomingRequests({required this.controller, required this.designerId});

  final FashionDesignersController controller;
  final String designerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: const RequestService(
        RequestKind.design,
      ).watchForProvider(designerId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const DesignerEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Incoming requests could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.toList()
          ..sort(controller.compareRequestsNewestFirst);
        if (requests.isEmpty) {
          return const DesignerEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No custom design requests yet.',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = requests[index];
            final requestId = data['id'].toString();
            return DesignRequestCard(
              data: data,
              designerView: true,
              onMessage: () => controller.openConversation(
                designerId: designerId,
                designerName: 'Designer',
                customerId: (data['customerId'] ?? '').toString(),
                customerName: (data['customerName'] ?? 'Customer').toString(),
                asDesigner: true,
                requestId: requestId,
                requestData: data,
              ),
              onStatusSelected: (status) =>
                  controller.updateRequestStatus(requestId, status, data),
            );
          },
        );
      },
    );
  }
}
