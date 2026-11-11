// The Customer side of Fashion Designers: search, the designers list and the
// customer's own requests.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/designers/controllers/fashion_designers_controller.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/designers/views/designer_detail_page.dart';
import 'package:banigoba/modules/designers/views/designer_profile_editor_page.dart';
import 'package:banigoba/modules/designers/widgets/design_request_card.dart';
import 'package:banigoba/modules/designers/widgets/designer_cards.dart';
import 'package:banigoba/modules/designers/widgets/designer_empty_state.dart';
import 'package:banigoba/modules/provider/models/provider_roles.dart';
import 'package:banigoba/modules/provider/services/request_service.dart';
import 'package:banigoba/modules/provider/views/provider_setup.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

class DesignersCustomerView extends StatelessWidget {
  const DesignersCustomerView({super.key, required this.controller});

  final FashionDesignersController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
          child: TextField(
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search designers, style, location',
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
                  label: 'Designers',
                  index: 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TabButton(
                  controller: controller,
                  label: 'My Requests',
                  index: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Obx(
            () => controller.customerTab.value == 0
                ? _DesignersList(controller: controller)
                : _CustomerRequests(controller: controller),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.controller,
    required this.label,
    required this.index,
  });

  final FashionDesignersController controller;
  final String label;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final selected = controller.customerTab.value == index;
      return FilledButton(
        onPressed: () => controller.setCustomerTab(index),
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? DesignerColors.primary
              : colors.surfaceContainerLow,
          foregroundColor: selected ? Colors.white : colors.onSurface,
          elevation: 0,
        ),
        child: Text(label),
      );
    });
  }
}

class _DesignersList extends StatelessWidget {
  const _DesignersList({required this.controller});

  final FashionDesignersController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ProfileService().watchVerifiedProviders('designer'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const DesignerEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Designers could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Obx(() {
          final designers =
              snapshot.data!
                  .map((profile) => DesignerSummary.fromProfile(profile))
                  .where(controller.matchesQuery)
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          if (designers.isEmpty) {
            return DesignerEmptyState(
              icon: Icons.design_services_outlined,
              title: controller.query.value.isEmpty
                  ? 'No designer profiles yet.'
                  : 'No designers match your search.',
              actionLabel: 'Create Designer Profile',
              onAction: () => openProviderSetup(
                context,
                ProviderRole.designer,
                editor: () => const DesignerProfileEditorPage(),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            itemCount: designers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final designer = designers[index];
              return DesignerCard(
                designer: designer,
                onTap: () =>
                    Get.to<void>(() => DesignerDetailView(designer: designer)),
              );
            },
          );
        });
      },
    );
  }
}

class _CustomerRequests extends StatelessWidget {
  const _CustomerRequests({required this.controller});

  final FashionDesignersController controller;

  @override
  Widget build(BuildContext context) {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      return const DesignerEmptyState(
        icon: Icons.lock_outline,
        title: 'Sign in to see your custom design requests.',
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: const RequestService(
        RequestKind.design,
      ).watchForCustomer(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const DesignerEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Requests could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.toList()
          ..sort(controller.compareRequestsNewestFirst);
        if (requests.isEmpty) {
          return const DesignerEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No custom design requests yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = requests[index];
            return DesignRequestCard(
              data: data,
              onMessage: () => controller.openConversation(
                designerId: (data['designerId'] ?? '').toString(),
                designerName: (data['designerName'] ?? 'Designer').toString(),
                customerId: user.uid,
                customerName: (data['customerName'] ?? 'Customer').toString(),
                asDesigner: false,
                requestId: data['id'].toString(),
                requestData: data,
              ),
            );
          },
        );
      },
    );
  }
}
