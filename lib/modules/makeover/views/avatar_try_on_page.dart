// Generates a clothing try-on using the signed-in user's saved avatar.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/avatar_try_on_controller.dart';
import 'package:banigoba/modules/makeover/models/try_on_prompt.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_cards.dart';
import 'package:banigoba/modules/makeover/widgets/try_on_panel.dart';

export 'package:banigoba/modules/makeover/models/try_on_prompt.dart'
    show TryOnProvider;

class AvatarTryOnPage extends StatelessWidget {
  const AvatarTryOnPage({
    super.key,
    this.garmentImageUrl,
    this.garmentName,
    this.category,
    this.fitNote = '',
  });

  final String? garmentImageUrl;
  final String? garmentName;
  final String? category;

  /// How the item really fits the shopper (their size and the fit check's
  /// findings), passed to Gemini as an instruction.
  final String fitNote;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters and the route's
    // arguments (the chosen products, a planned date), disposed with it.
    return GetBuilder<AvatarTryOnController>(
      init: AvatarTryOnController(
        garmentImageUrl: garmentImageUrl,
        garmentName: garmentName,
        category: category,
        fitNote: fitNote,
        arguments: ModalRoute.of(context)?.settings.arguments,
      ),
      global: false,
      builder: (controller) => _AvatarTryOnView(controller: controller),
    );
  }
}

class _AvatarTryOnView extends StatelessWidget {
  const _AvatarTryOnView({required this.controller});

  final AvatarTryOnController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Avatar Try-On'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
      ),
      body: Obx(
        () => controller.isLoadingAvatar.value
            ? const Center(child: CircularProgressIndicator())
            : _Content(controller: controller),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.controller});

  final AvatarTryOnController controller;

  @override
  Widget build(BuildContext context) {
    final products = controller.selectedProducts;
    final isMultiProductLook = products.length > 1;
    final clothingImageUrl = products.length == 1
        ? tryOnProductImageUrl(products.first)
        : controller.legacyGarmentImageUrl;
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            controller.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (isMultiProductLook) SelectedOutfitStrip(products: products),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: TryOnImageCard(
                    title: 'Your avatar',
                    imageUrl: controller.avatarImageUrl.value,
                    emptyText: 'Create an avatar first',
                  ),
                ),
                if (!isMultiProductLook) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TryOnImageCard(
                      title: 'Clothing',
                      imageUrl: clothingImageUrl,
                      emptyText: 'Choose clothing to try on',
                    ),
                  ),
                ],
              ],
            ),
          ),
          Obx(
            () => controller.avatarImageUrl.value == null
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: controller.createOrUpdateAvatar,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Create My Avatar'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Obx(() {
            final message = controller.error.value;
            if (message == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }),
          const SizedBox(height: 20),
          _GenerateButton(controller: controller),
          Obx(() {
            final label = controller.generatingLabel.value;
            if (controller.generatingProvider.value == null || label == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Putting on $label',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            );
          }),
          TryOnPanel(controller: controller),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.controller});

  final AvatarTryOnController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final generating =
          controller.generatingProvider.value == TryOnProvider.gemini;
      return ElevatedButton.icon(
        onPressed: controller.canGenerate
            ? controller.generateWithGemini
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: tryOnPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
        ),
        icon: generating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          generating
              ? 'Dressing your avatar...'
              : controller.results.value.containsKey(TryOnProvider.gemini)
              ? 'Try Again'
              : 'See It On Me',
        ),
      );
    });
  }
}
