import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/onboarding/models/first_run_guide.dart';
import 'package:banigoba/modules/onboarding/services/guide_actions_contract.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class FirstRunGuideController extends GetxController {
  FirstRunGuideController({required this.actions});

  final GuideActions actions;

  final Rx<GuideProgress> progress = const GuideProgress().obs;
  final Rxn<GuideStep> busy = Rxn<GuideStep>();
  final RxBool leaving = false.obs;

  Future<void> run(GuideStep step, BuildContext context) async {
    if (busy.value != null || leaving.value) return;
    busy.value = step;
    try {
      final done = switch (step) {
        GuideStep.photo => await actions.addPhoto(context),
        GuideStep.style => await actions.pickStyle(context),
        GuideStep.wardrobe => await actions.addPiece(context),
        GuideStep.makeover => await actions.tryMakeover(context),
      };
      if (isClosed || !done) return;
      final current = progress.value;
      progress.value = switch (step) {
        GuideStep.photo => current.copyWith(photoDone: true),
        GuideStep.style => current.copyWith(styleDone: true),
        GuideStep.wardrobe => current.copyWith(
          wardrobeCount: current.wardrobeCount + 1,
        ),
        GuideStep.makeover => current.copyWith(makeoverTried: true),
      };
    } on Exception catch (error) {
      if (isClosed) return;
      AppToast.say('That did not work: $error. Try again.');
    } finally {
      if (!isClosed) busy.value = null;
    }
  }

  Future<void> leave() async {
    if (leaving.value) return;
    leaving.value = true;
    try {
      await actions.finish();
    } on Exception catch (error) {
      if (isClosed) return;
      leaving.value = false;
      AppToast.say('Could not continue: $error');
    }
  }
}
