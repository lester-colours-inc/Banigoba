// The kind filter on the "Orders & requests" list (null means all).
import 'package:get/get.dart';

import 'package:banigoba/modules/provider/models/provider_inbox.dart';

class ProviderInboxFilterController extends GetxController {
  final Rxn<InboxKind> only = Rxn<InboxKind>();

  void select(InboxKind? kind) => only.value = kind;
}
