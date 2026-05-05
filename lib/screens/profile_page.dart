import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import 'product_detail_page.dart';

class ProfilePage extends StatelessWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final targetUserId = userId ?? currentUserId;
    final FriendService friendService = FriendService();

    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final bool isMe = targetUserId == currentUserId;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(targetUserId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("User not found")));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userName = userData['displayName'] ?? 'User';
        final userEmail = userData['email'] ?? '';

        return StreamBuilder<bool>(
          stream: friendService.isFollowing(targetUserId),
          builder: (context, followingSnapshot) {
            final isFollowing = followingSnapshot.data ?? false;
            final bool canSeeContent = isMe || isFollowing;

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text(isMe ? "My Profile" : userName),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                actions: [
                  if (isMe)
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF0D0140),
                      child: Text(
                        userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (!isMe) ...[
                      const SizedBox(height: 20),
                      StreamBuilder<bool>(
                        stream: friendService.hasPendingRequest(targetUserId),
                        builder: (context, requestSnapshot) {
                          final hasRequest = requestSnapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: () {
                              if (isFollowing) {
                                friendService.unfollowUser(targetUserId);
                              } else if (hasRequest) {
                                friendService.cancelFollowRequest(targetUserId);
                              } else {
                                friendService.sendFollowRequest(targetUserId);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.grey : (hasRequest ? Colors.orange : const Color(0xFF0D0140)),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            child: Text(isFollowing ? 'Unfollow' : (hasRequest ? 'Requested' : 'Follow')),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(context, 'Followers', friendService.getFollowersCount(targetUserId), targetUserId, 'followers', canSeeContent),
                        _buildStatColumn(context, 'Following', friendService.getFollowingCount(targetUserId), targetUserId, 'following', canSeeContent),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    if (canSeeContent) ...[
                      _buildUserItems(targetUserId, isMe),
                      if (isMe) ...[
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text("Settings"),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: const Text("Help & Support"),
                          onTap: () {},
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 50),
                      const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text("This Account is Private", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Follow this user to see their wardrobe", style: TextStyle(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserItems(String userId, bool isMe) {
    Stream<QuerySnapshot> stream;
    if (isMe) {
      stream = FirebaseFirestore.instance
          .collection('user_products')
          .where('userId', isEqualTo: userId)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('user_products')
          .where('userId', isEqualTo: userId)
          .where('visibility', isEqualTo: 'public')
          .snapshots();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            isMe ? "My Wardrobe" : "Wardrobe",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No public items to show."),
              );
            }

            final items = snapshot.data!.docs;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final data = items[index].data() as Map<String, dynamic>;
                final imageUrl = data['imageUrl'] ?? data['imageURL'] ?? '';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(productData: data),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, Stream<int> stream, String userId, String type, bool canSee) {
    return GestureDetector(
      onTap: () {
        if (canSee) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserListPage(userId: userId, type: type, title: label),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Follow this account to see their list")));
        }
      },
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Column(
            children: [
              Text(
                count.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FollowRequestsPage extends StatelessWidget {
  const FollowRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FriendService friendService = FriendService();

    return Scaffold(
      appBar: AppBar(title: const Text("Follow Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: friendService.getIncomingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending requests"));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requesterId = requests[index].id;
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(requesterId).snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox.shrink();
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = userData['displayName'] ?? 'User';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D0140),
                      child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(name),
                    subtitle: const Text("wants to follow you"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => friendService.acceptFollowRequest(requesterId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => friendService.declineFollowRequest(requesterId),
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

class UserListPage extends StatelessWidget {
  final String userId;
  final String type; // 'followers' or 'following'
  final String title;

  const UserListPage({super.key, required this.userId, required this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(type)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No $title yet"));
          }

          final userIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(userIds[index]).snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = userData['displayName'] ?? 'User';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D0140),
                      child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(name),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage(userId: userIds[index])),
                      );
                    },
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
