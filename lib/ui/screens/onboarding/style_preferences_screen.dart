// Optional style preferences, asked once after the account exists.
//
// Every question can be skipped, and the same screen is reachable later from
// Settings, so nobody has to answer everything up front (September 2026
// review). Persistence is injected so the screen stays testable.
import 'package:flutter/material.dart';

import '../../../data/models/style_preferences.dart';

class StylePreferencesScreen extends StatefulWidget {
  const StylePreferencesScreen({
    super.key,
    required this.onSave,
    required this.onSkip,
    this.initial = const StylePreferences(),
    this.isFirstRun = true,
  });

  /// Called with the user's answers.
  final Future<void> Function(StylePreferences preferences) onSave;

  /// Called when the user chooses to answer later.
  final Future<void> Function() onSkip;

  final StylePreferences initial;

  /// First run shows "Skip for now"; from Settings it is a normal page.
  final bool isFirstRun;

  static const List<String> styleOptions = [
    'Casual',
    'Smart',
    'Traditional',
    'Streetwear',
    'Elegant',
    'Sporty',
  ];

  @override
  State<StylePreferencesScreen> createState() => _StylePreferencesScreenState();
}

class _StylePreferencesScreenState extends State<StylePreferencesScreen> {
  static const Color _navy = Color(0xFF17008A);

  late Set<String> _styles = widget.initial.styles.toSet();
  late MakeoverFocus? _focus = widget.initial.focus;
  bool _isSaving = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save preferences: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleStyle(String style) {
    setState(() {
      _styles = _styles.contains(style)
          ? ({..._styles}..remove(style))
          : {..._styles, style};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your style'),
        automaticallyImplyLeading: !widget.isFirstRun,
        actions: [
          if (widget.isFirstRun)
            TextButton(
              key: const ValueKey('preferences_skip'),
              onPressed: _isSaving ? null : () => _run(widget.onSkip),
              child: const Text('Skip for now'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Help us suggest looks you will love. Answer as much or as little '
            'as you like; you can change this any time in Settings.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text('Styles you like', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in StylePreferencesScreen.styleOptions)
                FilterChip(
                  label: Text(style),
                  selected: _styles.contains(style),
                  onSelected: _isSaving ? null : (_) => _toggleStyle(style),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'What should a makeover change?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final focus in MakeoverFocus.values)
                ChoiceChip(
                  label: Text(focus.label),
                  selected: _focus == focus,
                  onSelected: _isSaving
                      ? null
                      : (selected) =>
                            setState(() => _focus = selected ? focus : null),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: FilledButton(
          key: const ValueKey('preferences_save'),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            minimumSize: const Size.fromHeight(54),
          ),
          onPressed: _isSaving
              ? null
              : () => _run(
                  () => widget.onSave(
                    StylePreferences(
                      styles: StylePreferencesScreen.styleOptions
                          .where(_styles.contains)
                          .toList(),
                      focus: _focus,
                    ),
                  ),
                ),
          child: Text(_isSaving ? 'Saving...' : 'Continue'),
        ),
      ),
    );
  }
}
