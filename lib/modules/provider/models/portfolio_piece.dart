// One piece in a designer's portfolio: a picture plus the same detail a
// boutique gives a stock item (September 2026 request), so a customer can
// judge fit and fabric the same way whichever surface the piece came from.
//
// Stored as a list of maps on designerProfile.portfolioPieces, alongside the
// existing designerProfile fields — see FashionDesignersPage.
import 'package:flutter/foundation.dart';

import 'package:banigoba/modules/wardrobe/models/piece_details.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_piece.freezed.dart';

@freezed
abstract class PortfolioPiece with _$PortfolioPiece {
  const PortfolioPiece._();

  const factory PortfolioPiece({
    required String imageUrl,
    @Default('') String size,
    @Default(PieceDetails()) PieceDetails details,
  }) = _PortfolioPiece;

  bool get isEmpty => imageUrl.isEmpty && size.isEmpty && details.isEmpty;

  factory PortfolioPiece.fromMap(Map<String, dynamic> data) => PortfolioPiece(
    imageUrl: (data['imageUrl'] ?? '').toString(),
    size: (data['size'] ?? '').toString(),
    details: PieceDetails.fromMap(data),
  );

  /// A plain image URL from the older, detail-free portfolio list.
  factory PortfolioPiece.fromImageUrl(String imageUrl) =>
      PortfolioPiece(imageUrl: imageUrl);

  Map<String, dynamic> toMap() => {
    'imageUrl': imageUrl,
    'size': size,
    ...details.toMap(),
  };

  /// The pieces stored under `designerProfile.portfolioPieces`, falling back
  /// to the older plain `portfolioImages` list so an existing designer's
  /// portfolio does not go blank the first time this loads.
  static List<PortfolioPiece> listFromProfile(Map<String, dynamic> profile) {
    final rawPieces = profile['portfolioPieces'];
    if (rawPieces is Iterable) {
      return rawPieces
          .whereType<Map>()
          .map(
            (piece) => PortfolioPiece.fromMap(Map<String, dynamic>.from(piece)),
          )
          .where((piece) => !piece.isEmpty)
          .toList();
    }
    final rawImages = profile['portfolioImages'];
    if (rawImages is Iterable) {
      return rawImages
          .map((url) => url.toString().trim())
          .where((url) => url.isNotEmpty)
          .map(PortfolioPiece.fromImageUrl)
          .toList();
    }
    return const [];
  }
}
