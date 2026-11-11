// Generates, displays, and saves the completed AI-styled look.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/styled_look_controller.dart';
import 'package:banigoba/modules/shop/widgets/cart_badge_button.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class StyledLookPage extends StatelessWidget {
  const StyledLookPage({
    super.key,
    required this.style,
    required this.sourceImageUrl,
    required this.generatedImageUrls,
  });

  final String style;
  final String sourceImageUrl;
  final List<String> generatedImageUrls;

  static Color primaryColor = const Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters, disposed with it.
    return GetBuilder<StyledLookController>(
      init: StyledLookController(
        style: style,
        sourceImageUrl: sourceImageUrl,
        generatedImageUrls: generatedImageUrls,
      ),
      global: false,
      builder: (controller) => _StyledLookView(controller: controller),
    );
  }
}

class _StyledLookView extends StatelessWidget {
  const _StyledLookView({required this.controller});

  final StyledLookController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: colors.onSurface),
          onPressed: () {},
        ),
        title: Text(
          'Your Styled Look',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          CartBadgeButton(
            onPressed: controller.openCart,
            color: colors.onSurface,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: colors.onSurface,
              ),
              onPressed: Get.back,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _MainLookCard(imageUrl: controller.mainImageUrl),
            const SizedBox(height: 25),
            Row(
              children: controller.generatedImageUrls
                  .take(3)
                  .map(
                    (url) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _SmallImageCard(imageUrl: url),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 40),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveLook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StyledLookPage.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save to Wardrobe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: Get.back,
              child: const Text(
                'Try Another Style',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainLookCard extends StatelessWidget {
  const _MainLookCard({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 450,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: AppNetworkImage(
          imageUrl,
          fit: BoxFit.cover,
          fallback: const Center(
            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _SmallImageCard extends StatelessWidget {
  const _SmallImageCard({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: AppNetworkImage(
          imageUrl,
          fit: BoxFit.cover,
          fallback: const Center(
            child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
