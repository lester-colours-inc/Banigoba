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
    final FriendService _friendService = FriendService();

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
                    stream: _friendService.isFollowing(targetUserId),
                    builder: (context, followSnapshot) {
                      final isFollowing = followSnapshot.data ?? false;
                      return ElevatedButton(
                        onPressed: () {
                          if (isFollowing) {
                            _friendService.unfollowUser(targetUserId);
                          } else {
                            _friendService.followUser(targetUserId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.grey : const Color(0xFF0D0140),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(context, 'Followers', _friendService.getFollowersCount(targetUserId), targetUserId, 'followers'),
                    _buildStatColumn(context, 'Following', _friendService.getFollowingCount(targetUserId), targetUserId, 'following'),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(),
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
              ],
            ),
          ),
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

  Widget _buildStatColumn(BuildContext context, String label, Stream<int> stream, String userId, String type) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserListPage(userId: userId, type: type, title: label),
          ),
        );
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
