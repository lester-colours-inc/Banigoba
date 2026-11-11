// The finished look, compared with the original photo, and what people
// naturally do next: save or share it, find the pieces, or change something.
import 'package:flutter/material.dart';

import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/makeover/widgets/before_after_view.dart';
import 'package:banigoba/modules/makeover/widgets/makeover_controls.dart';

class LookDoneView extends StatelessWidget {
  const LookDoneView({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    required this.changedParts,
    required this.onSave,
    required this.onFindPieces,
    required this.onEdit,
    required this.onNewIdea,
    required this.onStartAgain,
    this.isEditingSavedLook = false,
  });

  final String beforeUrl;
  final String afterUrl;
  final List<LookPart> changedParts;
  final VoidCallback onSave;
  final VoidCallback onFindPieces;
  final VoidCallback onEdit;
  final VoidCallback onNewIdea;
  final VoidCallback onStartAgain;
  final bool isEditingSavedLook;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        BeforeAfterView(beforeImageUrl: beforeUrl, afterImageUrl: afterUrl),
        if (changedParts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Changed: ${changedParts.map((part) => part.label).join(' · ')}',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
        ],
        const SizedBox(height: 18),
        MakeoverPrimaryButton(
          key: const ValueKey('makeover_save'),
          icon: Icons.bookmark_add_outlined,
          label: isEditingSavedLook ? 'Save changes' : 'Save this look',
          onPressed: onSave,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: MakeoverIconAction(
                key: const ValueKey('makeover_find_pieces'),
                icon: Icons.shopping_bag_outlined,
                label: 'Place Order',
                onTap: onFindPieces,
              ),
            ),
            Expanded(
              child: MakeoverIconAction(
                key: const ValueKey('makeover_edit'),
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: onEdit,
              ),
            ),
            Expanded(
              child: MakeoverIconAction(
                key: const ValueKey('makeover_new_idea'),
                icon: Icons.tune,
                label: 'New idea',
                onTap: onNewIdea,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            key: const ValueKey('makeover_start_again'),
            onPressed: onStartAgain,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Start again with the same idea'),
          ),
        ),
      ],
    );
  }
}

/// What the user wants to change about a look, from [showLookEditSheet].
@immutable
class LookEdit {
  const LookEdit({required this.part, this.note = ''});

  final LookPart part;
  final String note;
}

/// Asks what to change and how.
///
/// With [fixedPart] (a tweak of the current step) only the "how" is asked,
/// and it is required. Without it the user also picks the item, and the
/// "how" is optional.
Future<LookEdit?> showLookEditSheet(
  BuildContext context, {
  LookPart? fixedPart,
  LookPart initialPart = LookPart.outfit,
}) {
  return showModalBottomSheet<LookEdit>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _LookEditSheet(fixedPart: fixedPart, initialPart: initialPart),
  );
}

class _LookEditSheet extends StatefulWidget {
  const _LookEditSheet({required this.fixedPart, required this.initialPart});

  final LookPart? fixedPart;
  final LookPart initialPart;

  @override
  State<_LookEditSheet> createState() => _LookEditSheetState();
}

class _LookEditSheetState extends State<_LookEditSheet> {
  final TextEditingController _note = TextEditingController();
  late LookPart _part = widget.fixedPart ?? widget.initialPart;

  bool get _isTweak => widget.fixedPart != null;

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _part.label.toLowerCase();
    final canApply = !_isTweak || _note.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MakeoverSectionTitle(
            _isTweak ? 'Tweak the $label' : 'Edit your look',
            subtitle: _isTweak
                ? 'Say what to change. Everything else stays.'
                : 'Pick one thing to change. Everything else stays.',
          ),
          if (!_isTweak) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final part in LookPart.values)
                  MakeoverPill(
                    key: ValueKey('look_edit_part_${part.name}'),
                    label: part.label,
                    selected: part == _part,
                    onTap: () => setState(() => _part = part),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('look_edit_note'),
            controller: _note,
            autofocus: _isTweak,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: _isTweak ? 'What should change?' : 'How? (optional)',
              hintText: 'e.g. make it shorter, in navy blue',
            ),
          ),
          const SizedBox(height: 8),
          MakeoverPrimaryButton(
            key: const ValueKey('look_edit_apply'),
            icon: Icons.auto_awesome,
            label: 'Change the $label',
            onPressed: canApply
                ? () => Navigator.pop(
                    context,
                    LookEdit(part: _part, note: _note.text.trim()),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
