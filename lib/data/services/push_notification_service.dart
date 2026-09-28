// Registers FCM device tokens and handles notification taps.
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';
import '../../core/app_routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const int _apnsTokenAttempts = 20;
  static const Duration _apnsTokenRetryDelay = Duration(milliseconds: 500);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  String? _registeredUserId;
  String? _registeredToken;
  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  bool _isRegisteringToken = false;
  bool _pendingNotificationOpen = false;

  bool get _supportsPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) async {
    if (!_supportsPush) return;

    _navigatorKey = navigatorKey;
    _scaffoldMessengerKey = scaffoldMessengerKey;
    WidgetsBinding.instance.addObserver(this);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _authSubscription ??= _auth.authStateChanges().listen(_handleAuthChange);
    _tokenSubscription ??= _messaging.onTokenRefresh.listen(_saveToken);
    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
    );
    _messageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _openNotifications,
    );

    await _handleAuthChange(_auth.currentUser);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openNotifications(initialMessage);
      });
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      await _deleteRegisteredToken();
      return;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      return;
    }

    await _registerToken();
    _openPendingNotificationIfNeeded();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _auth.currentUser != null) {
      unawaited(_registerToken());
    }
  }

  Future<void> _registerToken() async {
    if (_isRegisteringToken || _auth.currentUser == null) return;
    _isRegisteringToken = true;

    try {
      if (!await _isApnsTokenAvailable()) return;

      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (error) {
      debugPrint('Unable to register push notifications: $error');
    } finally {
      _isRegisteringToken = false;
    }
  }

  Future<bool> _isApnsTokenAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return true;

    for (var attempt = 0; attempt < _apnsTokenAttempts; attempt++) {
      final token = await _messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return true;

      if (attempt < _apnsTokenAttempts - 1) {
        await Future<void>.delayed(_apnsTokenRetryDelay);
      }
    }

    return false;
  }

  Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null || token.isEmpty) return;

    if (_registeredUserId != null &&
        _registeredUserId != user.uid &&
        _registeredToken != null) {
      await _deleteRegisteredToken();
    }

    final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(tokenId)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    _registeredUserId = user.uid;
    _registeredToken = token;
  }

  Future<void> _deleteRegisteredToken() async {
    final userId = _registeredUserId;
    final token = _registeredToken;
    if (userId == null || token == null) return;

    final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(tokenId)
        .delete();

    _registeredUserId = null;
    _registeredToken = null;
  }

  void _openNotifications(RemoteMessage message) {
    if (_auth.currentUser == null || _navigatorKey?.currentState == null) {
      _pendingNotificationOpen = true;
      return;
    }

    _pendingNotificationOpen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey?.currentState;
      if (navigator == null) return;
      navigator.popUntil((route) => route.isFirst);
      navigator.pushNamed(AppRoutes.notifications);
    });
  }

  void _openPendingNotificationIfNeeded() {
    if (!_pendingNotificationOpen || _auth.currentUser == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pendingNotificationOpen || _auth.currentUser == null) return;
      _pendingNotificationOpen = false;
      final navigator = _navigatorKey?.currentState;
      if (navigator == null) return;
      navigator.popUntil((route) => route.isFirst);
      navigator.pushNamed(AppRoutes.notifications);
    });
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final messenger = _scaffoldMessengerKey?.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            notification.body == null
                ? notification.title ?? 'New notification'
                : '${notification.title ?? 'Banigoba'}\n${notification.body}',
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _openNotifications(message),
          ),
        ),
      );
  }
}
