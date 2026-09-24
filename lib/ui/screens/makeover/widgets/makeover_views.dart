// Presentational pieces of the Makeover page: the photo card, the progress
// view while a look is generated, and the result with its actions.
import 'package:flutter/material.dart';

import '../../../widgets/before_after_view.dart';

/// Shows the user's photo first, with ways to replace it.
class MakeoverPhotoCard extends StatelessWidget {
  const MakeoverPhotoCard({
    super.key,
    required this.photoUrl,
    required this.isLoading,
    required this.onUpload,
    required this.onTakePhoto,
  });

  final String photoUrl;
  final bool isLoading;
  final VoidCallback? onUpload;
  final VoidCallback? onTakePhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Widget preview;
    if (isLoading) {
      preview = const Center(child: CircularProgressIndicator());
    } else if (photoUrl.isEmpty) {
      // Scales down rather than overflowing with large system text sizes.
      preview = Padding(
        padding: const EdgeInsets.all(10),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 40, color: colors.outline),
              const SizedBox(height: 6),
              Text(
                'Add a\nfull-length\nphoto',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    } else {
      preview = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, color: colors.outline),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 120,
            height: 160,
            color: colors.surfaceContainerLow,
            child: preview,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('makeover_upload_photo'),
                onPressed: onUpload,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Upload'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('makeover_take_photo'),
                onPressed: onTakePhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take a photo'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown while one look is being generated, with a running timer so the wait
/// is visible and can be measured.
class MakeoverGeneratingView extends StatelessWidget {
  const MakeoverGeneratingView({
    super.key,
    required this.photoUrl,
    required this.elapsedSeconds,
  });

  final String photoUrl;
  final int elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 293,
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      color: Colors.black.withValues(alpha: 0.35),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Creating your look...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            // UNCLEAR: the seconds counter helps measure the plan's speed
            // target. Decide whether users should keep seeing it.
            Text('${elapsedSeconds}s'),
          ],
        ),
      ),
    );
  }
}

/// The finished look, compared with the original photo.
class MakeoverResultView extends StatelessWidget {
  const MakeoverResultView({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    required this.onTryAnother,
    required this.onChangeIdea,
    required this.onSave,
    this.errorMessage = '',
  });

  final String beforeUrl;
  final String afterUrl;
  final VoidCallback onTryAnother;
  final VoidCallback onChangeIdea;
  final VoidCallback onSave;
  final String errorMessage;

  static const Color _navy = Color(0xFF0D0140);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        BeforeAfterView(beforeImageUrl: beforeUrl, afterImageUrl: afterUrl),
        if (errorMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          MakeoverErrorBanner(message: errorMessage),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('makeover_save'),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: onSave,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Save this look'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('makeover_try_another'),
                onPressed: onTryAnother,
                icon: const Icon(Icons.refresh),
                label: const Text('Try another'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('makeover_change_idea'),
                onPressed: onChangeIdea,
                icon: const Icon(Icons.tune),
                label: const Text('Change idea'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MakeoverErrorBanner extends StatelessWidget {
  const MakeoverErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
