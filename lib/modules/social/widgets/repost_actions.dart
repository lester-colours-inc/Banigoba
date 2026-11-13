// Repost and Quote for a look in the Home feeds, the way X does them: a
// repost passes someone's look on to your own audience unchanged; a quote
// adds your own words above it. Either way the original author is told.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/social/models/post.dart';
import 'package:banigoba/modules/social/services/post_service.dart';
import 'package:banigoba/modules/social/views/quote_composer_page.dart';
import 'package:banigoba/modules/social/widgets/quoted_look_card.dart';
import 'package:banigoba/modules/social/widgets/share_audience_sheet.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

const int _maxQuoteLength = 280;

/// Repost and Quote are always offered (October 2026 review, P-8). Only a
/// shared look can be passed on, so on a private one this asks the owner to
/// share it first. Returns true when [post] is shared and the action can go
/// on.
Future<bool> ensureLookShared(
  BuildContext context,
  Post post, {
  required Future<void> Function(PostVisibility audience) share,
}) async {
  if (post.isShared) return true;
  final shareFirst = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('share_first_dialog'),
      title: const Text('Share this look first?'),
      content: const Text(
        'This look is private. Share it with friends, followers or everyone, '
        'then you can repost or quote it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          key: const ValueKey('share_first_confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Share'),
        ),
      ],
    ),
  );
  if (shareFirst != true || !context.mounted) return false;
  final audience = await showShareAudienceSheet(context);
  if (audience == null || audience == PostVisibility.private) return false;
  await share(audience);
  return true;
}

/// Reposts [post] after asking who should see it.
Future<void> repostLook(
  BuildContext context,
  Post post, {
  PostService? posts,
}) async {
  final audience = await showShareAudienceSheet(context, title: 'Repost to');
  if (audience == null || !context.mounted) return;
  await _send(
    context,
    () => (posts ?? PostService()).repost(post, audience: audience),
    done: 'Reposted.',
  );
}

/// Opens the X-style quote composer on [post] and posts the quote with the
/// words and audience chosen there. [preview] is what the composer shows of
/// the quoted look; without it the post's own caption and picture are used.
Future<void> quoteLook(
  BuildContext context,
  Post post, {
  PostService? posts,
  QuotedLookPreview? preview,
  Future<String>? myAvatarUrl,
}) async {
  final draft = await showQuoteComposer(
    context,
    preview:
        preview ??
        QuotedLookPreview(
          authorName: 'Look',
          timeLabel: '',
          text: post.isQuote ? post.quoteText : post.caption,
          imageUrl: post.imageURL,
        ),
    audience: post.isShared ? post.visibility : PostVisibility.public,
    myAvatarUrl: myAvatarUrl,
    maxLength: _maxQuoteLength,
  );
  if (draft == null || draft.text.isEmpty || !context.mounted) return;
  await _send(
    context,
    () => (posts ?? PostService()).repost(
      post,
      quote: draft.text,
      audience: draft.audience,
    ),
    done: 'Quote posted.',
  );
}

Future<void> _send(
  BuildContext context,
  Future<void> Function() action, {
  required String done,
}) async {
  try {
    await action();
    AppToast.say(done);
  } on SignInRequiredException catch (error) {
    AppToast.say(error.message);
  } on Exception catch (error) {
    AppToast.say('Unable to repost this look: $error');
  }
}
