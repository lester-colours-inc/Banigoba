// Repost and Quote for a look in the Home feeds, the way X does them: a
// repost passes someone's look on to your own audience unchanged; a quote
// adds your own words above it. Either way the original author is told.
import 'package:flutter/material.dart';

import '../../data/models/post.dart';
import '../../data/services/post_service.dart';
import 'share_audience_sheet.dart';

const int _maxQuoteLength = 280;

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

/// Asks for the user's words on [post], then who should see the quote.
Future<void> quoteLook(
  BuildContext context,
  Post post, {
  PostService? posts,
}) async {
  final quote = await showDialog<String>(
    context: context,
    builder: (_) => const _QuoteDialog(),
  );
  if (quote == null || quote.trim().isEmpty || !context.mounted) return;
  final audience = await showShareAudienceSheet(context, title: 'Quote to');
  if (audience == null || !context.mounted) return;
  await _send(
    context,
    () =>
        (posts ?? PostService()).repost(post, quote: quote, audience: audience),
    done: 'Quote posted.',
  );
}

Future<void> _send(
  BuildContext context,
  Future<void> Function() action, {
  required String done,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  } on SignInRequiredException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } on Exception catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Unable to repost this look: $error')),
    );
  }
}

class _QuoteDialog extends StatefulWidget {
  const _QuoteDialog();

  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quote this look'),
      content: TextField(
        key: const ValueKey('quote_field'),
        controller: _controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: _maxQuoteLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Add your thoughts',
          border: OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text),
          child: const Text('Next'),
        ),
      ],
    );
  }
}
