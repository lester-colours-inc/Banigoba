// One person in the Discover results; opens their profile.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/views/profile_page.dart';

const Color _primaryColor = Color(0xFF0D0140);

class PersonResultTile extends StatelessWidget {
  const PersonResultTile({super.key, required this.person});

  final Map<String, dynamic> person;

  static String _profileImageUrl(Map<String, dynamic> data) {
    final value =
        data['profileImageUrl'] ?? data['photoURL'] ?? data['photoUrl'];
    return value is String ? value.trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = (person['displayName'] ?? person['name'] ?? 'User')
        .toString()
        .trim();
    final imageUrl = _profileImageUrl(person);
    final initial = name.isEmpty ? 'U' : name[0].toUpperCase();
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            Get.to<void>(() => ProfilePage(userId: person['id'].toString())),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: _primaryColor,
                backgroundImage: imageUrl.isEmpty
                    ? null
                    : CachedNetworkImageProvider(imageUrl),
                child: imageUrl.isEmpty
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'User' : name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((person['username'] ?? '').toString()
                        case final username when username.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
