// Extra detail fields a boutique or designer can add to one piece, beyond
// its picture and size: measurements, fabric, origin, and any other useful
// detail (September 2026 request).
import 'package:flutter/foundation.dart';

@immutable
class PieceDetails {
  const PieceDetails({
    this.shoulderMeasurement = '',
    this.heightMeasurement = '',
    this.linenType = '',
    this.madeWhere = '',
    this.otherDetails = const [],
  });

  final String shoulderMeasurement;
  final String heightMeasurement;
  final String linenType;
  final String madeWhere;

  /// Free-form details added one at a time with "Add Detail".
  final List<String> otherDetails;

  bool get isEmpty =>
      shoulderMeasurement.isEmpty &&
      heightMeasurement.isEmpty &&
      linenType.isEmpty &&
      madeWhere.isEmpty &&
      otherDetails.isEmpty;

  factory PieceDetails.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const PieceDetails();
    final rawOtherDetails = data['otherDetails'];
    return PieceDetails(
      shoulderMeasurement: (data['shoulderMeasurement'] ?? '').toString(),
      heightMeasurement: (data['heightMeasurement'] ?? '').toString(),
      linenType: (data['linenType'] ?? '').toString(),
      madeWhere: (data['madeWhere'] ?? '').toString(),
      otherDetails: rawOtherDetails is Iterable
          ? rawOtherDetails
                .map((detail) => detail.toString().trim())
                .where((detail) => detail.isNotEmpty)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'shoulderMeasurement': shoulderMeasurement,
    'heightMeasurement': heightMeasurement,
    'linenType': linenType,
    'madeWhere': madeWhere,
    'otherDetails': otherDetails,
  };

  /// Reads the free-text controllers this feature uses for input, trimming
  /// blanks and dropping empty "other detail" rows.
  factory PieceDetails.fromControllerText({
    required String shoulderMeasurement,
    required String heightMeasurement,
    required String linenType,
    required String madeWhere,
    required Iterable<String> otherDetails,
  }) => PieceDetails(
    shoulderMeasurement: shoulderMeasurement.trim(),
    heightMeasurement: heightMeasurement.trim(),
    linenType: linenType.trim(),
    madeWhere: madeWhere.trim(),
    otherDetails: otherDetails
        .map((detail) => detail.trim())
        .where((detail) => detail.isNotEmpty)
        .toList(),
  );
}
