// "Share my stock" form: what to share, in whose words, and who to tell.
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/shop/models/shop_link.dart';

class ShopLinkFormController extends GetxController {
  ShopLinkFormController({
    required this.ownerId,
    required this.shopName,
    required this.products,
    required this.onSubmit,
  });

  final String ownerId;
  final String shopName;

  /// The shop's own pieces, each with an 'id'.
  final List<Map<String, dynamic>> products;
  final Future<void> Function(ShopLink draft) onSubmit;

  final Rx<ShareScope> scope = ShareScope.all.obs;
  final RxString category = ''.obs;
  final RxList<String> picked = <String>[].obs;
  final Rx<ShareAudience> audience = ShareAudience.linkOnly.obs;
  final TextEditingController title = TextEditingController();
  final TextEditingController note = TextEditingController();
  final RxBool busy = false.obs;
  final RxnString error = RxnString();

  @override
  void onClose() {
    title.dispose();
    note.dispose();
    super.onClose();
  }

  List<String> get categories {
    final found = <String>{};
    for (final product in products) {
      final value = (product['category'] ?? '').toString().trim();
      if (value.isNotEmpty) found.add(value.toLowerCase());
    }
    return found.toList()..sort();
  }

  String idOf(Map<String, dynamic> product) => (product['id'] ?? '').toString();

  String imageOf(Map<String, dynamic> product) =>
      (product['rawImageUrl'] ?? product['imageUrl'] ?? '').toString();

  void chooseScope(ShareScope next) {
    scope.value = next;
    error.value = null;
  }

  void chooseCategory(String next) => category.value = next;

  void chooseAudience(ShareAudience next) => audience.value = next;

  void setPicked(String id, {required bool on}) {
    if (on) {
      picked.add(id);
    } else {
      picked.remove(id);
    }
  }

  ShopLink _draft() {
    final base = ShopLink(
      id: '',
      ownerId: ownerId,
      shopName: shopName,
      title: '',
      scope: scope.value,
      category: category.value,
      productIds: List.unmodifiable(picked),
      audience: audience.value,
    );
    final covered = switch (scope.value) {
      ShareScope.all => products,
      ShareScope.category => products.where(
        (p) => (p['category'] ?? '').toString().toLowerCase() == category.value,
      ),
      ShareScope.items => [
        for (final id in picked) ...products.where((p) => idOf(p) == id),
      ],
    };
    final cover = covered
        .map(imageOf)
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');
    return ShopLink(
      id: '',
      ownerId: base.ownerId,
      shopName: base.shopName,
      title: title.text.trim().isEmpty ? base.scopeLabel : title.text.trim(),
      note: note.text.trim(),
      scope: base.scope,
      category: base.category,
      productIds: base.productIds,
      audience: base.audience,
      coverImageUrl: cover,
    );
  }

  Future<void> submit() async {
    final draft = _draft();
    final problem = validateShopLink(
      title: draft.title,
      note: draft.note,
      scope: scope.value,
      category: category.value,
      productIds: picked,
    );
    if (problem != null) {
      error.value = problem;
      return;
    }
    busy.value = true;
    error.value = null;
    try {
      await onSubmit(draft);
    } on Exception catch (e) {
      if (!isClosed) error.value = 'Could not create the link: $e';
    } finally {
      if (!isClosed) busy.value = false;
    }
  }
}
