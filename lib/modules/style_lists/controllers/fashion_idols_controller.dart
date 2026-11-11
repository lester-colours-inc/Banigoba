// My Fashion Idols: the idols list and adding one by name.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/views/makeover_page.dart';
import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class FashionIdolsController extends GetxController {
  FashionIdolsController({StyleListsService? lists})
    : lists = lists ?? StyleListsService();

  final StyleListsService lists;
  final String userId = AppAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<StyleListEntry>> idols = lists.watch(
    userId,
    StyleList.idols,
  );

  final TextEditingController name = TextEditingController();

  /// Mirrors [name], so the Add button follows typing.
  final RxString typed = ''.obs;

  bool get canAdd => idolIdFor(typed.value).isNotEmpty;

  @override
  void onClose() {
    name.dispose();
    super.onClose();
  }

  Future<void> addIdol() async {
    final text = name.text.trim();
    final id = idolIdFor(text);
    if (id.isEmpty) return;
    try {
      await lists.add(
        userId,
        StyleList.idols,
        StyleListEntry(id: id, name: text),
      );
      name.clear();
      typed.value = '';
    } on PostgrestException catch (error) {
      AppToast.say('Could not add $text: ${error.message}');
    }
  }

  void removeIdol(String id) => lists.remove(userId, StyleList.idols, id);

  void styleMeLike(String idolName) =>
      Get.to<void>(() => MakeoverPage(initialIdolName: idolName));
}
