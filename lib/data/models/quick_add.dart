// Quick add for flea-market traders (review item K-1): a piece goes up with
// just a photo, a price, its kind and the sizes in hand. Everything else the
// full form asks for gets a sensible default, and can be edited later.
import 'package:flutter/foundation.dart';

/// The kinds of piece quick add offers, with the label used for the piece's
/// name when the trader does not type one.
enum QuickKind {
  tops('tops', 'Top'),
  bottoms('bottoms', 'Bottoms'),
  dresses('dresses', 'Dress'),
  outerwear('outerwear', 'Jacket'),
  shoes('shoes', 'Shoes'),
  accessories('accessories', 'Accessory'),
  other('other', 'Item');

  const QuickKind(this.category, this.defaultName);

  /// The product category the piece is saved under.
  final String category;
  final String defaultName;

  /// Whether pieces of this kind come in sizes.
  bool get isSized => this != accessories && this != other;

  /// The sizes to offer: letters for clothes, UK sizes for shoes.
  List<String> get sizes => switch (this) {
    shoes => const [
      'UK 3',
      'UK 4',
      'UK 5',
      'UK 6',
      'UK 7',
      'UK 8',
      'UK 9',
      'UK 10',
      'UK 11',
      'UK 12',
    ],
    accessories || other => const [],
    _ => const ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
  };
}

/// Reads a price typed by a person: "12", "12.50", "$12,50". Null when it is
/// not a positive number.
double? parsePrice(String input) {
  final cleaned = input.trim().replaceAll(r'$', '').replaceAll(',', '.');
  final value = double.tryParse(cleaned);
  if (value == null || value <= 0 || value.isNaN || value.isInfinite) {
    return null;
  }
  return (value * 100).roundToDouble() / 100;
}

@immutable
class QuickAddDraft {
  const QuickAddDraft({
    this.kind = QuickKind.tops,
    this.price,
    this.name = '',
    this.sizes = const {},
    this.quantity = 1,
    this.hasPhoto = false,
  });

  final QuickKind kind;
  final double? price;
  final String name;

  /// Pieces in hand per size (sized kinds only).
  final Map<String, int> sizes;

  /// Pieces in hand for kinds with no sizes.
  final int quantity;
  final bool hasPhoto;

  /// The piece's name: what the trader typed, or the kind's default.
  String get displayName =>
      name.trim().isEmpty ? kind.defaultName : name.trim();

  /// How many pieces in all.
  int get totalStock => kind.isSized
      ? sizes.values.fold(0, (sum, count) => sum + count)
      : quantity;

  /// What is missing before the piece can be saved, in plain words, or null.
  String? get problem {
    if (!hasPhoto) return 'Add a photo of the piece.';
    if (price == null) return 'Enter a price.';
    if (kind.isSized && totalStock <= 0) return 'Pick at least one size.';
    if (!kind.isSized && quantity <= 0) return 'Say how many you have.';
    return null;
  }

  bool get isReady => problem == null;

  QuickAddDraft copyWith({
    QuickKind? kind,
    double? price,
    String? name,
    Map<String, int>? sizes,
    int? quantity,
    bool? hasPhoto,
  }) => QuickAddDraft(
    kind: kind ?? this.kind,
    price: price ?? this.price,
    name: name ?? this.name,
    // Changing the kind clears sizes that do not belong to it.
    sizes: kind != null && kind != this.kind ? const {} : (sizes ?? this.sizes),
    quantity: quantity ?? this.quantity,
    hasPhoto: hasPhoto ?? this.hasPhoto,
  );

  /// Adds one of [size], or removes the size when [delta] takes it to zero.
  QuickAddDraft adjustSize(String size, int delta) {
    final next = Map<String, int>.of(sizes);
    final count = (next[size] ?? 0) + delta;
    if (count <= 0) {
      next.remove(size);
    } else {
      next[size] = count;
    }
    return copyWith(sizes: next);
  }

  /// The product fields to save (camelCase, as the product service expects).
  Map<String, dynamic> toProduct({
    required String imageUrl,
    required String shopName,
  }) {
    assert(isReady, 'Only a ready draft can be saved.');
    return {
      'name': displayName,
      'price': price,
      'stock': totalStock,
      if (kind.isSized) 'sizeInventory': Map<String, int>.of(sizes),
      'imageUrl': imageUrl,
      'rawImageUrl': imageUrl,
      'category': kind.category,
      'styleTag': 'casual',
      'colours': const <String>[],
      'gender': 'unisex',
      'weatherTags': const <String>[],
      'functionalTags': const <String>[],
      'shopName': shopName,
    };
  }
}

/// Moves one size's count by [delta], never below zero. Used by the stock
/// editor, where a size can sit at zero (sold out) rather than disappear.
Map<String, int> adjustedStock(Map<String, int> sizes, String size, int delta) {
  final next = Map<String, int>.of(sizes);
  final count = (next[size] ?? 0) + delta;
  next[size] = count < 0 ? 0 : count;
  return next;
}
