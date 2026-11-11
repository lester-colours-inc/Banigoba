// The original coordinated clothing-and-hair makeover, built on chosen
// catalogue items.
//
// Superseded as the entry point by MakeoverPage (Phase 3), which starts from
// the user's photo and an idea rather than products. Kept because choosing
// real items to try on is what "Get this look" (Phase 5) will need; it is
// reachable at AppRoutes.makeoverWithItems.
//
// Covers UI-04 (intent) through UI-09 (save and visibility) from BNG SRS 001,
// and the JRN-01 journey. Clothing and hair are presented as equal sections of
// a single brief, never as two separate products, and either can be refined
// afterwards without discarding the other's selection.
//
// Deliberately absent: any score, rating, ranking or "best look" marker. The
// compare step offers alternatives and an explanation of what changed.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/makeover/controllers/create_makeover_controller.dart';
import 'package:banigoba/modules/makeover/widgets/create_makeover_brief.dart';
import 'package:banigoba/modules/makeover/widgets/create_makeover_compare.dart';
import 'package:banigoba/modules/makeover/widgets/create_makeover_progress.dart';

class CreateMakeoverPage extends GetView<CreateMakeoverController> {
  const CreateMakeoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text(
          'Create your look',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Obx(
          () => controller.step.value == CreateStep.brief
              ? const BackButton()
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: controller.isBusy.value
                      ? null
                      : () => controller.goTo(CreateStep.brief),
                ),
        ),
      ),
      body: Obx(
        () => switch (controller.step.value) {
          CreateStep.brief => CreateMakeoverBrief(controller: controller),
          CreateStep.generating => CreateMakeoverProgress(
            controller: controller,
          ),
          CreateStep.compare => CreateMakeoverCompare(controller: controller),
        },
      ),
    );
  }
}
