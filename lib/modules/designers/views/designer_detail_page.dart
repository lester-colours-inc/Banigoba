// A designer's page: their story, specialties and portfolio, with the ways to
// request a design or message them.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/designers/controllers/designer_detail_controller.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/designers/views/design_request_page.dart';
import 'package:banigoba/modules/designers/widgets/designer_cards.dart';
import 'package:banigoba/modules/designers/widgets/designer_empty_state.dart';
import 'package:banigoba/modules/designers/widgets/portfolio_piece_sheet.dart';
import 'package:banigoba/modules/provider/models/portfolio_piece.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class DesignerDetailPage extends StatelessWidget {
  const DesignerDetailPage({super.key, required this.designerId});

  final String designerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().watch(designerId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: DesignerEmptyState(
              icon: Icons.warning_amber_rounded,
              title: 'Designer profile could not be loaded.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data!.isEmpty) {
          return const Scaffold(
            body: DesignerEmptyState(
              icon: Icons.design_services_outlined,
              title: 'Designer profile not found.',
            ),
          );
        }

        return DesignerDetailView(
          designer: DesignerSummary.fromProfile(snapshot.data!),
        );
      },
    );
  }
}

class DesignerDetailView extends StatelessWidget {
  const DesignerDetailView({super.key, required this.designer});

  final DesignerSummary designer;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<DesignerDetailController>(
      init: DesignerDetailController(designer: designer),
      global: false,
      builder: (controller) =>
          _DetailBody(controller: controller, designer: designer),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.controller, required this.designer});

  final DesignerDetailController controller;
  final DesignerSummary designer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: Text(designer.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DesignerHero(designer: designer),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                Get.to<void>(() => DesignRequestPage(designer: designer)),
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Request Custom Design'),
            style: FilledButton.styleFrom(
              backgroundColor: DesignerColors.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: controller.openConversation,
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message Designer'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 22),
          if (designer.bio.isNotEmpty) ...[
            const DesignerSectionTitle('About'),
            const SizedBox(height: 8),
            Text(designer.bio, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 22),
          ],
          if (designer.specialties.isNotEmpty) ...[
            const DesignerSectionTitle('Specialties'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: designer.specialties
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
            const SizedBox(height: 22),
          ],
          if (designer.portfolioPieces.isNotEmpty) ...[
            const DesignerSectionTitle('Portfolio'),
            const SizedBox(height: 4),
            Text(
              'Tap a piece to see its size, measurements and fabric.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: designer.portfolioPieces.length,
              itemBuilder: (context, index) {
                final piece = designer.portfolioPieces[index];
                return GestureDetector(
                  onTap: () => _showPiece(context, piece),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppNetworkImage(
                      piece.imageUrl,
                      fit: BoxFit.cover,
                      fallback: Container(
                        color: colors.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showPiece(BuildContext context, PortfolioPiece piece) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => PortfolioPieceSheet(piece: piece),
    );
  }
}
