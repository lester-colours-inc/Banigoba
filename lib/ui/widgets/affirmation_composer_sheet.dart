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

import '../../data/affirmations/affirmation_library.dart';
import '../../data/models/affirmation.dart';
import '../../data/models/text_moderation.dart';
import '../../data/services/affirmation_service.dart';
import 'quick_reply_bar.dart';

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

class AffirmationComposerSheet extends StatefulWidget {
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
  State<AffirmationComposerSheet> createState() =>
      _AffirmationComposerSheetState();
}

class _AffirmationComposerSheetState extends State<AffirmationComposerSheet> {
  final TextEditingController _messageController = TextEditingController();

  List<AffirmationDefinition> _definitions = const [];
  Set<String> _alreadySent = const {};
  AffirmationDefinition? _selected;
  bool _isLoading = true;
  bool _isSending = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final definitions = await widget.service.availableDefinitions();
    final sent = await widget.service
        .watchOwnSent(targetType: widget.targetType, targetId: widget.targetId)
        .first;
    if (!mounted) return;
    setState(() {
      _definitions = definitions;
      _alreadySent = sent;
      _isLoading = false;
    });
  }

  Future<void> _send() async {
    final selected = _selected;
    if (selected == null || _isSending) return;

    setState(() {
      _isSending = true;
      _error = '';
    });

    try {
      await widget.service.send(
        targetType: widget.targetType,
        targetId: widget.targetId,
        targetOwnerId: widget.targetOwnerId,
        definition: selected,
        personalMessage: _messageController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isSending = false;
      });
    } on ModerationException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _isSending = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to send that affirmation. $error';
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = groupAffirmationsByCategory(_definitions);

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
              'Affirm ${widget.recipientName}',
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

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final category in AffirmationCategory.values)
                if (grouped[category]?.isNotEmpty == true)
                  _buildCategory(category, grouped[category] ?? const []),

            if (_selected?.needsContextDisclosure == true)
              _buildContextDisclosure(_selected),

            const SizedBox(height: 8),
            QuickReplyBar(
              replies: [
                for (final reply in kQuickReplies)
                  if (reply.runes.length > 2) reply,
              ],
              onSelected: (reply) => _messageController.text = reply,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('affirmation_comment_field'),
              controller: _messageController,
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

            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selected == null || _isSending ? null : _send,
                icon: _isSending
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite_outline),
                label: Text(
                  _selected == null
                      ? 'Choose an affirmation'
                      : 'Send ${_selected?.shortLabel}',
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
  }

  Widget _buildCategory(
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
          children: definitions.map(_buildChip).toList(),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildChip(AffirmationDefinition definition) {
    final isSelected = _selected?.id == definition.id;
    final isSent = _alreadySent.contains(definition.id);

    return ChoiceChip(
      selected: isSelected,
      // Accessible label always accompanies the emoji, never replaces it.
      avatar: definition.emoji.isEmpty
          ? null
          : Text(definition.emoji, style: const TextStyle(fontSize: 16)),
      label: Text(definition.shortLabel),
      tooltip: isSent ? 'Already sent' : definition.text,
      onSelected: isSent
          ? null
          : (_) => setState(() {
              _selected = isSelected ? null : definition;
            }),
    );
  }

  Widget _buildContextDisclosure(AffirmationDefinition? definition) {
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
