// Lets the signed-in user manage account details, profile photo, and address.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/settings/controllers/settings_controller.dart';
import 'package:banigoba/modules/settings/views/privacy_safety_section.dart';
import 'package:banigoba/modules/settings/widgets/settings_account_section.dart';
import 'package:banigoba/modules/settings/widgets/settings_preferences_sections.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<SettingsController>(
      init: SettingsController(),
      global: false,
      builder: (controller) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Obx(
          () => controller.loading.value
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsPhoto(controller: controller),
                      const SizedBox(height: 24),
                      SettingsAccountSection(controller: controller),
                      const SizedBox(height: 28),
                      SettingsPreferencesSections(controller: controller),
                      const PrivacySafetySection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
