// Small pieces of My Profile Details: section titles and the Save bar.
import 'package:flutter/material.dart';

class BodyProfileSectionTitle extends StatelessWidget {
  const BodyProfileSectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class BodyProfileSaveBar extends StatelessWidget {
  const BodyProfileSaveBar({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          key: const ValueKey('save_profile_details'),
          onPressed: isSaving ? null : onSave,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text(
                  'Save details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
        ),
      ),
    );
  }
}
