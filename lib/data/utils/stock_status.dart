// What a shop has left of each piece (K-1): total stock, and whether a piece
// is sold out or running low, so a trader with a few pieces sees at a glance
// what needs restocking.
import 'size_inventory.dart';

/// A piece counts as low when this many or fewer are left.
const int kLowStockAt = 2;

enum StockLevel { soldOut, low, inStock }

/// Everything left: the sum of the sizes, or the single count for a one-size
/// piece.
int totalStock(Map<String, dynamic> product) {
  final sizes = parseSizeInventory(product);
  if (sizes.isNotEmpty) return totalSizeInventory(sizes);
  final stock = product['stock'];
  return stock is num ? stock.toInt() : 0;
}

StockLevel stockLevelOf(Map<String, dynamic> product) {
  final left = totalStock(product);
  if (left <= 0) return StockLevel.soldOut;
  if (left <= kLowStockAt) return StockLevel.low;
  return StockLevel.inStock;
}

class StockSummary {
  const StockSummary({
    required this.total,
    required this.soldOut,
    required this.low,
  });

  final int total;
  final int soldOut;
  final int low;
}

StockSummary summarizeStock(Iterable<Map<String, dynamic>> products) {
  var total = 0;
  var soldOut = 0;
  var low = 0;
  for (final product in products) {
    total += 1;
    switch (stockLevelOf(product)) {
      case StockLevel.soldOut:
        soldOut += 1;
      case StockLevel.low:
        low += 1;
      case StockLevel.inStock:
        break;
    }
  }
  return StockSummary(total: total, soldOut: soldOut, low: low);
}

/// The products at [level], or all of them when [level] is null.
List<Map<String, dynamic>> filterByStock(
  Iterable<Map<String, dynamic>> products,
  StockLevel? level,
) => [
  for (final product in products)
    if (level == null || stockLevelOf(product) == level) product,
];

/// How far a piece got in followers' feeds, for the shop: "Shown to 4 of 9
/// followers". Null for a piece with no record (listed before this existed).
String? reachLabel({required int? reach, required int? followers}) {
  if (reach == null || followers == null) return null;
  if (followers == 0) return 'No followers yet';
  if (reach == 0) return 'No follower matched it yet';
  return 'Shown to $reach of $followers ${followers == 1 ? 'follower' : 'followers'}';
}
