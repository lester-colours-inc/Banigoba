// Generates one step of a makeover (one item: hair, clothes, shoes...) and
// returns it as soon as it exists.
//
// Phase 3 of the work plan: the old coordinated flow ran hair and then each
// garment as separate FASHN calls and showed nothing until all had finished.
// Here every step is a single image call that the user sees straight away,
// and each step builds on the image the user kept from the one before.
//
// The provider sits behind [LookImageGenerator] and is never shown in the UI.
// UNCLEAR: in the meeting someone said Gemini was "just for the demo". If a
// different provider is chosen, add another LookImageGenerator; nothing else
// here needs to change.

import 'package:flutter/foundation.dart';

import '../../core/supabase/app_auth.dart';

import '../models/look_request.dart';
import 'ai_job_service.dart';

/// Turns a photo and an instruction into a new, stored image.
abstract interface class LookImageGenerator {
  bool get isConfigured;

  /// Edits [photoUrl] per [prompt] and returns the address of the result.
  /// [referenceImageUrls] are extra images the prompt refers to (a look to
  /// copy), sent after the photo.
  Future<String> generate({
    required String photoUrl,
    required String prompt,
    List<String> referenceImageUrls = const [],
  });
}

/// Gemini image editing ("Nano Banana"), run on the server so it finishes
/// (and the person is notified) even if the app is closed.
class ServerLookGenerator implements LookImageGenerator {
  ServerLookGenerator({AiImageJobs? jobs})
    : _jobs = jobs ?? SupabaseAiImageJobs();

  final AiImageJobs _jobs;

  @override
  bool get isConfigured => true;

  @override
  Future<String> generate({
    required String photoUrl,
    required String prompt,
    List<String> referenceImageUrls = const [],
  }) async {
    final job = await _jobs.run(
      AiJobRequest(
        kind: AiJobKind.look,
        label: 'Your look',
        steps: [
          AiImageStep(
            prompt: prompt,
            images: [
              AiImageUrl(photoUrl),
              for (final url in referenceImageUrls) AiImageUrl(url),
            ],
          ),
        ],
      ),
    );
    if (job.images.isEmpty) {
      throw const AiJobException('No picture came back. Please try again.');
    }
    return job.images.first;
  }
}

/// A generated look and how long it took, for the speed target in the plan.
@immutable
class GeneratedLook {
  const GeneratedLook({required this.imageUrl, required this.elapsed});

  final String imageUrl;
  final Duration elapsed;
}

/// A failure with a message fit to show the user.
class LookGenerationException implements Exception {
  const LookGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LookGenerationService {
  LookGenerationService({
    LookImageGenerator? generator,
    String Function()? currentUserId,
  }) : _generator = generator ?? ServerLookGenerator(),
       _currentUserId =
           currentUserId ?? (() => AppAuth.instance.currentUser?.uid ?? '');

  final LookImageGenerator _generator;
  final String Function() _currentUserId;

  bool get isConfigured => _generator.isConfigured;

  /// Generates one step of [request]: changes [part] of [baseImageUrl] (the
  /// image the user kept last; the original photo by default).
  ///
  /// [tweak] is the user's own words when they redo or edit a step.
  Future<GeneratedLook> generate(
    LookRequest request, {
    required LookPart part,
    String? baseImageUrl,
    String tweak = '',
  }) async {
    final userId = _currentUserId();
    if (userId.isEmpty) {
      throw const LookGenerationException('Sign in to create a makeover.');
    }
    if (!request.isReady) {
      throw const LookGenerationException(
        'Add a photo and choose how to style it first.',
      );
    }
    if (!_generator.isConfigured) {
      throw const LookGenerationException(
        'Makeovers are not available right now.',
      );
    }

    final stopwatch = Stopwatch()..start();
    final String imageUrl;
    try {
      imageUrl = await _generator.generate(
        photoUrl: baseImageUrl ?? request.photoUrl,
        prompt: buildLookPrompt(request, part: part, tweak: tweak),
        referenceImageUrls: request.referenceImageUrls,
      );
    } on AiJobException catch (error) {
      debugPrint('Look generation failed: $error');
      throw LookGenerationException(
        error.isStillRunning
            ? error.message
            : 'We could not create your look this time. Please try again.',
      );
    } on Exception catch (error) {
      debugPrint('Look generation failed: $error');
      throw const LookGenerationException(
        'We could not create your look this time. Please try again.',
      );
    }
    stopwatch.stop();

    // Measured for the plan's speed target; compare against the old flow.
    debugPrint(
      'Look step ${part.name} generated in ${stopwatch.elapsedMilliseconds} ms',
    );
    return GeneratedLook(imageUrl: imageUrl, elapsed: stopwatch.elapsed);
  }
}
