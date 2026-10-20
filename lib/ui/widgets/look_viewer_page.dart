// A look opened up from a feed card: the picture full screen, pinch to zoom,
// with its caption underneath.
import 'package:flutter/material.dart';

import 'app_network_image.dart';

Future<void> openLookViewer(
  BuildContext context, {
  required String imageUrl,
  String title = '',
  String caption = '',
}) {
  return Navigator.push(
    context,
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) =>
          LookViewerPage(imageUrl: imageUrl, title: title, caption: caption),
    ),
  );
}

class LookViewerPage extends StatelessWidget {
  const LookViewerPage({
    super.key,
    required this.imageUrl,
    this.title = '',
    this.caption = '',
  });

  final String imageUrl;
  final String title;
  final String caption;

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
