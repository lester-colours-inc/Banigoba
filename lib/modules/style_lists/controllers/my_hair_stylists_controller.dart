// My Hair Stylists: salons in My Circle, liked hairstyles and trying them on.
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/core/services/image_crop.dart';
import 'package:banigoba/core/services/storage_service.dart';
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/views/makeover_page.dart';
import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/social/services/circle_service.dart';
import 'package:banigoba/modules/social/widgets/forward_recipient_sheet.dart';
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class MyHairStylistsController extends GetxController {
  final StyleListsService _lists = StyleListsService();
  final CircleService _circle = CircleService();
  final ImagePicker _picker = ImagePicker();
  final String userId = AppAuth.instance.currentUser?.uid ?? '';

  late final Stream<List<CircleMember>> members = _circle.watch(userId);
  late final Stream<List<StyleListEntry>> hairstyles = _lists.watch(
    userId,
    StyleList.hairstyles,
  );
  final RxBool uploading = false.obs;

  Future<void> findSalon() async {
    final context = Get.context;
    if (context == null) return;
    final salon = await showForwardRecipientSheet(
      context,
      ForwardRecipientKind.salon,
      title: 'Add a salon to My Circle',
    );
    if (salon == null) return;
    try {
      await _circle.add(userId, salon.toCircleMember(CircleKind.salon));
      AppToast.say('${salon.name} is in My Circle.');
    } on PostgrestException catch (error) {
      AppToast.say('Could not add ${salon.name}: ${error.message}');
    }
  }

  void removeSalon(String id) => _circle.remove(userId, id);

  void removeHairstyle(String id) =>
      _lists.remove(userId, StyleList.hairstyles, id);

  Future<void> addHairstyle(ImageSource source) async {
    final picked = await _picker.pickAndCropImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    uploading.value = true;
    try {
      final url = await StorageService().uploadHairInspirationBytes(
        await picked.readAsBytes(),
        userId,
      );
      await _lists.add(
        userId,
        StyleList.hairstyles,
        StyleListEntry(id: '', name: '', imageUrl: url),
      );
    } on PostgrestException catch (error) {
      AppToast.say('Could not add that photo: ${error.message}');
    } finally {
      if (!isClosed) uploading.value = false;
    }
  }

  void tryOnMe(String imageUrl) => Get.to<void>(
    () => MakeoverPage(initialScope: LookScope.hair, initialTwinUrl: imageUrl),
  );

  void newHairstyle() =>
      Get.to<void>(() => const MakeoverPage(initialScope: LookScope.hair));
}
