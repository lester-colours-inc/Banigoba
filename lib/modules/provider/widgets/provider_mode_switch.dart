// The Customer / Provider switch at the top of the menu (S-1). Without a
// provider role it offers "Become a provider" instead.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/controllers/provider_mode_switch_controller.dart';

class ProviderModeSwitch extends StatelessWidget {
  const ProviderModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to the menu: created and disposed with the widget.
    return GetBuilder<ProviderModeSwitchController>(
      init: ProviderModeSwitchController(),
      global: false,
      builder: (controller) {
        if (controller.userId == null) return const SizedBox.shrink();
        return Obx(() {
          final data = controller.profile.value;
          if (data == null || data.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: controller.roles.isEmpty
                ? OutlinedButton.icon(
                    key: const ValueKey('become_provider'),
                    onPressed: controller.becomeProvider,
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Become a business'),
                  )
                : SegmentedButton<bool>(
                    key: const ValueKey('mode_switch'),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Customer')),
                      ButtonSegment(value: true, label: Text('Business')),
                    ],
                    selected: const {false},
                    onSelectionChanged: (choice) {
                      if (choice.first) controller.switchToBusiness();
                    },
                  ),
          );
        });
      },
    );
  }
}
