// The affirmation composer: which expressions are on offer, which one is
// picked, and sending it with the optional comment.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/utils/text_moderation.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/services/affirmation_service.dart';

class AffirmationComposerController extends GetxController {
  AffirmationComposerController({
    required this.targetType,
    required this.targetId,
    required this.targetOwnerId,
    required this.service,
  });

  final AffirmationTargetType targetType;
  final String targetId;
  final String targetOwnerId;
  final AffirmationService service;

  final TextEditingController message = TextEditingController();

  final Rx<List<AffirmationDefinition>> definitions =
      Rx<List<AffirmationDefinition>>(const []);
  final Rx<Set<String>> alreadySent = Rx<Set<String>>(const {});
  final Rxn<AffirmationDefinition> selected = Rxn<AffirmationDefinition>();
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    message.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    final loaded = await service.availableDefinitions();
    final sent = await service
        .watchOwnSent(targetType: targetType, targetId: targetId)
        .first;
    if (isClosed) return;
    definitions.value = loaded;
    alreadySent.value = sent;
    isLoading.value = false;
  }

  void toggle(AffirmationDefinition definition) {
    selected.value = selected.value?.id == definition.id ? null : definition;
  }

  /// Sends the picked affirmation; true when it went, false (with [error]
  /// set) when it did not.
  Future<bool> send() async {
    final pick = selected.value;
    if (pick == null || isSending.value) return false;

    isSending.value = true;
    error.value = '';

    try {
      await service.send(
        targetType: targetType,
        targetId: targetId,
        targetOwnerId: targetOwnerId,
        definition: pick,
        personalMessage: message.text,
      );
      return !isClosed;
    } on StateError catch (e) {
      return _fail(e.message);
    } on ModerationException catch (e) {
      return _fail(e.message);
    } on Exception catch (e) {
      return _fail('Unable to send that affirmation. $e');
    }
  }

  bool _fail(String text) {
    if (isClosed) return false;
    error.value = text;
    isSending.value = false;
    return false;
  }
}
