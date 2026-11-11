// Choose your @username. Shown once to anyone without one (new sign-ups and
// existing users alike) with a suggestion made from their name, and reused
// from Settings to change it (October 2026 review, U-4).
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:banigoba/modules/onboarding/models/username.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({
    super.key,
    required this.suggest,
    required this.isAvailable,
    required this.onClaim,
    this.current = '',
    this.isFirstRun = true,
  });

  /// A free suggestion based on the user's name, or null.
  final Future<String?> Function() suggest;
  final Future<bool> Function(String username) isAvailable;

  /// Saves the username; throws with a readable message when it is taken.
  final Future<void> Function(String username) onClaim;

  /// The username the user has now, when changing it from Settings.
  final String current;
  final bool isFirstRun;

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

enum _Check { idle, checking, available, taken }

class _UsernameScreenState extends State<UsernameScreen> {
  static const _debounce = Duration(milliseconds: 400);

  late final TextEditingController _controller = TextEditingController(
    text: widget.current,
  );
  Timer? _timer;
  _Check _check = _Check.idle;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (widget.current.isEmpty) unawaited(_loadSuggestion());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestion() async {
    final suggestion = await widget.suggest();
    if (!mounted || suggestion == null || _controller.text.isNotEmpty) return;
    _controller.text = suggestion;
    setState(() => _check = _Check.available);
  }

  String get _name => normalizeUsername(_controller.text);

  String? get _problem =>
      _controller.text.isEmpty ? null : usernameProblem(_controller.text);

  void _onChanged(String _) {
    _timer?.cancel();
    setState(() {
      _error = '';
      _check = _Check.idle;
    });
    if (_problem != null || _name.isEmpty || _name == widget.current) return;
    setState(() => _check = _Check.checking);
    _timer = Timer(_debounce, () async {
      final name = _name;
      final free = await widget.isAvailable(name);
      if (!mounted || name != _name) return;
      setState(() => _check = free ? _Check.available : _Check.taken);
    });
  }

  bool get _canSave =>
      !_saving &&
      _problem == null &&
      _name.isNotEmpty &&
      (_name == widget.current || _check == _Check.available);

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await widget.onClaim(_name);
      if (mounted && !widget.isFirstRun) Navigator.of(context).pop(_name);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? get _helper => switch (_check) {
    _ when _problem != null => null,
    _Check.checking => 'Checking…',
    _Check.available => '@$_name is yours if you want it',
    _Check.taken => null,
    _Check.idle => 'Letters, numbers, dots and underscores',
  };

  String? get _errorText =>
      _problem ??
      (_check == _Check.taken
          ? 'That username is taken. Try another.'
          : null) ??
      (_error.isEmpty ? null : _error);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: widget.isFirstRun ? null : AppBar(title: const Text('Username')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            if (widget.isFirstRun) ...[
              Text(
                'Choose your username',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Your username is how people find and mention you, like '
              '@tariro.m. Your name can be shared with others; your username '
              'is yours alone. Your email stays private.',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const ValueKey('username_field'),
              controller: _controller,
              autofocus: !widget.isFirstRun,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: kUsernameMaxLength,
              textInputAction: TextInputAction.done,
              onChanged: _onChanged,
              onSubmitted: (_) => _canSave ? _save() : null,
              decoration: InputDecoration(
                prefixText: '@',
                labelText: 'Username',
                helperText: _helper,
                errorText: _errorText,
                suffixIcon: switch (_check) {
                  _Check.checking => const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  _Check.available => Icon(
                    Icons.check_circle,
                    color: colors.primary,
                  ),
                  _ => null,
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('username_save'),
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isFirstRun ? 'Continue' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
