// Quoting a look, laid out like X's quote composer: close and Post along the
// top, your avatar beside "Add a comment…", the quoted look as a card below,
// and who can see it plus a character ring along the bottom.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/controllers/quote_controller.dart';
import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/widgets/quoted_look_card.dart';
import 'package:banigoba/modules/social/widgets/share_audience_sheet.dart';

/// What the composer hands back when the user taps Post.
typedef QuoteDraft = ({String text, PostVisibility audience});

/// Opens the composer full screen. Returns null when it is closed.
Future<QuoteDraft?> showQuoteComposer(
  BuildContext context, {
  required QuotedLookPreview preview,
  PostVisibility audience = PostVisibility.public,
  Future<String>? myAvatarUrl,
  int maxLength = 280,
}) {
  return Navigator.of(context).push<QuoteDraft>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => QuoteComposerPage(
        preview: preview,
        audience: audience,
        myAvatarUrl: myAvatarUrl,
        maxLength: maxLength,
      ),
    ),
  );
}

class QuoteComposerPage extends StatelessWidget {
  const QuoteComposerPage({
    super.key,
    required this.preview,
    this.audience = PostVisibility.public,
    this.myAvatarUrl,
    this.maxLength = 280,
  });

  final QuotedLookPreview preview;
  final PostVisibility audience;
  final Future<String>? myAvatarUrl;
  final int maxLength;

  // Space the avatar takes, so the quoted card lines up under the text.
  static const double _avatarRadius = 22;
  static const double _gutter = 12;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with it.
    return GetBuilder<QuoteController>(
      init: QuoteController(maxLength: maxLength, audience: audience),
      global: false,
      builder: (controller) => Scaffold(
        key: const ValueKey('quote_composer'),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(controller: controller),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MyAvatar(url: myAvatarUrl, radius: _avatarRadius),
                        const SizedBox(width: _gutter),
                        Expanded(child: _CommentField(controller: controller)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: _avatarRadius * 2 + _gutter,
                      ),
                      child: QuotedLookCard(preview: preview),
                    ),
                  ],
                ),
              ),
              _BottomBar(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final QuoteController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('quote_close'),
            tooltip: 'Close',
            icon: const Icon(Icons.close, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Obx(
            () => FilledButton(
              key: const ValueKey('quote_post'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                minimumSize: const Size(0, 40),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                disabledBackgroundColor: colors.primary.withValues(alpha: 0.4),
                disabledForegroundColor: colors.onPrimary.withValues(
                  alpha: 0.7,
                ),
              ),
              onPressed: controller.canPost
                  ? () => Navigator.pop<QuoteDraft>(context, (
                      text: controller.text.text.trim(),
                      audience: controller.audience.value,
                    ))
                  : null,
              child: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller});

  final QuoteController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      key: const ValueKey('quote_field'),
      controller: controller.text,
      autofocus: true,
      minLines: 1,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [LengthLimitingTextInputFormatter(controller.maxLength)],
      style: const TextStyle(fontSize: 20, height: 1.3),
      decoration: InputDecoration(
        hintText: 'Add a comment…',
        hintStyle: TextStyle(fontSize: 20, color: colors.onSurfaceVariant),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.only(top: 8),
      ),
      onChanged: (value) => controller.typed.value = value,
    );
  }
}

class _MyAvatar extends StatelessWidget {
  const _MyAvatar({required this.url, required this.radius});

  final Future<String>? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<String>(
      future: url,
      builder: (context, snapshot) {
        final image = snapshot.data ?? '';
        return CircleAvatar(
          radius: radius,
          backgroundColor: colors.surfaceContainerHigh,
          backgroundImage: image.isEmpty
              ? null
              : CachedNetworkImageProvider(image),
          child: image.isEmpty
              ? Icon(Icons.person, color: colors.onSurfaceVariant)
              : null,
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});

  final QuoteController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final divider = Divider(height: 1, color: colors.outlineVariant);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        divider,
        Obx(() {
          final audience = controller.audience.value;
          return InkWell(
            key: const ValueKey('quote_audience'),
            onTap: () async => controller.chooseAudience(
              await showShareAudienceSheet(context, title: 'Who can see this'),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(_audienceIcon(audience), color: colors.primary),
                  const SizedBox(width: 16),
                  Text(
                    _audienceLabel(audience),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        divider,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_CharacterRing(controller: controller)],
          ),
        ),
      ],
    );
  }

  static IconData _audienceIcon(PostVisibility audience) => switch (audience) {
    PostVisibility.public => Icons.public,
    PostVisibility.followers => Icons.group_outlined,
    PostVisibility.friends => Icons.people_alt_outlined,
    PostVisibility.private => Icons.lock_outline,
  };

  static String _audienceLabel(PostVisibility audience) => switch (audience) {
    PostVisibility.public => 'Everyone can see this',
    PostVisibility.followers => 'Your followers can see this',
    PostVisibility.friends => 'Your friends can see this',
    PostVisibility.private => 'Only you can see this',
  };
}

/// X's counter: a ring that fills as you type, showing what's left near the
/// end and turning red at the limit.
class _CharacterRing extends StatelessWidget {
  const _CharacterRing({required this.controller});

  final QuoteController controller;

  static const int _warnAt = 20;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final remaining = controller.remaining;
      final isNearLimit = remaining <= _warnAt;
      final ringColor = remaining <= 0
          ? colors.error
          : isNearLimit
          ? Colors.amber.shade700
          : colors.primary;
      return SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: controller.used,
              strokeWidth: 2.5,
              color: ringColor,
              backgroundColor: colors.outlineVariant,
            ),
            if (isNearLimit)
              Text(
                '$remaining',
                style: TextStyle(fontSize: 11, color: ringColor),
              ),
          ],
        ),
      );
    });
  }
}
