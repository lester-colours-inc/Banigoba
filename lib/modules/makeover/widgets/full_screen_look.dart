// A generated look shown full screen, pinch to zoom.
import 'package:flutter/material.dart';

import 'package:banigoba/shared/widgets/app_network_image.dart';

class FullScreenLook extends StatelessWidget {
  const FullScreenLook({
    super.key,
    required this.title,
    required this.imageUrl,
  });

  final String title;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 4,
          child: AppNetworkImage(
            imageUrl,
            fit: BoxFit.contain,
            fallback: const Text(
              'Unable to display this look.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
