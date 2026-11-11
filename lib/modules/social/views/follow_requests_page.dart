import 'package:flutter/material.dart';

import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';

/// Page displaying incoming follow requests
class FollowRequestsPage extends StatelessWidget {
  const FollowRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FriendService friendService = FriendService();

    return Scaffold(
      appBar: AppBar(title: const Text("Follow Requests")),
      body: StreamBuilder<List<String>>(
        stream: friendService.getIncomingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          final requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requesterId = requests[index];
              return StreamBuilder<Map<String, dynamic>>(
                stream: ProfileService().watch(requesterId),
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
                    subtitle: const Text("wants to follow you"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: () =>
                              friendService.acceptFollowRequest(requesterId),
                          child: const Text('Accept'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () =>
                              friendService.declineFollowRequest(requesterId),
                          child: const Text('Decline'),
                        ),
                      ],
                    ),
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
