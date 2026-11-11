// Verification of designer / shop / agent profiles: the list, and the
// verify / unverify action.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class ProfileVerificationController extends GetxController {
  ProfileVerificationController({
    required this.profileField,
    required this.titleFallback,
    this.requireActive = true,
  });

  final String profileField;
  final String titleFallback;
  final bool requireActive;

  final RxList<Map<String, dynamic>> profiles = <Map<String, dynamic>>[].obs;
  final RxBool loaded = false.obs;
  final RxBool failed = false.obs;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = ProfileService().watchAll().listen((rows) {
      failed.value = false;
      profiles.assignAll(_visible(rows));
      loaded.value = true;
    }, onError: (Object _) => failed.value = true);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Map<String, dynamic> profileOf(Map<String, dynamic> user) =>
      Map<String, dynamic>.from(user[profileField] as Map? ?? const {});

  /// Each provider type stores its public profile on a different nested
  /// field, but the verification card renders all of them in the same shape.
  List<Map<String, dynamic>> _visible(List<Map<String, dynamic>> rows) {
    return rows.where((doc) {
      final profile = profileOf(doc);
      if (profile.isEmpty) return false;
      final name = (profile['name'] ?? '').toString().trim();
      final hasProfile =
          name.isNotEmpty ||
          (profile['description'] ?? '').toString().trim().isNotEmpty ||
          (profile['bio'] ?? '').toString().trim().isNotEmpty;
      if (!hasProfile) return false;
      return !requireActive || profile['active'] == true;
    }).toList()..sort(
      (a, b) => nameOf(profileOf(a), a).compareTo(nameOf(profileOf(b), b)),
    );
  }

  String nameOf(Map<String, dynamic> profile, Map<String, dynamic> user) {
    return (profile['name'] ??
            profile['shopName'] ??
            user['displayName'] ??
            titleFallback)
        .toString();
  }

  static String subtitleOf(Map<String, dynamic> profile) {
    final parts = [
      profile['type'],
      profile['location'],
      profile['description'],
      profile['bio'],
    ].map((value) => value?.toString().trim() ?? '').where((v) => v.isNotEmpty);
    return parts.take(3).join(' • ');
  }

  Future<void> setVerified({
    required String userId,
    required String title,
    required bool value,
  }) async {
    try {
      final adminId = AppAuth.instance.currentUser?.uid;
      // The profile map (e.g. shop) carries the details marketplace screens
      // read; `verified` itself is a guarded column only curators can set.
      final service = ProfileService();
      final current = await service.get(userId);
      await service.update(userId, {
        profileField: {
          ...Map<String, dynamic>.from(current[profileField] as Map? ?? {}),
          'verified': value,
          'verificationStatus': value ? 'verified' : 'unverified',
          'verifiedAt': value ? DateTime.now().toUtc().toIso8601String() : null,
          'verifiedBy': value ? adminId : null,
        },
      });

      if (value && profileField == 'shop') {
        try {
          // Approval should succeed even if the notification write is denied,
          // so keep this secondary side effect isolated.
          await NotificationService().addNotification(
            receiverId: userId,
            title: 'Boutique approved',
            body:
                'approved your boutique. Customers can now discover your shop.',
            type: 'shop_approval',
            extraData: {
              'fromId': adminId,
              'fromName': 'Curators Workspace',
              'sellerId': userId,
              'shopName': title,
            },
          );
        } catch (error) {
          debugPrint('Shop approval notification failed: $error');
        }
      }

      if (isClosed) return;
      AppToast.say(
        value
            ? '$title verified successfully.'
            : '$title verification removed.',
      );
    } catch (error) {
      if (!isClosed) AppToast.say('Unable to update verification: $error');
    }
  }
}
