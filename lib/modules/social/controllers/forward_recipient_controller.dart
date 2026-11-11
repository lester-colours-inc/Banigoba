// Choosing who to send a look to: the search text and My Circle edits.
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/social/services/circle_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class ForwardRecipientController extends GetxController {
  ForwardRecipientController({required this.recipients, CircleService? circle})
    : _circle = circle ?? CircleService();

  /// The verified salons, shops or designers on offer.
  final Future<List<Map<String, dynamic>>> recipients;

  final CircleService _circle;
  final String userId = AppAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<CircleMember>> members = _circle.watch(userId);

  /// The trimmed, lower-case search text.
  final RxString query = ''.obs;

  void onSearchChanged(String value) =>
      query.value = value.trim().toLowerCase();

  /// Adds [member] to My Circle, or removes it when [inCircle].
  Future<void> toggleCircle(
    CircleMember member, {
    required bool inCircle,
  }) async {
    try {
      if (inCircle) {
        await _circle.remove(userId, member.id);
      } else {
        await _circle.add(userId, member);
      }
    } on PostgrestException catch (error) {
      AppToast.say('Could not update My Circle: ${error.message}');
    }
  }
}
