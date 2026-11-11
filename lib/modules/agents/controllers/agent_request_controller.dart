// Sending a request to an agent.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/agents/models/agent_summary.dart';
import 'package:banigoba/modules/notifications/services/notification_service.dart';
import 'package:banigoba/modules/provider/services/request_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class AgentRequestController extends GetxController {
  AgentRequestController({required this.agent});

  final AgentSummary agent;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController service = TextEditingController();
  final TextEditingController date = TextEditingController();
  final TextEditingController budget = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController notes = TextEditingController();
  final RxBool saving = false.obs;

  @override
  void onClose() {
    for (final field in [service, date, budget, location, notes]) {
      field.dispose();
    }
    super.onClose();
  }

  Future<void> submit() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      AppToast.say('Sign in to request an agent.');
      return;
    }
    if (!formKey.currentState!.validate()) return;

    saving.value = true;
    try {
      await const RequestService(RequestKind.hair).create(
        customerId: user.uid,
        providerId: agent.id,
        details: {
          'agentName': agent.name,
          'agentType': agent.type,
          'customerName': user.displayName ?? user.email ?? 'Customer',
          'service': service.text.trim(),
          'preferredDate': date.text.trim(),
          'budget': budget.text.trim(),
          'location': location.text.trim(),
          'notes': notes.text.trim(),
        },
      );

      await NotificationService().addNotification(
        receiverId: agent.id,
        title: 'New agent request',
        body:
            '${user.displayName ?? user.email ?? 'A customer'} requested ${service.text.trim()}.',
        type: 'agent_request',
        extraData: {'agentId': agent.id, 'customerId': user.uid},
      );

      if (isClosed) return;
      AppToast.say('Agent request sent.');
      Get.back<void>();
    } catch (error) {
      AppToast.say('Unable to send request: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
