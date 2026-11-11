// The public list of approved events; clears expired ones when it opens.
import 'package:get/get.dart';

import 'package:banigoba/modules/events/services/event_service.dart';

class ApprovedEventsController extends GetxController {
  ApprovedEventsController({EventService? service})
    : service = service ?? EventService();

  final EventService service;

  @override
  void onInit() {
    super.onInit();
    service.removeExpiredEvents();
  }
}
