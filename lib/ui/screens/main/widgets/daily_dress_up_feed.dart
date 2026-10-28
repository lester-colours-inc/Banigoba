// The My Daily Dress Up feed on Home: what to wear, drawn from the user's
// Smart Wardrobe. Every look saved from a makeover lands in the wardrobe, so
// it shows up here to wear again.
//
// TODO(daily-dress-up): also feed in Smart Wardrobe AI suggestions and looks
// from the user's chosen Fashion Twins and Fashion Idols (docs/WORK_PLAN.md,
// "Backlog"). Neither exists in the data yet.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/post.dart';
import '../../../../data/services/outfit_service.dart';
import '../../../../data/services/post_service.dart';
import '../../../../data/services/turn_around_service.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/dress_up_post_card.dart';
import '../../../widgets/forward_look_sheet.dart';
import '../../../widgets/share_audience_sheet.dart';
import '../../../widgets/look_viewer_page.dart';
import '../../../../core/app_routes.dart';
import 'friends_dress_ups.dart';
import 'new_from_shops.dart';

class DailyDressUpFeed extends StatefulWidget {
  const DailyDressUpFeed({super.key, required this.emptyBuilder});

  /// Renders the feed's empty, signed-out and error messages, so they match
  /// the other Home feeds.
  final Widget Function(IconData icon, String message) emptyBuilder;

  @override
  State<DailyDressUpFeed> createState() => _DailyDressUpFeedState();
}

class _DailyDressUpFeedState extends State<DailyDressUpFeed> {
  final OutfitService _outfits = OutfitService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _looks = _outfits
      .watchSavedOutfits(_userId);

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return widget.emptyBuilder(
        Icons.lock_outline,
        'Sign in to dress up from your Smart Wardrobe.',
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _looks,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return widget.emptyBuilder(
            Icons.cloud_off_outlined,
            'Your Smart Wardrobe could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final looks =
            snapshot.data!.docs
                .where(
                  (doc) => (doc.data()['imageUrl'] ?? '').toString().isNotEmpty,
                )
                .toList()
              ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
        if (looks.isEmpty) {
          return Column(
            children: [
              NewFromShops(userId: _userId),
              FriendsDressUps(viewerId: _userId),
              widget.emptyBuilder(
                Icons.checkroom_outlined,
                'Set up your Smart Wardrobe to get outfit ideas here every '
                'day: add your clothes and your measurements, and save looks '
                'you love.',
              ),
              const SizedBox(height: 16),
              const SmartWardrobeSetupActions(),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NewFromShops(userId: _userId),
            FriendsDressUps(viewerId: _userId),
            for (var index = 0; index < looks.length; index++) ...[
              _buildLook(looks[index], index),
              if (index != looks.length - 1) const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLook(
    QueryDocumentSnapshot<Map<String, dynamic>> look,
    int index,
  ) {
    final data = look.data();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final name = (data['name'] ?? '').toString().trim();
    final title = name.isEmpty ? 'Saved look' : name;
    final fromPost = (data['sourcePostId'] ?? '').toString().isNotEmpty;

    return DressUpPostCard(
      key: ValueKey('daily_dress_up_${look.id}'),
      isMineLayout: true,
      title: 'Smart Wardrobe',
      subtitle: title,
      detail: fromPost ? 'From My Fashion Makeover' : 'Saved to wardrobe',
      avatarUrl: '',
      timeLabel: _formatDate(_createdAt(look)),
      imageBackground: kLookBackdrops[(index + 2) % kLookBackdrops.length],
      visual: AppNetworkImage(
        imageUrl,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
      ),
      onImageTap: () => openLookViewer(
        context,
        imageUrl: imageUrl,
        title: title,
        turnViews: parseTurnViews(data['turnViews'], frontUrl: imageUrl),
      ),
      actions: [
        DressUpCardAction(
          icon: Icons.event_available_outlined,
          chipLabel: 'Wear today',
          label: 'Wear today',
          onTap: () => _wearToday(look),
        ),
        // Post it as today's dress-up for friends or everyone (D-2, P-4).
        DressUpCardAction(
          icon: Icons.send_outlined,
          label: "Post as today's dress-up",
          onTap: () => _postDressUp(look.id, imageUrl, title),
        ),
      ],
      trailingAction: DressUpCardAction(
        icon: Icons.share_outlined,
        label: kSendToLabel,
        onTap: () =>
            showForwardLookSheet(context, imageUrl: imageUrl, caption: title),
      ),
    );
  }

  Future<void> _postDressUp(
    String outfitId,
    String imageUrl,
    String title,
  ) async {
    final audience = await showShareAudienceSheet(
      context,
      title: "Post today's dress-up",
    );
    if (audience == null || audience == PostVisibility.private || !mounted) {
      return;
    }
    await _shareDressUp(outfitId, imageUrl, title, audience);
  }

  Future<void> _shareDressUp(
    String outfitId,
    String imageUrl,
    String title,
    PostVisibility audience,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await PostService().createPost(
        caption: title,
        imageURL: imageUrl,
        outfitId: outfitId,
        visibility: audience,
        kind: PostKind.dressUp,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (audience) {
            PostVisibility.friends =>
              "Posted for your friends as today's dress-up.",
            PostVisibility.followers =>
              "Posted for your followers as today's dress-up.",
            _ => "Posted for everyone as today's dress-up.",
          }),
        ),
      );
    } on SignInRequiredException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to share your dress-up.')),
      );
    } on FirebaseException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to share: ${error.message}')),
      );
    }
  }

  Future<void> _wearToday(
    QueryDocumentSnapshot<Map<String, dynamic>> look,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _outfits.reuseOutfitOnDate(
        userId: _userId,
        outfitId: look.id,
        date: DateTime.now(),
        outfit: look.data(),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Added to today in your wardrobe.')),
      );
    } on Exception catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to plan this look: $error')),
      );
    }
  }

  static DateTime _createdAt(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()['createdAt'];
    return value is Timestamp ? value.toDate() : DateTime(2000);
  }

  static String _formatDate(DateTime date) =>
      date.year == 2000 ? '' : '${date.day}/${date.month}/${date.year}';
}

/// The two first steps of setting up the Smart Wardrobe, shown when it is
/// still empty (October 2026 review, D-3).
class SmartWardrobeSetupActions extends StatelessWidget {
  const SmartWardrobeSetupActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          key: const ValueKey('setup_smart_wardrobe'),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.wardrobe),
          icon: const Icon(Icons.checkroom_outlined),
          label: const Text('Set up my Smart Wardrobe'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('setup_measurements'),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.bodyProfile),
          icon: const Icon(Icons.straighten),
          label: const Text('Add my measurements'),
        ),
      ],
    );
  }
}
