// Registers FCM device tokens and handles notification taps.
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/firebase_options.dart';
import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/notifications/services/notification_router.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const int _apnsTokenAttempts = 20;
  static const Duration _apnsTokenRetryDelay = Duration(milliseconds: 500);

  final AppAuth _auth = AppAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  String? _registeredUserId;
  String? _registeredToken;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isRegisteringToken = false;
  bool _pendingNotificationOpen = false;

  /// The tapped push's data while waiting for sign-in, so it can still open
  /// the right page.
  Map<String, dynamic>? _pendingMessageData;

  bool get _supportsPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (!_supportsPush) return;

    _navigatorKey = navigatorKey;
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

  Future<void> _handleAuthChange(AppUser? user) async {
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

    await supabase.from('fcm_tokens').upsert({
      'user_id': user.uid,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    _registeredUserId = user.uid;
    _registeredToken = token;
  }

  Future<void> _deleteRegisteredToken() async {
    final userId = _registeredUserId;
    final token = _registeredToken;
    if (userId == null || token == null) return;

    await supabase
        .from('fcm_tokens')
        .delete()
        .eq('user_id', userId)
        .eq('token', token);

    _registeredUserId = null;
    _registeredToken = null;
  }

  void _openNotifications(RemoteMessage message) {
    if (_auth.currentUser == null || _navigatorKey?.currentState == null) {
      _pendingNotificationOpen = true;
      _pendingMessageData = message.data;
      return;
    }

    _pendingNotificationOpen = false;
    _pendingMessageData = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey?.currentState;
      if (navigator == null) return;
      unawaited(_openFor(navigator, message.data));
    });
  }

  /// Opens what the push is about: the look, the person, the chat or the
  /// finished AI look. Anything without a destination opens the
  /// notifications list.
  Future<void> _openFor(
    NavigatorState navigator,
    Map<String, dynamic>? data,
  ) async {
    navigator.popUntil((route) => route.isFirst);
    final type = (data?['type'] ?? '').toString();
    final opened = await openNotificationTarget(navigator.context, type, data);
    if (!opened && navigator.mounted) {
      navigator.pushNamed(AppRoutes.notifications);
    }
  }

  void _openPendingNotificationIfNeeded() {
    if (!_pendingNotificationOpen || _auth.currentUser == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pendingNotificationOpen || _auth.currentUser == null) return;
      _pendingNotificationOpen = false;
      final data = _pendingMessageData;
      _pendingMessageData = null;
      final navigator = _navigatorKey?.currentState;
      if (navigator == null) return;
      unawaited(_openFor(navigator, data));
    });
  }

  void _showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    AppToast.show(
      notification.body == null
          ? notification.title ?? 'New notification'
          : '${notification.title ?? 'Banigoba'}\n${notification.body}',
      actionLabel: 'View',
      onAction: () => _openNotifications(message),
    );
  }
}
