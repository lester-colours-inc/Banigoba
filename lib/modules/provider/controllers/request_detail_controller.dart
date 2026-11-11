// A design or hair request's answer buttons: accept, decline, complete.
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/views/request_detail_sheet.dart';

class RequestDetailController extends GetxController {
  RequestDetailController({required this.onRespond});

  final RespondToRequest onRespond;

  final RxBool busy = false.obs;
  final RxnString error = RxnString();

  Future<void> answer(String status) async {
    busy.value = true;
    error.value = null;
    try {
      await onRespond(status);
      if (!isClosed) Get.back<void>();
    } on Exception catch (e) {
      if (!isClosed) error.value = 'Could not save: $e';
    } finally {
      if (!isClosed) busy.value = false;
    }
  }
}
