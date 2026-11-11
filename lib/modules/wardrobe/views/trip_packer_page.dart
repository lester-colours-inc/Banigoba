// Builds packing checklists from the garments in selected saved outfits.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/wardrobe/controllers/trip_packer_controller.dart';
import 'package:banigoba/modules/wardrobe/models/packing_outfit.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class TripPackerPage extends GetView<TripPackerController> {
  const TripPackerPage({super.key});

  static const _primaryColor = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Packer')),
      body: !controller.isSignedIn
          ? const Center(child: Text('Sign in to create a packing list.'))
          : Obx(() {
              final outfits = controller.outfits.value;
              if (outfits == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (outfits.isEmpty) {
                return const Center(
                  child: Text('Save outfits first to build a packing list.'),
                );
              }
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Select outfits. Every garment name will become a packing checklist item.',
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: outfits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _OutfitTile(outfit: outfits[index]),
                    ),
                  ),
                  const _CreateListButton(),
                ],
              );
            }),
    );
  }
}

class _OutfitTile extends GetView<TripPackerController> {
  const _OutfitTile({required this.outfit});

  final PackingOutfit outfit;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CheckboxListTile(
        value: controller.selectedIds.contains(outfit.id),
        onChanged: (_) => controller.toggle(outfit.id),
        secondary: SizedBox(
          width: 58,
          child: outfit.imageUrl.isEmpty
              ? const Icon(Icons.checkroom_outlined)
              : AppNetworkImage(
                  outfit.imageUrl,
                  fit: BoxFit.contain,
                  fallback: const Icon(Icons.checkroom_outlined),
                ),
        ),
        title: Text(outfit.name),
        subtitle: Text(outfit.itemNames.join(', ')),
      ),
    );
  }
}

class _CreateListButton extends GetView<TripPackerController> {
  const _CreateListButton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => FilledButton.icon(
            onPressed:
                controller.selectedIds.isEmpty || controller.isSaving.value
                ? null
                : controller.saveList,
            style: FilledButton.styleFrom(
              backgroundColor: TripPackerPage._primaryColor,
              minimumSize: const Size(double.infinity, 54),
            ),
            icon: const Icon(Icons.luggage),
            label: Text(
              controller.isSaving.value
                  ? 'Creating list...'
                  : 'Create Packing List',
            ),
          ),
        ),
      ),
    );
  }
}
