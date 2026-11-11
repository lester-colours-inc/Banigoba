// An agent edits their public profile.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/agents/models/agent_summary.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class AgentProfileEditorController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController bio = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController services = TextEditingController();
  final TextEditingController rate = TextEditingController();
  final RxString type = 'hair'.obs;
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  @override
  void onClose() {
    for (final field in [name, bio, location, services, rate]) {
      field.dispose();
    }
    super.onClose();
  }

  void setType(String value) => type.value = value;

  Future<void> _loadProfile() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      loading.value = false;
      return;
    }
    final data = await ProfileService().get(user.uid);
    final profile = Map<String, dynamic>.from(
      data['agentProfile'] as Map? ?? const {},
    );
    type.value = (profile['type'] ?? 'hair').toString() == 'clothes'
        ? 'clothes'
        : 'hair';
    name.text =
        (profile['name'] ?? data['displayName'] ?? user.displayName ?? '')
            .toString();
    bio.text = (profile['bio'] ?? '').toString();
    location.text = (profile['location'] ?? '').toString();
    services.text = toStringList(profile['services']).join(', ');
    rate.text = (profile['rate'] ?? '').toString();
    if (!isClosed) loading.value = false;
  }

  Future<void> save() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      AppToast.say('Sign in to create an agent profile.');
      return;
    }
    if (!formKey.currentState!.validate()) return;

    saving.value = true;
    try {
      await ProfileService().mergeSection(user.uid, 'agentProfile', {
        'active': true,
        'type': type.value,
        'name': name.text.trim(),
        'bio': bio.text.trim(),
        'location': location.text.trim(),
        'services': splitCsv(services.text),
        'rate': rate.text.trim(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

      if (isClosed) return;
      AppToast.say('Agent profile saved.');
      Get.back<void>();
    } catch (error) {
      AppToast.say('Unable to save profile: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
