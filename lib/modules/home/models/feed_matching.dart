// Daily feed matching (review items D-4 and A-6): when a shop or designer a
// person follows has new stock, decide whether it belongs in their My Daily
// Dress Up feed. A piece matches when ALL of these hold:
//   1. it is from a shop or designer they follow (never a stranger),
//   2. it is in stock in their size (or a size the fit check says fits),
//   3. it suits a style they chose, or fills a gap in their wardrobe.
// Pure functions, so the rules are easy to test and to run on a server later.
import 'package:banigoba/core/supabase/rows.dart';
import 'package:flutter/foundation.dart';

import 'package:banigoba/core/utils/size_inventory.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/wardrobe/models/fit_check.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_matching.freezed.dart';

/// A day's cards never exceed this, so the feed doesn't turn into an advert.
const int kDailyFeedCards = 3;

/// A wardrobe category counts as a gap when the person owns fewer than this.
const int kGapBelow = 1;

/// Categories that come in sizes: clothing sizes, or shoe sizes for shoes.
const Set<String> kSizedCategories = {
  'tops',
  'bottoms',
  'dresses',
  'outerwear',
  'shoes',
};

/// Which shop style tags suit each style a person can choose. The two lists
/// were written separately, so this bridges them.
// UNCLEAR: placeholder mapping; confirm with the stakeholder.
const Map<String, Set<String>> kStyleBridge = {
  'casual': {'casual'},
  'smart': {'corporate'},
  'traditional': {'afrochic', 'traditional'},
  'streetwear': {'streetwear'},
  'elegant': {'glamour'},
  'sporty': {'sporty'},
};

/// Everything the matcher knows about the person.
@freezed
abstract class ShopperProfile with _$ShopperProfile {
  const ShopperProfile._();

  const factory ShopperProfile({
    required String userId,
    @Default(BodyProfile()) BodyProfile body,

    /// The styles they chose, e.g. "Smart".
    @Default([]) List<String> styles,

    /// How many wardrobe items they own, by category ("tops", "outerwear"...).
    @Default({}) Map<String, int> ownedByCategory,

    /// The shops and designers they follow.
    @Default({}) Set<String> followedSellerIds,
  }) = _ShopperProfile;
}

/// Why a piece was chosen, in words for the card.
@freezed
abstract class FeedMatch with _$FeedMatch {
  const FeedMatch._();

  const factory FeedMatch({
    required String productId,
    required int score,

    /// "In your size (M)", "Suits your Smart style", ...
    required List<String> reasons,

    /// The size to offer, or '' for one-size items.
    required String size,
  }) = _FeedMatch;

  String get headline => reasons.first;
}

String sellerOf(Map<String, dynamic> product) =>
    (product['uploaderId'] ??
            product['sellerId'] ??
            product['shopId'] ??
            product['userId'] ??
            '')
        .toString();

String _category(Map<String, dynamic> product) =>
    (product['category'] ?? '').toString().trim().toLowerCase();

/// The style the person chose that this piece suits, or null.
String? matchingStyle(Map<String, dynamic> product, List<String> styles) {
  final tag = (product['styleTag'] ?? product['style'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  if (tag.isEmpty) return null;
  for (final style in styles) {
    if (kStyleBridge[style.trim().toLowerCase()]?.contains(tag) ?? false) {
      return style;
    }
  }
  return null;
}

/// The size to offer in [product], or null when none suits the person:
/// their usual size if in stock, otherwise the size the fit check recommends
/// (if comfortable and in stock). One-size items give '' and always pass.
String? sizeFor(Map<String, dynamic> product, BodyProfile body) {
  final stock = parseSizeInventory(product);
  if (stock.isEmpty) return (product['stock'] as num? ?? 1) > 0 ? '' : null;
  final inStock = [
    for (final entry in stock.entries)
      if (entry.value > 0) entry.key,
  ];
  if (inStock.isEmpty) return null;
  // Shoes go by shoe size; a size chart says nothing about them.
  final footwear = _category(product) == 'shoes';
  if (footwear) return body.sizeToSelect(inStock, footwear: true);
  if (body.sizeToSelect(inStock, footwear: false) case final usual?) {
    // Their usual size, unless the shop's own chart says it is tight.
    final chart = SizeChart.fromProduct(product);
    final check = FitCheck.of(chart, body, selectedSize: usual);
    if (!check.hasResult || check.isComfortable) return usual;
  }
  final recommended = recommendSize(SizeChart.fromProduct(product), body);
  if (recommended != null && inStock.contains(recommended)) {
    final check = FitCheck.of(
      SizeChart.fromProduct(product),
      body,
      selectedSize: recommended,
    );
    if (check.isComfortable) return recommended;
  }
  return null;
}

/// Whether [product] belongs in [shopper]'s feed, and why. Null if not.
FeedMatch? matchProduct(Map<String, dynamic> product, ShopperProfile shopper) {
  final id = (product['id'] ?? '').toString();
  final seller = sellerOf(product);
  if (id.isEmpty || seller.isEmpty || seller == shopper.userId) return null;
  if (!shopper.followedSellerIds.contains(seller)) return null;

  final category = _category(product);
  var size = '';
  if (kSizedCategories.contains(category)) {
    final fitting = sizeFor(product, shopper.body);
    if (fitting == null) return null;
    size = fitting;
  } else if ((product['stock'] as num? ?? 1) <= 0 &&
      parseSizeInventory(product).isEmpty) {
    return null;
  }

  final style = matchingStyle(product, shopper.styles);
  final owned = shopper.ownedByCategory[category] ?? 0;
  final fillsGap =
      category.isNotEmpty &&
      category != 'other' &&
      owned < kGapBelow &&
      shopper.ownedByCategory.isNotEmpty;
  if (style == null && !fillsGap) return null;

  final reasons = [
    if (size.isNotEmpty) 'In your size ($size)' else 'Available now',
    if (style != null) 'Suits your $style style',
    if (fillsGap) "Fills a gap: you don't have any $category yet",
  ];
  return FeedMatch(
    productId: id,
    score: 3 + (style != null ? 2 : 0) + (fillsGap ? 2 : 0),
    reasons: List.unmodifiable(reasons),
    size: size,
  );
}

DateTime _createdAt(Map<String, dynamic> product) =>
    asDateTime(product['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);

/// Today's cards: the best matches (highest score, then newest), at most
/// [limit], skipping anything in [alreadyShown].
List<FeedMatch> pickDailyMatches(
  Iterable<Map<String, dynamic>> products,
  ShopperProfile shopper, {
  Set<String> alreadyShown = const {},
  int limit = kDailyFeedCards,
}) {
  final scored = <(FeedMatch, DateTime)>[];
  for (final product in products) {
    final id = (product['id'] ?? '').toString();
    if (alreadyShown.contains(id)) continue;
    final match = matchProduct(product, shopper);
    if (match != null) scored.add((match, _createdAt(product)));
  }
  scored.sort((a, b) {
    final byScore = b.$1.score.compareTo(a.$1.score);
    return byScore != 0 ? byScore : b.$2.compareTo(a.$2);
  });
  return List.unmodifiable(scored.take(limit).map((entry) => entry.$1));
}
