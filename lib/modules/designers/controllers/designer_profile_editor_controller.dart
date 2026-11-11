// The designer's own profile: details and the portfolio pieces being edited.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/designers/models/designer_summary.dart';
import 'package:banigoba/modules/designers/models/portfolio_piece_entry.dart';
import 'package:banigoba/modules/provider/models/portfolio_piece.dart';
import 'package:banigoba/modules/social/services/profile_service.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class DesignerProfileEditorController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController bio = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController specialties = TextEditingController();
  final TextEditingController priceRange = TextEditingController();
  final RxList<PortfolioPieceEntry> pieces = <PortfolioPieceEntry>[].obs;
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  @override
  void onClose() {
    for (final field in [name, bio, location, specialties, priceRange]) {
      field.dispose();
    }
    for (final piece in pieces) {
      piece.dispose();
    }
    super.onClose();
  }

  Future<void> _loadProfile() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      loading.value = false;
      return;
    }
    final data = await ProfileService().get(user.uid);
    final profile = Map<String, dynamic>.from(
      data['designerProfile'] as Map? ?? const {},
    );
    name.text =
        (profile['name'] ?? data['displayName'] ?? user.displayName ?? '')
            .toString();
    bio.text = (profile['bio'] ?? '').toString();
    location.text = (profile['location'] ?? '').toString();
    specialties.text = toStringList(profile['specialties']).join(', ');
    priceRange.text = (profile['priceRange'] ?? '').toString();
    pieces.addAll(
      PortfolioPiece.listFromProfile(
        profile,
      ).map((piece) => PortfolioPieceEntry(piece: piece)),
    );
    if (!isClosed) loading.value = false;
  }

  void addPiece() => pieces.add(
    PortfolioPieceEntry(piece: const PortfolioPiece(imageUrl: '')),
  );

  void removePiece(int index) => pieces.removeAt(index).dispose();

  Future<void> save() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      AppToast.say('Sign in to create a designer profile.');
      return;
    }
    if (!formKey.currentState!.validate()) return;

    saving.value = true;
    try {
      final saved = pieces
          .map((entry) => entry.toPiece())
          .where((piece) => !piece.isEmpty)
          .toList();
      await ProfileService().mergeSection(user.uid, 'designerProfile', {
        'active': true,
        'name': name.text.trim(),
        'bio': bio.text.trim(),
        'location': location.text.trim(),
        'specialties': splitCsv(specialties.text),
        'priceRange': priceRange.text.trim(),
        'portfolioPieces': saved.map((piece) => piece.toMap()).toList(),
        // Kept so anything still reading the flat list (and this editor,
        // for a profile last saved before pieces existed) sees the same
        // pictures.
        'portfolioImages': saved
            .map((piece) => piece.imageUrl)
            .where((url) => url.isNotEmpty)
            .toList(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });

      if (isClosed) return;
      AppToast.say('Designer profile saved.');
      Get.back<void>();
    } catch (error) {
      AppToast.say('Unable to save profile: $error');
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
