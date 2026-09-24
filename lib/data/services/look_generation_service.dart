// Generates one makeover look at a time and returns it as soon as it exists.
//
// Phase 3 of the work plan: the old coordinated flow ran hair and then each
// garment as separate FASHN calls and showed nothing until all had finished.
// This service makes a single image call per look, so the first result shows
// as fast as the provider allows, and "Try another" is just another call.
//
// The provider sits behind [LookImageGenerator] and is never shown in the UI.
// UNCLEAR: in the meeting someone said Gemini was "just for the demo". If a
// different provider is chosen, add another LookImageGenerator; nothing else
// here needs to change.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/look_request.dart';
import 'gemini_image_api.dart';
import 'storage_service.dart';

/// Turns a photo and an instruction into a new image.
abstract interface class LookImageGenerator {
  bool get isConfigured;

  Future<Uint8List> generate({
    required String photoUrl,
    required String prompt,
  });
}

/// Gemini image editing ("Nano Banana").
class GeminiLookGenerator implements LookImageGenerator {
  GeminiLookGenerator({String? apiKey}) : _apiKey = apiKey ?? _compiledKey;

  static const String _compiledKey = String.fromEnvironment('GEMINI_API_KEY');

  final String _apiKey;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<Uint8List> generate({
    required String photoUrl,
    required String prompt,
  }) async {
    final photo = await GeminiImageApi.fetchImage(photoUrl);
    final result = await GeminiImageApi(
      apiKey: _apiKey,
    ).editImage(images: [photo], prompt: prompt);
    return result.bytes;
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

typedef LookUploader = Future<String> Function(Uint8List bytes, String userId);

class LookGenerationService {
  LookGenerationService({
    LookImageGenerator? generator,
    LookUploader? upload,
    String Function()? currentUserId,
  }) : _generator = generator ?? GeminiLookGenerator(),
       _upload = upload ?? StorageService().uploadTryOnResultBytes,
       _currentUserId =
           currentUserId ??
           (() => FirebaseAuth.instance.currentUser?.uid ?? '');

  final LookImageGenerator _generator;
  final LookUploader _upload;
  final String Function() _currentUserId;

  bool get isConfigured => _generator.isConfigured;

  /// Generates exactly one look for [request].
  Future<GeneratedLook> generate(LookRequest request) async {
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
        'Makeovers are not set up on this build. Start the app with '
        '--dart-define-from-file=dart_defines.json',
      );
    }

    final stopwatch = Stopwatch()..start();
    final Uint8List bytes;
    try {
      bytes = await _generator.generate(
        photoUrl: request.photoUrl,
        prompt: buildLookPrompt(request),
      );
    } on Exception catch (error) {
      debugPrint('Look generation failed: $error');
      throw const LookGenerationException(
        'We could not create your look this time. Please try again.',
      );
    }

    final String imageUrl;
    try {
      imageUrl = await _upload(bytes, userId);
    } on Exception catch (error) {
      debugPrint('Look upload failed: $error');
      throw const LookGenerationException(
        'Your look was created but could not be saved. Please try again.',
      );
    }
    stopwatch.stop();

    // Measured for the plan's speed target; compare against the old flow.
    debugPrint('Look generated in ${stopwatch.elapsedMilliseconds} ms');
    return GeneratedLook(imageUrl: imageUrl, elapsed: stopwatch.elapsed);
  }
}
