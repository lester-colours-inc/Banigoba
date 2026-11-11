// Lets users choose styling options and adds optional weather context to the makeover.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/style_selection_controller.dart';
import 'package:banigoba/modules/makeover/widgets/style_selection_parts.dart';

class StyleSelectionPage extends StatelessWidget {
  const StyleSelectionPage({
    super.key,
    this.imageBytes,
    this.imageUrl,
    this.plannedDate,
    this.eventId,
    this.eventName,
  }) : assert(
         imageBytes != null || imageUrl != null,
         'Either imageBytes or imageUrl must be provided.',
       );

  final Uint8List? imageBytes;
  final String? imageUrl;
  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;

  static Color primaryColor = styleSelectionPrimary;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters, disposed with it.
    return GetBuilder<StyleSelectionController>(
      init: StyleSelectionController(
        imageBytes: imageBytes,
        imageUrl: imageUrl,
        plannedDate: plannedDate,
        eventId: eventId,
        eventName: eventName,
      ),
      global: false,
      builder: (controller) => _StyleSelectionView(controller: controller),
    );
  }
}

class _StyleSelectionView extends StatelessWidget {
  const _StyleSelectionView({required this.controller});

  final StyleSelectionController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: Get.back,
          icon: Icon(Icons.chevron_left_rounded, color: colors.onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            StyleHeroCard(controller: controller),
            const SizedBox(height: 20),
            StyleInfoRow(controller: controller),
            const SizedBox(height: 20),
            StyleActionButtons(controller: controller),
            const SizedBox(height: 25),
            const StyleSectionTile(
              icon: Icons.lightbulb_outline,
              title: 'Trending Styles',
              subtitle: 'Discover your global style icon twin',
            ),
            const SizedBox(height: 12),
            const StyleSectionTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Designer Pick',
              subtitle: 'Discover your global style icon twin',
            ),
            const SizedBox(height: 12),
            const StyleSectionTile(
              icon: Icons.storefront_outlined,
              title: 'My Closet',
              subtitle: 'Discover your global style icon twin',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
