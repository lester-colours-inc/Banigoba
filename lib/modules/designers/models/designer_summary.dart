// A designer as the lists and the detail page show them, plus the small text
// helpers the designer screens share.
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:banigoba/modules/provider/models/portfolio_piece.dart';

part 'designer_summary.freezed.dart';

class DesignerColors {
  static const primary = Color(0xFF0D0140);
}

@freezed
abstract class DesignerSummary with _$DesignerSummary {
  const DesignerSummary._();

  const factory DesignerSummary({
    required String id,
    required String name,
    required String bio,
    required String location,
    required List<String> specialties,
    required String priceRange,
    required List<PortfolioPiece> portfolioPieces,
    required String avatarUrl,
  }) = _DesignerSummary;

  factory DesignerSummary.fromProfile(Map<String, dynamic> data) {
    final profile = Map<String, dynamic>.from(
      data['designerProfile'] as Map? ?? const {},
    );
    final name = (profile['name'] ?? data['displayName'] ?? 'Designer')
        .toString();
    final portfolioPieces = PortfolioPiece.listFromProfile(profile);
    final avatar =
        (profile['avatarUrl'] ??
                data['profileImageUrl'] ??
                (portfolioPieces.isEmpty ? '' : portfolioPieces.first.imageUrl))
            .toString();
    return DesignerSummary(
      id: data['id'].toString(),
      name: name,
      bio: (profile['bio'] ?? '').toString(),
      location: (profile['location'] ?? '').toString(),
      specialties: toStringList(profile['specialties']),
      priceRange: (profile['priceRange'] ?? '').toString(),
      portfolioPieces: portfolioPieces,
      avatarUrl: avatar,
    );
  }
}

List<String> splitCsv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<String> toStringList(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return splitCsv(value);
  }
  return const [];
}
