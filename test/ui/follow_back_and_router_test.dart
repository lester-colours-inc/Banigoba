import 'dart:async';

import 'package:banigoba/modules/social/services/friend_service.dart';
import 'package:banigoba/modules/notifications/services/notification_router.dart';
import 'package:banigoba/modules/social/widgets/follow_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Follows held in memory; a sent request shows as pending at once.
class _FakeFriends extends FriendService {
  _FakeFriends({bool following = false, bool requested = false})
    : _following = following,
      _requested = requested;

  final bool _following;
  bool _requested;
  final _requestedChanges = StreamController<bool>.broadcast();
  final sent = <String>[];

  @override
  Stream<bool> isFollowing(String targetUserId) => Stream.value(_following);

  @override
  Stream<bool> hasPendingRequest(String targetUserId) async* {
    yield _requested;
    yield* _requestedChanges.stream;
  }

  @override
  Future<void> sendFollowRequest(String targetUserId) async {
    sent.add(targetUserId);
    _requested = true;
    _requestedChanges.add(true);
  }
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FollowBackButton', () {
    testWidgets('sends a follow request and then reads Requested', (
      tester,
    ) async {
      final friends = _FakeFriends();
      await tester.pumpWidget(
        _host(FollowBackButton(userId: 'amara', friends: friends)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Follow back'));
      await tester.pumpAndSettle();

      expect(friends.sent, ['amara']);
      expect(find.text('Requested'), findsOneWidget);
      expect(find.text('Follow back'), findsNothing);
    });

    testWidgets('reads Following when you already follow them', (tester) async {
      await tester.pumpWidget(
        _host(
          FollowBackButton(
            userId: 'amara',
            friends: _FakeFriends(following: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Follow back'), findsNothing);
    });
  });

  group('openNotificationTarget', () {
    Future<bool> open(
      WidgetTester tester,
      String type,
      Map<String, dynamic>? data,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      return openNotificationTarget(context, type, data);
    }

    testWidgets('has nowhere to go without an id', (tester) async {
      expect(await open(tester, 'general', null), isFalse);
    });

    testWidgets('a look notification without its post has nowhere to go', (
      tester,
    ) async {
      expect(await open(tester, 'comment', {'fromId': 'amara'}), isFalse);
      expect(await open(tester, 'like', const {}), isFalse);
    });

    testWidgets('an affirmation on a makeover is not opened as a post', (
      tester,
    ) async {
      expect(
        await open(tester, 'affirmation', {
          'targetType': 'makeover',
          'targetId': 'm1',
        }),
        isFalse,
      );
    });
  });
}
