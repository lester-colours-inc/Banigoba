// Sending a custom design request to a designer.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/provider/services/request_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class DesignRequestController extends GetxController {
  DesignRequestController({required this.designer});

  final DesignerSummary designer;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController occasion = TextEditingController();
  final TextEditingController budget = TextEditingController();
  final TextEditingController deadline = TextEditingController();
  final TextEditingController measurements = TextEditingController();
  final TextEditingController inspiration = TextEditingController();
  final TextEditingController notes = TextEditingController();
  final RxBool saving = false.obs;

  @override
  void onClose() {
    for (final field in [
      occasion,
      budget,
      deadline,
      measurements,
      inspiration,
      notes,
    ]) {
      field.dispose();
    }
    super.onClose();
  }

  Future<void> submit() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      AppToast.say('Sign in to request a custom design.');
      return;
    }
    if (!formKey.currentState!.validate()) return;

    saving.value = true;
    try {
      await const RequestService(RequestKind.design).create(
        customerId: user.uid,
        providerId: designer.id,
        details: {
          'designerName': designer.name,
          'customerName': user.displayName ?? user.email ?? 'Customer',
          'occasion': occasion.text.trim(),
          'budget': budget.text.trim(),
          'deadline': deadline.text.trim(),
          'measurements': measurements.text.trim(),
          'inspirationUrls': splitCsv(inspiration.text),
          'notes': notes.text.trim(),
        },
      );

      await NotificationService().addNotification(
        receiverId: designer.id,
        title: 'New custom design request',
        body:
            '${user.displayName ?? user.email ?? 'A customer'} requested a custom design.',
        type: 'designer_collection',
        extraData: {'customerId': user.uid, 'designerId': designer.id},
      );

      if (isClosed) return;
      AppToast.say('Custom design request sent.');
      Get.back<void>();
    } catch (error) {
      AppToast.say('Unable to send request: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
