// Fashion Designers: browse designers and your requests as a customer, or
// manage your designer profile and incoming requests as a designer.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/designers/controllers/fashion_designers_controller.dart';
import 'package:banigoba/modules/designers/widgets/designer_workspace.dart';
import 'package:banigoba/modules/designers/widgets/designers_customer_view.dart';

export 'package:banigoba/modules/designers/views/designer_detail_page.dart'
    show DesignerDetailPage;
export 'package:banigoba/modules/designers/views/designer_profile_editor_page.dart'
    show DesignerProfileEditorPage;

class FashionDesignersPage extends StatelessWidget {
  const FashionDesignersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<FashionDesignersController>(
      init: FashionDesignersController(),
      global: false,
      builder: (controller) => _DesignersView(controller: controller),
    );
  }
}

class _DesignersView extends StatelessWidget {
  const _DesignersView({required this.controller});

  final FashionDesignersController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Fashion Designers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Obx(
              () => SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.shopping_bag_outlined),
                    label: Text('Customer'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.design_services_outlined),
                    label: Text('Designer'),
                  ),
                ],
                selected: {controller.view.value},
                onSelectionChanged: (value) => controller.setView(value.first),
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => controller.view.value == 0
                  ? DesignersCustomerView(controller: controller)
                  : DesignerWorkspace(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}
