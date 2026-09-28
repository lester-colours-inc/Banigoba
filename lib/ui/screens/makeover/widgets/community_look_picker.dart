// Style twin: pick a public look from the community to copy onto yourself.
import 'package:flutter/material.dart';

import '../../../../data/models/post.dart';
import '../../../widgets/app_network_image.dart';

/// How many recent public looks the picker offers.
const int kCommunityLookLimit = 30;

/// Returns the image URL of the chosen look, or null when cancelled.
Future<String?> showCommunityLookPicker(
  BuildContext context, {
  required Stream<List<Post>> posts,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _CommunityLookGrid(posts: posts, controller: controller),
    ),
  );
}

class _CommunityLookGrid extends StatelessWidget {
  const _CommunityLookGrid({required this.posts, required this.controller});

  final Stream<List<Post>> posts;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'Pick your style twin',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Choose a look from the community to copy onto yourself.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Post>>(
            stream: posts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Looks could not be loaded.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final looks = snapshot.data!
                  .where((post) => post.isPublic && post.imageURL.isNotEmpty)
                  .take(kCommunityLookLimit)
                  .toList();
              if (looks.isEmpty) {
                return const Center(
                  child: Text('No community looks yet. Try your photos.'),
                );
              }

              return GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: looks.length,
                itemBuilder: (context, index) {
                  final look = looks[index];
                  return InkWell(
                    key: ValueKey('community_look_${look.id}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, look.imageURL),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AppNetworkImage(
                        look.imageURL,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        fallback: ColoredBox(
                          color: colors.surfaceContainerHigh,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
