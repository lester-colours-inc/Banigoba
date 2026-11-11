// The Makeover flow, opened from Home's floating Makeover button.
//
// Phase 3 of the work plan, reworked after the September 2026 feedback:
//   1. Brief     — your photo, what should change, and how (Describe · Style
//                  idol · Style twin · Weather · Trending)
//   2. Styling   — one item at a time (hair, clothes, shoes, accessories).
//                  Each result shows as soon as it exists; the user keeps it,
//                  redoes it, tweaks it, skips it or goes back. A new step
//                  only generates when the user presses "Style my ..."
//   3. Done      — save or share, find the pieces, or edit something
//
// Also opened from a saved look on Home to edit it ([editingPostId]), and
// from someone's post to copy it as a style twin ([initialTwinUrl]).
//
// There is no product catalogue here: people see themselves first and buy
// afterwards ("Find pieces", then "Get this look" in Phase 5).
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/home/models/weather.dart';
import 'package:banigoba/modules/makeover/controllers/makeover_controller.dart';
import 'package:banigoba/modules/makeover/services/look_generation_service.dart';
import 'package:banigoba/modules/makeover/widgets/ai_photo_consent.dart';
import 'package:banigoba/modules/makeover/widgets/look_done_view.dart';
import 'package:banigoba/modules/makeover/widgets/look_source_picker.dart';
import 'package:banigoba/modules/makeover/widgets/look_step_view.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_brief.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_controls.dart';
import 'package:banigoba/modules/profile_details/models/body_profile.dart';
import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/core/main_tab.dart';
import 'package:banigoba/shared/widgets/app_drawer.dart';
import 'package:banigoba/shared/widgets/bottom_navigation.dart';

class MakeoverPage extends StatelessWidget {
  const MakeoverPage({
    super.key,
    this.generationService,
    this.initialPhotoUrl,
    this.initialScope,
    this.loadWeather,
    this.editingPostId,
    this.initialTwinUrl,
    this.initialMethod,
    this.initialIdolName,
    this.loadBodyProfile,
    this.confirmAiUse = ensureAiPhotoConsent,
  });

  /// Asks before photos go to the AI (App Store 5.1.2); injected in tests.
  final Future<bool> Function(BuildContext context) confirmAiUse;

  /// Injected in tests; defaults to Gemini.
  final LookGenerationService? generationService;

  /// Skips loading the user's latest photo when given. When editing, this is
  /// the saved look.
  final String? initialPhotoUrl;

  /// Skips reading the saved makeover preference when given (tests).
  final LookScope? initialScope;

  /// Injected in tests; defaults to device location + WeatherService.
  final Future<Weather?> Function()? loadWeather;

  /// The saved look being edited, so saving can update it in place.
  final String? editingPostId;

  /// Starts on Style twin with this look to copy.
  final String? initialTwinUrl;

  /// Starts on this idea source, e.g. Style idol for "My Fashion Idols".
  final LookMethod? initialMethod;

  /// Starts on Style idol with this person filled in ("Style me like …"
  /// from My Fashion Idols).
  final String? initialIdolName;

  /// Injected in tests; defaults to the signed-in user's profile details.
  final Future<BodyProfile> Function()? loadBodyProfile;

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: built from its parameters, disposed with it.
    return GetBuilder<MakeoverController>(
      init: MakeoverController(
        confirmAiUse: confirmAiUse,
        context: () => context,
        generationService: generationService,
        initialPhotoUrl: initialPhotoUrl,
        initialScope: initialScope,
        loadWeather: loadWeather,
        editingPostId: editingPostId,
        initialTwinUrl: initialTwinUrl,
        initialMethod: initialMethod,
        initialIdolName: initialIdolName,
        loadBodyProfile: loadBodyProfile,
      ),
      global: false,
      builder: (controller) => _MakeoverView(controller: controller),
    );
  }
}

class _MakeoverView extends StatelessWidget {
  const _MakeoverView({required this.controller});

  final MakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: controller.phase.value == MakeoverPhase.brief,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.handleBack();
        },
        child: Scaffold(
          drawer: const AppDrawer(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(controller: controller),
              Expanded(child: _Stage(controller: controller)),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.phase.value == MakeoverPhase.brief)
                MakeoverGenerateBar(controller: controller),
              CustomBottomNavigation(
                currentIndex: MainTab.home.index,
                onTap: controller.openMainTab,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final MakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = controller.session.value;
      return MakeoverHeader(
        title: controller.title,
        onBack: controller.handleBack,
        trailing:
            controller.phase.value == MakeoverPhase.styling && session != null
            ? TextButton(
                key: const ValueKey('makeover_finish_now'),
                onPressed: session.changedParts.isEmpty
                    ? null
                    : () => controller.finish(session),
                style: TextButton.styleFrom(foregroundColor: kMakeoverNavy),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              )
            : null,
      );
    });
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.controller});

  final MakeoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = controller.session.value;
      return switch (controller.phase.value) {
        MakeoverPhase.brief => MakeoverBrief(controller: controller),
        MakeoverPhase.styling when session != null => LookStepView(
          session: session,
          isGenerating: controller.isGenerating.value,
          elapsedSeconds: controller.elapsedSeconds.value,
          errorMessage: controller.error.value,
          onKeep: controller.keep,
          onTryAgain: controller.generateCurrent,
          onTweak: controller.tweakCurrent,
          onSkip: controller.skip,
          onUndo: controller.undo,
          onJumpTo: controller.jumpTo,
          onGenerate: controller.generateCurrent,
        ),
        MakeoverPhase.styling => const SizedBox.shrink(),
        MakeoverPhase.done => LookDoneView(
          beforeUrl: controller.photoUrl.value,
          afterUrl: controller.finalUrl.value,
          changedParts: controller.changedParts.value,
          isEditingSavedLook: controller.isEditing,
          onSave: controller.save,
          onFindPieces: controller.findPieces,
          onEdit: controller.editLook,
          onNewIdea: controller.newIdea,
          onStartAgain: controller.startAgain,
        ),
      };
    });
  }
}
