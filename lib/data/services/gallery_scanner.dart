// Reads the most recent photos on the phone for gallery suggestions (E-5).
// Only called after the person has agreed (see GalleryConsent). Thumbnails
// are loaded for display on the phone; a photo's full bytes are read only
// when the person picks it. Nothing here uploads anything.
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

enum GalleryAccess { granted, denied, unsupported }

/// One recent photo: loaders, so nothing is read until it is needed.
@immutable
class GalleryPhoto {
  const GalleryPhoto({
    required this.id,
    required this.thumbnail,
    required this.bytes,
  });

  final String id;
  final Future<Uint8List?> Function() thumbnail;
  final Future<Uint8List?> Function() bytes;
}

abstract interface class GalleryScanner {
  /// Asks the phone for permission to read photos.
  Future<GalleryAccess> requestAccess();

  /// The newest photos, at most [limit].
  Future<List<GalleryPhoto>> recent({int limit});
}

class PhotoManagerScanner implements GalleryScanner {
  const PhotoManagerScanner();

  @override
  Future<GalleryAccess> requestAccess() async {
    if (kIsWeb) return GalleryAccess.unsupported;
    final state = await PhotoManager.requestPermissionExtend();
    return state.hasAccess ? GalleryAccess.granted : GalleryAccess.denied;
  }

  @override
  Future<List<GalleryPhoto>> recent({int limit = 12}) async {
    if (kIsWeb) return const [];
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    if (albums.isEmpty) return const [];
    final assets = await albums.first.getAssetListRange(start: 0, end: limit);
    return [
      for (final asset in assets)
        GalleryPhoto(
          id: asset.id,
          thumbnail: () =>
              asset.thumbnailDataWithSize(const ThumbnailSize.square(240)),
          bytes: () => asset.originBytes,
        ),
    ];
  }
}
