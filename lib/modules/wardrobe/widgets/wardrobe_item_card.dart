// One piece in My Clothes: picture, name, who it is from, and wear status.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/wardrobe/controllers/wardrobe_controller.dart';
import 'package:banigoba/modules/wardrobe/models/wardrobe_collections.dart';
import 'package:banigoba/modules/wardrobe/models/wear_tracking.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

const Color _primary = Color(0xFF0D0140);

/// Draws the eye to pieces that have gone unworn a long time.
const Color _nudgeColor = Color(0xFFD9822B);

class WardrobeItemCard extends StatelessWidget {
  const WardrobeItemCard({
    super.key,
    required this.controller,
    required this.data,
  });

  final WardrobeController controller;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = data['imageUrl'] ?? data['imageURL'] ?? '';
    final rawImageUrl = data['rawImageUrl'] ?? imageUrl;

    final String? originalProductId = data['originalProductId'];
    final String? originalPosterId = data['originalPosterId'];
    final String? uploaderId = data['userId'];

    // Only attribute to a user if it was an original upload or saved from a user
    final String? posterId = originalProductId != null
        ? originalPosterId
        : uploaderId;

    return GestureDetector(
      onTap: () => controller.openProduct(data),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: rawImageUrl.isNotEmpty
                    ? AppNetworkImage(
                        rawImageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Container(
                        color: colors.surfaceContainerHighest,
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'No Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Display original poster name if not admin
                  if (posterId != null)
                    _PosterLine(
                      posterId: posterId,
                      currentUserId: controller.userId,
                      data: data,
                    )
                  else
                    _ColourSubtitle(data: data),
                  if (uploaderId == controller.userId)
                    _WearRow(controller: controller, data: data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterLine extends StatelessWidget {
  const _PosterLine({
    required this.posterId,
    required this.currentUserId,
    required this.data,
  });

  final String posterId;
  final String currentUserId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ProfileService().watch(posterId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final userData = snapshot.data!;
        final bool isAdmin =
            userData['role'] == 'admin' || userData['isAdmin'] == true;
        if (isAdmin) {
          // For admin items, show colors or nothing extra
          return _ColourSubtitle(data: data);
        }
        final posterName = userData['displayName'] ?? 'User';
        return Text(
          posterId == currentUserId ? 'by you' : 'by $posterName',
          style: TextStyle(
            color: _primary.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// "Worn 3 weeks ago" / "Not worn in 10 months", and a tap to record
/// wearing it today (W-7).
class _WearRow extends StatelessWidget {
  const _WearRow({required this.controller, required this.data});

  final WardrobeController controller;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = wearStatus(
      lastWorn: timestampToDate(data['lastWornAt']),
      addedAt: timestampToDate(data['createdAt']),
      now: DateTime.now(),
    );
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            status.label,
            key: ValueKey('wear_status_${data['id']}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: status.isNudge ? FontWeight.w700 : FontWeight.w500,
              color: status.isNudge ? _nudgeColor : colors.onSurfaceVariant,
            ),
          ),
        ),
        IconButton(
          key: ValueKey('collection_move_${data['id']}'),
          tooltip: collectionOf(data).isEmpty
              ? 'Add to a collection'
              : 'In ${collectionOf(data)}. Tap to change',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          onPressed: () => controller.moveToCollection(data),
          icon: Icon(
            collectionOf(data).isEmpty ? Icons.folder_outlined : Icons.folder,
          ),
        ),
        IconButton(
          key: ValueKey('wore_today_${data['id']}'),
          tooltip: 'I wore this today',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          onPressed: status.label == 'Worn today'
              ? null
              : () => controller.markWorn(data['id'].toString()),
          icon: const Icon(Icons.check_circle_outline),
        ),
      ],
    );
  }
}

/// The colour line for a product card.
class _ColourSubtitle extends StatelessWidget {
  const _ColourSubtitle({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final dynamic rawColours = data['colours'] ?? data['colour'];
    List<dynamic> coloursList = [];
    if (rawColours is List) {
      coloursList = rawColours;
    } else if (rawColours != null && rawColours.toString().isNotEmpty) {
      coloursList = [rawColours];
    }

    String colourText = 'Various';
    if (coloursList.isNotEmpty) {
      final first = coloursList[0].toString().trim();
      if (first.isNotEmpty) {
        colourText = first[0].toUpperCase() + first.substring(1).toLowerCase();
        if (coloursList.length > 1) colourText += ' +${coloursList.length - 1}';
      }
    }
    return Text(
      colourText,
      style: TextStyle(
        color: Theme.of(context).colorScheme.outline,
        fontSize: 11,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
