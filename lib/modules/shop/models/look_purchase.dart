// From look to purchase (review items K-4 and A-7): after a makeover or on
// someone's look, say for each piece whether the person already owns
// something like it, and which verified shops sell one that fits them.
//
// Pieces are matched by kind (tops, shoes...), size and chosen style. The
// look itself is a picture, so colour is not matched. Pure functions; the
// service in look_purchase_service.dart supplies the stock.
import 'package:flutter/foundation.dart';

import 'package:banigoba/core/utils/size_inventory.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/home/models/feed_matching.dart';
import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'look_purchase.freezed.dart';

/// How many shop pieces are offered for each part of a look.
const int kPicksPerPart = 3;

const Set<String> _garments = {'tops', 'bottoms', 'dresses', 'outerwear'};

const Map<LookPart, Set<String>> _partCategories = {
  LookPart.outfit: _garments,
  LookPart.top: {'tops', 'outerwear'},
  LookPart.bottom: {'bottoms'},
  LookPart.accessories: {'accessories'},
};

final RegExp _shoeWords = RegExp(
  r'\b(shoes?|sneakers?|trainers?|boots?|sandals?|heels?|loafers?|flats|pumps)\b',
  caseSensitive: false,
);

bool _isShoe(Map<String, dynamic> item) =>
    _shoeWords.hasMatch((item['name'] ?? '').toString());

/// Whether a wardrobe item or shop product is the kind of thing [part] needs.
/// Shoes are the shoes category, or, for older listings made before it
/// existed, anything with a shoe word in its name.
bool itemSuitsPart(Map<String, dynamic> item, LookPart part) {
  if (part == LookPart.hair) return false;
  final category = (item['category'] ?? '').toString().trim().toLowerCase();
  final isShoe = category == 'shoes' || _isShoe(item);
  if (part == LookPart.shoes) return isShoe;
  if (isShoe) return false;
  return _partCategories[part]?.contains(category) ?? false;
}

/// A shop piece worth offering, and why.
@freezed
abstract class ShopPick with _$ShopPick {
  const ShopPick._();

  const factory ShopPick({
    required Map<String, dynamic> product,

    /// The size to add to the cart, or '' for a one-size piece.
    required String size,

    /// "In your size (M)", "Suits your Smart style", ...
    required List<String> reasons,
    required int score,
  }) = _ShopPick;
}

/// What to say about one part of a look.
@freezed
abstract class PieceAdvice with _$PieceAdvice {
  const PieceAdvice._();

  const factory PieceAdvice({
    required LookPart part,

    /// Wardrobe items of the right kind.
    required List<Map<String, dynamic>> owned,
    required List<ShopPick> picks,
  }) = _PieceAdvice;

  bool get hasIt => owned.isNotEmpty;
}

num _price(Map<String, dynamic> product) =>
    product['price'] is num ? product['price'] as num : 0;

/// The wardrobe items and shop picks for [part]. [stock] should already be
/// limited to verified shops.
PieceAdvice adviceFor(
  LookPart part, {
  required String userId,
  required Iterable<Map<String, dynamic>> wardrobe,
  required Iterable<Map<String, dynamic>> stock,
  required BodyProfile body,
  required List<String> styles,
  int limit = kPicksPerPart,
}) {
  final owned = [
    for (final item in wardrobe)
      if (itemSuitsPart(item, part)) item,
  ];
  final picks = <ShopPick>[];
  for (final product in stock) {
    if (!itemSuitsPart(product, part)) continue;
    final seller = sellerOf(product);
    if (seller.isEmpty || seller == userId) continue;

    final category = (product['category'] ?? '').toString().toLowerCase();
    var size = '';
    if (kSizedCategories.contains(category)) {
      final fitting = sizeFor(product, body);
      if (fitting == null) continue;
      size = fitting;
    } else if ((product['stock'] as num? ?? 1) <= 0 &&
        parseSizeInventory(product).isEmpty) {
      continue;
    }

    final style = matchingStyle(product, styles);
    picks.add(
      ShopPick(
        product: product,
        size: size,
        score: style != null ? 2 : 0,
        reasons: [
          if (size.isNotEmpty) 'In your size ($size)' else 'Available now',
          if (style != null) 'Suits your $style style',
          if (owned.isEmpty) "You don't have any yet",
        ],
      ),
    );
  }
  picks.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0
        ? byScore
        : _price(a.product).compareTo(_price(b.product));
  });
  return PieceAdvice(
    part: part,
    owned: List.unmodifiable(owned),
    picks: List.unmodifiable(picks.take(limit)),
  );
}
