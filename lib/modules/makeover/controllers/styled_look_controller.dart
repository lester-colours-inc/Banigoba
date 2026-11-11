// Saving the generated styled look to the wardrobe.
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/makeover/services/makeover_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class StyledLookController extends GetxController {
  StyledLookController({
    required this.style,
    required this.sourceImageUrl,
    required this.generatedImageUrls,
    MakeoverService? makeoverService,
  }) : _makeoverService = makeoverService ?? MakeoverService();

  final String style;
  final String sourceImageUrl;
  final List<String> generatedImageUrls;
  final MakeoverService _makeoverService;

  final RxBool isSaving = false.obs;

  String get mainImageUrl =>
      generatedImageUrls.isNotEmpty ? generatedImageUrls.first : sourceImageUrl;

  void openCart() => Get.toNamed<void>(AppRoutes.cart);

  Future<void> saveLook() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      AppToast.say('You must be signed in to save your look.');
      return;
    }

    isSaving.value = true;
    try {
      await _makeoverService.saveGeneratedMakeover(
        userId: user.uid,
        style: style,
        generatedImageUrls: generatedImageUrls,
        sourceImageUrl: sourceImageUrl,
      );
      if (!isClosed) {
        AppToast.say('Your AI makeover has been saved to your wardrobe.');
      }
    } catch (e) {
      if (!isClosed) AppToast.say('Failed to save look: $e');
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }
}
