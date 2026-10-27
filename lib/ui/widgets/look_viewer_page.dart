// A look opened up from a feed card: the picture full screen, pinch to zoom,
// with its caption underneath. A look that was turned around when it was
// saved opens in the turn-around viewer instead: drag to see every angle.
import 'package:flutter/material.dart';

import '../../data/services/turn_around_service.dart';
import 'app_network_image.dart';
import 'turn_around_viewer.dart';

Future<void> openLookViewer(
  BuildContext context, {
  required String imageUrl,
  String title = '',
  String caption = '',
  Map<TurnView, String> turnViews = const {},
}) {
  return Navigator.push(
    context,
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LookViewerPage(
        imageUrl: imageUrl,
        title: title,
        caption: caption,
        turnViews: turnViews,
      ),
    ),
  );
}

class LookViewerPage extends StatelessWidget {
  const LookViewerPage({
    super.key,
    required this.imageUrl,
    this.title = '',
    this.caption = '',
    this.turnViews = const {},
  });

  final String imageUrl;
  final String title;
  final String caption;

  /// The saved angles, front included. More than one turns the look.
  final Map<TurnView, String> turnViews;

  bool get _turns => turnViews.length > 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_turns)
              Expanded(
                child: Theme(
                  data: ThemeData.dark(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TurnAroundViewer(
                      key: const ValueKey('look_viewer_turn'),
                      views: turnViews,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                            size: 48,
                          )
                        : AppNetworkImage(
                            imageUrl,
                            key: const ValueKey('look_viewer_image'),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                  ),
                ),
              ),
            if (caption.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Text(
                  caption.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
