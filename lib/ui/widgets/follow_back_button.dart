// "Follow back" for someone who follows you. Every follow is a request, so
// this sends one; it then reads Requested, and Following once accepted.
import 'package:flutter/material.dart';

import '../../data/services/friend_service.dart';

class FollowBackButton extends StatefulWidget {
  const FollowBackButton({super.key, required this.userId, this.friends});

  final String userId;

  /// Injected in tests; the app's service otherwise.
  final FriendService? friends;

  @override
  State<FollowBackButton> createState() => _FollowBackButtonState();
}

class _FollowBackButtonState extends State<FollowBackButton> {
  late final FriendService _friends = widget.friends ?? FriendService();
  late final Stream<bool> _isFollowing = _friends.isFollowing(widget.userId);
  late final Stream<bool> _isRequested = _friends.hasPendingRequest(
    widget.userId,
  );
  bool _isSending = false;

  Future<void> _followBack() async {
    setState(() => _isSending = true);
    try {
      await _friends.sendFollowRequest(widget.userId);
    } on Exception catch (error) {
      debugPrint('Unable to follow back ${widget.userId}: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to follow back. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isFollowing,
      builder: (context, following) => StreamBuilder<bool>(
        stream: _isRequested,
        builder: (context, requested) {
          if (!following.hasData || !requested.hasData) {
            return const SizedBox.shrink();
          }
          if (following.data == true) {
            return _settled(context, 'Following');
          }
          if (requested.data == true) {
            return _settled(context, 'Requested');
          }
          return FilledButton(
            onPressed: _isSending ? null : _followBack,
            child: const Text('Follow back'),
          );
        },
      ),
    );
  }

  Widget _settled(BuildContext context, String label) => OutlinedButton(
    onPressed: null,
    child: Text(
      label,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
