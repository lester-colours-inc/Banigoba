// What a "your look is ready" notification opens: the person's own photo
// beside the look the server made, with the same slider as the makeover
// screen. The work may have finished while the app was closed, so this page
// needs nothing but the two addresses the notification carries.
import 'package:flutter/material.dart';

import '../screens/makeover/widgets/makeover_controls.dart';
import 'app_network_image.dart';
import 'before_after_view.dart';
import 'look_viewer_page.dart';

/// The two pictures in an `ai_job` notification's extra data, or null when
/// there is no result to show (a job that failed).
({String before, String after})? aiResultOf(Map<String, dynamic>? data) {
  if (data == null || data['status'] == 'failed') return null;
  final after = (data['imageUrl'] ?? '').toString();
  if (after.isEmpty) return null;
  return (before: (data['beforeUrl'] ?? '').toString(), after: after);
}

/// Opens the result of an `ai_job` notification. Returns false when there is
/// nothing to show, so the caller can fall back to the notifications list.
bool openAiResult(NavigatorState navigator, Map<String, dynamic>? data) {
  final result = aiResultOf(data);
  if (result == null) return false;
  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => AiResultPage(
        beforeUrl: result.before,
        afterUrl: result.after,
        title: _titleFor((data?['kind'] ?? '').toString()),
      ),
    ),
  );
  return true;
}

String _titleFor(String kind) => switch (kind) {
  'try_on' => 'Your try-on',
  'turn_around' => 'Your look',
  'makeover' => 'Your makeover',
  _ => 'Your look',
};

class AiResultPage extends StatelessWidget {
  const AiResultPage({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    this.title = 'Your look',
  });

  final String beforeUrl;
  final String afterUrl;
  final String title;

  void _openFull(BuildContext context) =>
      openLookViewer(context, imageUrl: afterUrl, title: title);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasBefore = beforeUrl.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => hasBefore
                      ? BeforeAfterView(
                          key: const ValueKey('ai_result_compare'),
                          beforeImageUrl: beforeUrl,
                          afterImageUrl: afterUrl,
                          aspectRatio:
                              constraints.maxWidth / constraints.maxHeight,
                          borderRadius: 16,
                          fit: BoxFit.contain,
                          background: kMakeoverNavy,
                          onTapAfter: () => _openFull(context),
                        )
                      : GestureDetector(
                          key: const ValueKey('ai_result_only'),
                          onTap: () => _openFull(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ColoredBox(
                              color: kMakeoverNavy,
                              child: AppNetworkImage(
                                afterUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                hasBefore
                    ? 'Drag the slider to compare. Tap your new look to see '
                          'it full screen.'
                    : 'Tap your new look to see it full screen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
