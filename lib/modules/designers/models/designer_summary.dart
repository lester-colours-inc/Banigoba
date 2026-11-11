// A designer as the lists and the detail page show them, plus the small text
// helpers the designer screens share.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/provider/models/portfolio_piece.dart';

class DesignerColors {
  static const primary = Color(0xFF0D0140);
}

class DesignerSummary {
  const DesignerSummary({
    required this.id,
    required this.name,
    required this.bio,
    required this.location,
    required this.specialties,
    required this.priceRange,
    required this.portfolioPieces,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String bio;
  final String location;
  final List<String> specialties;
  final String priceRange;
  final List<PortfolioPiece> portfolioPieces;
  final String avatarUrl;

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
