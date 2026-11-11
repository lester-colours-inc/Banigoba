// Shared helpers for boutique size inventory.
//
// The database stores product sizes as a dynamic map, but cart and order logic
// need predictable labels and integer quantities. Keeping the normalization
// here makes the customer UI, cart, and checkout agree on the same size keys.

String normalizeSizeLabel(Object? value) {
  return (value ?? '').toString().trim().toUpperCase();
}

Map<String, int> parseSizeInventory(Map<String, dynamic> data) {
  final raw = data['sizeInventory'];
  if (raw is! Map) return <String, int>{};

  final inventory = <String, int>{};
  raw.forEach((key, value) {
    final size = normalizeSizeLabel(key);
    final quantity = _intValue(value);
    if (size.isNotEmpty) inventory[size] = quantity;
  });
  return inventory;
}

int totalSizeInventory(Map<String, int> inventory) {
  return inventory.values.fold<int>(0, (total, quantity) => total + quantity);
}

String cartItemIdForSize(String productId, String selectedSize) {
  final size = normalizeSizeLabel(selectedSize);
  if (size.isEmpty) return productId;
  final safeSize = size.toLowerCase().replaceAll('/', '-');
  return '${productId}_size_$safeSize';
}

int _intValue(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}
