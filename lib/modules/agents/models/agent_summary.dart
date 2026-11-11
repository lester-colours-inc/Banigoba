// An agent as the lists and the detail page show them, plus the small text
// helpers the agent screens share.
import 'package:flutter/material.dart';

class AgentColors {
  static const primary = Color(0xFF0D0140);
}

class AgentSummary {
  const AgentSummary({
    required this.id,
    required this.type,
    required this.name,
    required this.bio,
    required this.location,
    required this.services,
    required this.rate,
    required this.avatarUrl,
  });

  final String id;
  final String type;
  final String name;
  final String bio;
  final String location;
  final List<String> services;
  final String rate;
  final String avatarUrl;

  String get typeLabel => type == 'hair' ? 'Hair Agent' : 'Clothes Agent';

  factory AgentSummary.fromProfile(Map<String, dynamic> data) {
    final profile = Map<String, dynamic>.from(
      data['agentProfile'] as Map? ?? const {},
    );
    final type = (profile['type'] ?? 'hair').toString() == 'clothes'
        ? 'clothes'
        : 'hair';
    final name = (profile['name'] ?? data['displayName'] ?? 'Agent').toString();
    final avatar = (profile['avatarUrl'] ?? data['profileImageUrl'] ?? '')
        .toString();
    return AgentSummary(
      id: data['id'].toString(),
      type: type,
      name: name,
      bio: (profile['bio'] ?? '').toString(),
      location: (profile['location'] ?? '').toString(),
      services: toStringList(profile['services']),
      rate: (profile['rate'] ?? '').toString(),
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
