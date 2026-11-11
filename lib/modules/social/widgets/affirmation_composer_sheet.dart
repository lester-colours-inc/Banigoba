// UI-10 Affirmation composer.
//
// Presents reviewed expressions grouped by category, plus an optional personal
// message. There is no rating, no score and no slider: the sender picks an
// expression and sends it. Where an expression carries cultural meaning, that
// meaning and its provenance are shown before it can be sent.
//
// Affirming and commenting are one action: the optional comment travels with
// the affirmation, and the quick-reply words fill it in with one tap.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/models/affirmation_library.dart';
import 'package:banigoba/modules/social/models/affirmation.dart';
import 'package:banigoba/modules/social/controllers/affirmation_composer_controller.dart';
import 'package:banigoba/modules/social/services/affirmation_service.dart';
import 'package:banigoba/modules/social/widgets/quick_reply_bar.dart';

/// Opens the composer. Returns true when an affirmation was sent.
Future<bool> showAffirmationComposer(
  BuildContext context, {
  required AffirmationTargetType targetType,
  required String targetId,
  required String targetOwnerId,
  required String recipientName,
  AffirmationService? service,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => AffirmationComposerSheet(
      targetType: targetType,
      targetId: targetId,
      targetOwnerId: targetOwnerId,
      recipientName: recipientName,
      service: service ?? AffirmationService(),
    ),
  );
  return sent ?? false;
}

class AffirmationComposerSheet extends StatelessWidget {
  const AffirmationComposerSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetOwnerId,
    required this.recipientName,
    required this.service,
  });

  final AffirmationTargetType targetType;
  final String targetId;
  final String targetOwnerId;
  final String recipientName;
  final AffirmationService service;

  @override
  Widget build(BuildContext context) {
    // Scoped to this sheet: created and disposed with the widget.
    return GetBuilder<AffirmationComposerController>(
      init: AffirmationComposerController(
        targetType: targetType,
        targetId: targetId,
        targetOwnerId: targetOwnerId,
        service: service,
      ),
      global: false,
      builder: (controller) =>
          _ComposerView(controller: controller, recipientName: recipientName),
    );
  }
}

class _ComposerView extends StatelessWidget {
  const _ComposerView({required this.controller, required this.recipientName});

  final AffirmationComposerController controller;
  final String recipientName;

  Future<void> _send(BuildContext context) async {
    final sent = await controller.send();
    if (sent && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final grouped = groupAffirmationsByCategory(controller.definitions.value);
      final selected = controller.selected.value;
      final error = controller.error.value;
      final isSending = controller.isSending.value;
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Affirm $recipientName',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to celebrate this look.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              if (controller.isLoading.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final category in AffirmationCategory.values)
                  if (grouped[category]?.isNotEmpty == true)
                    _buildCategory(
                      context,
                      category,
                      grouped[category] ?? const [],
                    ),

              if (selected?.needsContextDisclosure == true)
                _buildContextDisclosure(context, selected),

              const SizedBox(height: 8),
              QuickReplyBar(
                replies: [
                  for (final reply in kQuickReplies)
                    if (reply.runes.length > 2) reply,
                ],
                onSelected: (reply) => controller.message.text = reply,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('affirmation_comment_field'),
                controller: controller.message,
                maxLines: 3,
                minLines: 2,
                maxLength: 280,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Add a comment (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selected == null || isSending
                      ? null
                      : () => _send(context),
                  icon: isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite_outline),
                  label: Text(
                    selected == null
                        ? 'Choose an affirmation'
                        : 'Send ${selected.shortLabel}',
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Affirmations are shown to the person who created the look. '
                'They are never totalled into a public score.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategory(
    BuildContext context,
    AffirmationCategory category,
    List<AffirmationDefinition> definitions,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final d in definitions) _buildChip(d)],
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildChip(AffirmationDefinition definition) {
    final isSelected = controller.selected.value?.id == definition.id;
    final isSent = controller.alreadySent.value.contains(definition.id);

    return ChoiceChip(
      selected: isSelected,
      // Accessible label always accompanies the emoji, never replaces it.
      avatar: definition.emoji.isEmpty
          ? null
          : Text(definition.emoji, style: const TextStyle(fontSize: 16)),
      label: Text(definition.shortLabel),
      tooltip: isSent ? 'Already sent' : definition.text,
      onSelected: isSent ? null : (_) => controller.toggle(definition),
    );
  }

  Widget _buildContextDisclosure(
    BuildContext context,
    AffirmationDefinition? definition,
  ) {
    if (definition == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final lines = <String>[
      if (definition.translation.isNotEmpty)
        'Translation: ${definition.translation}',
      if (definition.meaning.isNotEmpty) 'Meaning: ${definition.meaning}',
      if (definition.language.isNotEmpty) 'Language: ${definition.language}',
      if (definition.culture.isNotEmpty) 'Culture: ${definition.culture}',
      if (definition.provenance.historicalSource.isNotEmpty)
        'Source: ${definition.provenance.historicalSource}',
      if (definition.provenance.contributor.isNotEmpty)
        'Contributed by: ${definition.provenance.contributor}',
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(line, style: theme.textTheme.bodySmall),
              ),
            )
            .toList(),
      ),
    );
  }
}
