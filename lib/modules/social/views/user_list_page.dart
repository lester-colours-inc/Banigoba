import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/modules/social/views/profile_page.dart';

/// Generic page displaying a list of users (e.g. Followers list)
class UserListPage extends StatelessWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final String title;

  const UserListPage({
    super.key,
    required this.userId,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<String>>(
        stream: FriendService().listUserIds(userId, type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No $title yet"));
          }

          final userIds = snapshot.data!;

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              return StreamBuilder<Map<String, dynamic>>(
                stream: ProfileService().watch(userIds[index]),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final userData = userSnapshot.data!;
                  final name = userData['displayName'] ?? 'User';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D0140),
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(name),
                    onTap: () =>
                        Get.to<void>(() => ProfilePage(userId: userIds[index])),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
