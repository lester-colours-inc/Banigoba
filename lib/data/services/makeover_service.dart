import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/app_auth.dart';
import '../../core/supabase/supabase_config.dart';
import '../supabase/storage_files.dart';

class MakeoverService {
  /// Uploads the user's original full-body selfie or photo for AI processing.
  Future<String> uploadInputImage(File file, String userId) async {
    try {
      return await StorageFiles.upload(
        bucket: Buckets.aiMakeovers,
        path: '$userId/${randomFileName()}',
        bytes: await file.readAsBytes(),
      );
    } on Object catch (error) {
      throw Exception('Failed to upload makeover input image: $error');
    }
  }

  /// Calls the generate-makeover function to produce makeover result URLs.
  Future<List<String>> generateMakeover({
    required String userId,
    required String style,
    required String imageUrl,
  }) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }
    if (user.uid != userId) {
      throw Exception('The requested user does not match the signed-in user.');
    }

    try {
      final result = await supabase.functions.invoke(
        'generate-makeover',
        body: {'style': style, 'imageUrl': imageUrl},
      );
      final data = result.data;
      final urls = data is Map ? data['generatedImageUrls'] : null;
      if (urls is List) {
        return urls.map((item) => item.toString()).toList();
      }

      throw Exception('Unexpected response from makeover function.');
    } on FunctionException catch (error) {
      throw Exception(
        error.reasonPhrase ?? 'Makeover generation failed (${error.status}).',
      );
    }
  }

  /// Saves the generated makeover result.
  Future<void> saveGeneratedMakeover({
    required String userId,
    required String style,
    required List<String> generatedImageUrls,
    required String sourceImageUrl,
  }) async {
    await supabase.from('ai_makeovers').insert({
      'user_id': userId,
      'style': style,
      'source_image_url': sourceImageUrl,
      'generated_image_urls': generatedImageUrls,
    });
  }
}
