// My Hair Stylists (October 2026 review, F-3): a setup page, not a makeover
// page. Keep your salons and stylists (My Circle) and the hairstyles you
// like, from your photos or camera. "Try this on me" opens the hair
// makeover with that style; its result goes to the normal feeds (F-4).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:banigoba/modules/makeover/widgets/look_viewer_page.dart';
import 'package:banigoba/modules/social/services/circle_service.dart';
import 'package:banigoba/modules/style_lists/controllers/my_hair_stylists_controller.dart';
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class MyHairStylistsPage extends StatelessWidget {
  const MyHairStylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<MyHairStylistsController>(
      init: MyHairStylistsController(),
      global: false,
      builder: (controller) => _build(context, controller),
    );
  }

  Widget _build(BuildContext context, MyHairStylistsController controller) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Hair Stylists')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Your salons, and the hairstyles you love. Try any of them on '
            'yourself, or send one to your stylist.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('hair_new_style'),
            onPressed: controller.newHairstyle,
            icon: const Icon(Icons.face_retouching_natural),
            label: const Text('Try a new hairstyle'),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'My salons and stylists',
            action: TextButton.icon(
              key: const ValueKey('hair_find_salon'),
              onPressed: controller.findSalon,
              icon: const Icon(Icons.add),
              label: const Text('Find a salon'),
            ),
          ),
          StreamBuilder<List<CircleMember>>(
            stream: controller.members,
            builder: (context, snapshot) {
              final salons = (snapshot.data ?? const <CircleMember>[])
                  .where((member) => member.kind == CircleKind.salon)
                  .toList();
              if (salons.isEmpty) {
                return Text(
                  'None yet. Find your salon so it comes first when you '
                  'send a hairstyle.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                );
              }
              return Column(
                children: [
                  for (final salon in salons)
                    ListTile(
                      key: ValueKey('hair_salon_${salon.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: salon.avatarUrl.isEmpty
                            ? null
                            : CachedNetworkImageProvider(salon.avatarUrl),
                        child: salon.avatarUrl.isEmpty
                            ? const Icon(Icons.content_cut)
                            : null,
                      ),
                      title: Text(salon.name),
                      subtitle: salon.detail.isEmpty
                          ? null
                          : Text(salon.detail),
                      trailing: IconButton(
                        tooltip: 'Remove from My Circle',
                        icon: const Icon(Icons.group_remove_outlined),
                        onPressed: () => controller.removeSalon(salon.id),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Hairstyles I like',
            action: Obx(
              () => PopupMenuButton<ImageSource>(
                key: const ValueKey('hair_add_style'),
                tooltip: 'Add a hairstyle',
                enabled: !controller.uploading.value,
                onSelected: controller.addHairstyle,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ImageSource.gallery,
                    child: Text('From my photos'),
                  ),
                  PopupMenuItem(
                    value: ImageSource.camera,
                    child: Text('Take a photo'),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: controller.uploading.value
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: colors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(color: colors.primary),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          StreamBuilder<List<StyleListEntry>>(
            stream: controller.hairstyles,
            builder: (context, snapshot) {
              final styles = snapshot.data ?? const <StyleListEntry>[];
              if (styles.isEmpty) {
                return Text(
                  'Save hairstyles you see and love, from your photos or the '
                  'camera, then try them on yourself.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                );
              }
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: [
                  for (final style in styles)
                    _HairstyleTile(
                      key: ValueKey('hairstyle_${style.id}'),
                      imageUrl: style.imageUrl,
                      onOpen: () => openLookViewer(
                        context,
                        imageUrl: style.imageUrl,
                        title: 'A hairstyle I like',
                      ),
                      onTryOn: () => controller.tryOnMe(style.imageUrl),
                      onRemove: () => controller.removeHairstyle(style.id),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        action,
      ],
    );
  }
}

class _HairstyleTile extends StatelessWidget {
  const _HairstyleTile({
    super.key,
    required this.imageUrl,
    required this.onOpen,
    required this.onTryOn,
    required this.onRemove,
  });

  final String imageUrl;
  final VoidCallback onOpen;
  final VoidCallback onTryOn;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onOpen,
            child: ColoredBox(
              color: colors.surfaceContainerHigh,
              child: AppNetworkImage(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filledTonal(
              tooltip: 'Remove',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: FilledButton.icon(
              onPressed: onTryOn,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Try this on me'),
            ),
          ),
        ],
      ),
    );
  }
}
