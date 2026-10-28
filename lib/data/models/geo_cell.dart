// A coarse place for "Near me" (review items P-5, A-4): the phone's location
// reduced to a square about 22 km wide. Only the cell is ever saved or shown
// to other people, never coordinates, so nobody can be pinned down closer
// than a district. Two people are near each other when their cells are the
// same or touch.
import 'package:flutter/foundation.dart';

/// Cell size in degrees; 0.2 degrees is about 22 km.
const double kCellDegrees = 0.2;

@immutable
class GeoCell {
  const GeoCell(this.x, this.y);

  /// The cell holding the point at [latitude], [longitude].
  factory GeoCell.fromLatLng(double latitude, double longitude) => GeoCell(
    (longitude / kCellDegrees).floor(),
    (latitude / kCellDegrees).floor(),
  );

  final int x;
  final int y;

  /// "31:-89": how the cell is stored.
  String get key => '$x:$y';

  /// The cell for a stored [key], or null when it is not one.
  static GeoCell? tryParse(String? key) {
    final parts = (key ?? '').split(':');
    if (parts.length != 2) return null;
    final x = int.tryParse(parts[0]);
    final y = int.tryParse(parts[1]);
    return x == null || y == null ? null : GeoCell(x, y);
  }

  /// The same cell, or one touching it.
  bool isNear(GeoCell other) =>
      (x - other.x).abs() <= 1 && (y - other.y).abs() <= 1;

  @override
  bool operator ==(Object other) =>
      other is GeoCell && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'GeoCell($key)';
}
