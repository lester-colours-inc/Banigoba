// Writing the words for a quote: the text, who it goes to, and whether it
// can be posted.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/models/post.dart';

class QuoteController extends GetxController {
  QuoteController({
    this.maxLength = 280,
    PostVisibility audience = PostVisibility.public,
  }) : audience = audience.obs;

  final int maxLength;
  final TextEditingController text = TextEditingController();

  /// Mirrors [text] so the view reacts to typing.
  final RxString typed = ''.obs;

  /// Who sees the quote. A quote is never private.
  final Rx<PostVisibility> audience;

  bool get canPost => typed.value.trim().isNotEmpty;

  /// How much of [maxLength] is used, 0..1, for the counter ring.
  double get used => (typed.value.length / maxLength).clamp(0, 1).toDouble();

  int get remaining => maxLength - typed.value.length;

  void chooseAudience(PostVisibility? chosen) {
    if (chosen == null || chosen == PostVisibility.private) return;
    audience.value = chosen;
  }

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }
}
