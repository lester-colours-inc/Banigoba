// Extra detail fields a boutique or designer can add to one piece, beyond
// its picture and size: measurements, fabric, origin, and any other useful
// detail (September 2026 request).
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'piece_details.freezed.dart';

@freezed
abstract class PieceDetails with _$PieceDetails {
  const PieceDetails._();

  const factory PieceDetails({
    @Default('') String shoulderMeasurement,
    @Default('') String heightMeasurement,
    @Default('') String linenType,
    @Default('') String madeWhere,

    /// Free-form details added one at a time with "Add Detail".
    @Default([]) List<String> otherDetails,
  }) = _PieceDetails;

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
