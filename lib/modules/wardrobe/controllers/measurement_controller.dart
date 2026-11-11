// Body-proportion calibration: slider values and saving them.
import 'dart:typed_data';

import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/core/supabase/supabase_config.dart';
import 'package:banigoba/modules/makeover/views/style_selection_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class MeasurementController extends GetxController {
  MeasurementController({
    this.imageBytes,
    this.imageUrl,
    this.plannedDate,
    this.eventId,
    this.eventName,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;

  final RxDouble height = 0.68.obs;
  final RxDouble waist = 0.48.obs;
  final RxDouble shoulders = 0.46.obs;
  final RxBool isSaving = false.obs;

  bool get hasSourceImage => imageBytes != null || imageUrl != null;

  Future<void> confirm() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final user = AppAuth.instance.currentUser;
      if (user != null) {
        await supabase.from('user_documents').upsert({
          'user_id': user.uid,
          'kind': 'bodyCalibration',
          'id': 'latest',
          'data': {
            'height': height.value,
            'waist': waist.value,
            'shoulders': shoulders.value,
          },
        });
      }
      if (isClosed) return;
      if (hasSourceImage) {
        await Get.off<void>(
          () => StyleSelectionPage(
            imageBytes: imageBytes,
            imageUrl: imageUrl,
            plannedDate: plannedDate,
            eventId: eventId,
            eventName: eventName,
          ),
        );
      } else {
        AppToast.say('Measurements saved successfully.');
        Get.back<void>();
      }
    } catch (error) {
      if (!isClosed) AppToast.say('Unable to save measurements: $error');
    } finally {
      if (!isClosed) isSaving.value = false;
    }
  }
}
