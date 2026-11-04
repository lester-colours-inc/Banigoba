// Generates, stores, and retrieves hairstyle makeover results.
import 'dart:typed_data';

import '../../core/supabase/supabase_config.dart';
import '../models/affirmation.dart';
import '../models/post.dart';
import '../models/text_moderation.dart';
import '../supabase/rows.dart';
import '../supabase/storage_files.dart';
import 'affirmation_service.dart';

class HairstyleService {
  static const String _selfieKind = 'hairSelfie';
  static const String _selfieId = 'latest';

  Future<String> saveLatestSelfie({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    final imageUrl = await StorageFiles.upload(
      bucket: Buckets.userImages,
      path: '$userId/hairStyles/selfies/${randomFileName()}',
      bytes: imageBytes,
    );
    final existing = await supabase
        .from('user_documents')
        .select('data')
        .eq('user_id', userId)
        .eq('kind', _selfieKind)
        .eq('id', _selfieId)
        .maybeSingle();
    final urls = [
      ...((existing?['data'] as Map?)?['hairStyleSelfieUrls'] as List? ??
          const []),
      imageUrl,
    ];
    await supabase.from('user_documents').upsert({
      'user_id': userId,
      'kind': _selfieKind,
      'id': _selfieId,
      'data': {
        'latestHairStyleSelfieUrl': imageUrl,
        'hairStyleSelfieUrls': urls,
        'hairStyleSelfieUploadedAt': DateTime.now().toUtc().toIso8601String(),
      },
    });
    return imageUrl;
  }

  Future<String?> getLatestSelfieUrl(String userId) async {
    final row = await supabase
        .from('user_documents')
        .select('data')
        .eq('user_id', userId)
        .eq('kind', _selfieKind)
        .eq('id', _selfieId)
        .maybeSingle();
    final value = (row?['data'] as Map?)?['latestHairStyleSelfieUrl'];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  Future<Uint8List> downloadSelfie(String imageUrl) async {
    final bytes = await StorageFiles.download(imageUrl);
    if (bytes == null || bytes.isEmpty) {
      throw Exception('The saved hairstyle selfie is empty.');
    }
    return bytes;
  }

  Future<void> saveLook({
    required String userId,
    required String styleName,
    required String prompt,
    required String styleReferenceImageUrl,
    required HairstyleGeneration generation,
  }) async {
    await supabase.from('hair_looks').insert({
      'user_id': userId,
      'style_name': styleName,
      'prompt': prompt,
      'source_image_url': generation.sourceImageUrl,
      'result_image_url': generation.resultImageUrl,
      'style_reference_image_url': styleReferenceImageUrl,
      'is_preview': generation.isPreview,
      'is_public': false,
      'visibility': 'private',
      'data': {
        'previewType': generation.isPreview ? 'mock_collage' : 'generated',
      },
    });
  }

  /// The user's saved hair looks, newest first (camelCase maps with an id).
  Stream<List<Map<String, dynamic>>> watchSavedLooks(String userId) {
    return supabase
        .from('hair_looks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => [for (final row in rows) camelizeRow(row)]);
  }

  Future<void> makeSavedLookPublic({
    required String userId,
    required String lookId,
  }) async {
    await supabase
        .from('hair_looks')
        .update({
          'is_public': true,
          'visibility': 'public',
          'published_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', lookId)
        .eq('user_id', userId);
  }

  Future<void> makeSavedLookPrivate({
    required String userId,
    required String lookId,
  }) async {
    await supabase
        .from('hair_looks')
        .update({'is_public': false, 'visibility': 'private'})
        .eq('id', lookId)
        .eq('user_id', userId);
  }

  Future<void> deleteSavedLook({
    required String userId,
    required String lookId,
  }) async {
    await supabase
        .from('comments')
        .delete()
        .eq('target_type', 'hairLook')
        .eq('target_id', lookId);
    await supabase
        .from('hair_looks')
        .delete()
        .eq('id', lookId)
        .eq('user_id', userId);

    // Affirmations must not outlive the look they were about.
    await AffirmationService().deleteAllForTarget(
      targetType: AffirmationTargetType.hairLook,
      targetId: lookId,
    );
  }

  Future<void> addSavedLookComment({
    required String ownerId,
    required String lookId,
    required String userId,
    required String text,
    required String username,
    required String profileImageURL,
  }) async {
    if (userId.isEmpty || text.trim().isEmpty) return;
    final moderated = moderateText(text);
    if (!moderated.isAllowed) throw ModerationException(moderated.reason!);
    await supabase.from('comments').insert({
      'target_type': 'hairLook',
      'target_id': lookId,
      'author_id': userId,
      'author_name': username,
      'author_image_url': profileImageURL,
      'text': moderated.text,
    });
  }

  Stream<List<PostComment>> watchSavedLookComments({
    required String ownerId,
    required String lookId,
  }) {
    return supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('target_id', lookId)
        .order('created_at', ascending: false)
        .map(
          (rows) => [
            for (final row in rows)
              if (row['target_type'] == 'hairLook') PostComment.fromRow(row),
          ],
        );
  }

  /// The hairstyle catalogue, live: everything for curators, or just the
  /// ones [uploaderId] added. Maps carry `id`, `name`, `imageUrl`, the
  /// catalogue fields, and `createdBy`.
  Stream<List<Map<String, dynamic>>> watchCatalog({String? uploaderId}) {
    final base = supabase.from('hairstyles').stream(primaryKey: ['id']);
    final source = uploaderId == null
        ? base
        : supabase
              .from('hairstyles')
              .stream(primaryKey: ['id'])
              .eq('uploader_id', uploaderId);
    return source.map(
      (rows) => [
        for (final row in rows)
          {...flattenRow(row), 'createdBy': row['uploader_id']},
      ],
    );
  }

  /// The catalogue fields every hairstyle carries beyond its name and picture.
  Map<String, dynamic> _catalogDetails({
    required String length,
    required String gender,
    required String hairType,
    required List<String> styleTypes,
    required String cutTypeGroup,
    required String cutType,
    required List<String> occasions,
    required String colour,
    required String maintenanceLevel,
  }) {
    return {
      'length': length,
      'gender': gender,
      'hairType': hairType,
      'styleType': styleTypes.isEmpty ? '' : styleTypes.first,
      'styleTypes': styleTypes,
      'cutTypeGroup': cutTypeGroup,
      'cutType': cutType,
      'occasion': occasions.isEmpty ? '' : occasions.first,
      'occasions': occasions,
      'colour': colour,
      'maintenanceLevel': maintenanceLevel,
    };
  }

  Future<String> _uploadCatalogImage(
    Uint8List imageBytes,
    String filename,
    String cutType,
  ) {
    final safeName = _safeStorageName(
      filename.trim().isEmpty ? cutType : filename,
    );
    return StorageFiles.upload(
      bucket: Buckets.hairstyles,
      path: '${DateTime.now().millisecondsSinceEpoch}_$safeName.jpg',
      bytes: imageBytes,
    );
  }

  Future<String> uploadCatalogHairstyle({
    required String userId,
    required Uint8List imageBytes,
    required String filename,
    required String length,
    required String gender,
    required String hairType,
    required List<String> styleTypes,
    required String cutTypeGroup,
    required String cutType,
    required List<String> occasions,
    required String colour,
    required String maintenanceLevel,
    String? name,
  }) async {
    final imageUrl = await _uploadCatalogImage(imageBytes, filename, cutType);
    final row = await supabase
        .from('hairstyles')
        .insert({
          'name': name?.trim().isNotEmpty == true ? name!.trim() : cutType,
          'image_url': imageUrl,
          'category': cutTypeGroup,
          'uploader_id': userId,
          'data': _catalogDetails(
            length: length,
            gender: gender,
            hairType: hairType,
            styleTypes: styleTypes,
            cutTypeGroup: cutTypeGroup,
            cutType: cutType,
            occasions: occasions,
            colour: colour,
            maintenanceLevel: maintenanceLevel,
          ),
        })
        .select('id')
        .single();
    return row['id'].toString();
  }

  Future<void> updateCatalogHairstyle({
    required String docId,
    required String userId,
    Uint8List? imageBytes,
    String? filename,
    required String length,
    required String gender,
    required String hairType,
    required List<String> styleTypes,
    required String cutTypeGroup,
    required String cutType,
    required List<String> occasions,
    required String colour,
    required String maintenanceLevel,
    String? name,
  }) async {
    final updates = <String, dynamic>{
      'name': name?.trim().isNotEmpty == true ? name!.trim() : cutType,
      'category': cutTypeGroup,
      'data': _catalogDetails(
        length: length,
        gender: gender,
        hairType: hairType,
        styleTypes: styleTypes,
        cutTypeGroup: cutTypeGroup,
        cutType: cutType,
        occasions: occasions,
        colour: colour,
        maintenanceLevel: maintenanceLevel,
      ),
    };

    if (imageBytes != null) {
      updates['image_url'] = await _uploadCatalogImage(
        imageBytes,
        filename?.trim().isNotEmpty == true ? filename! : cutType,
        cutType,
      );
    }

    await supabase.from('hairstyles').update(updates).eq('id', docId);
  }

  String _safeStorageName(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'hairstyle' : cleaned;
  }
}

class HairstyleGeneration {
  const HairstyleGeneration({
    required this.sourceImageUrl,
    required this.resultImageUrl,
    required this.isPreview,
  });

  final String sourceImageUrl;
  final String resultImageUrl;
  final bool isPreview;
}
