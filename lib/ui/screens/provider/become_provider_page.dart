// One door for shops, designers and salons (S-4): tick what you offer, give a
// business name and a place, and provider mode opens. Roles already held are
// shown ticked and left as they are.
import '../../../core/supabase/app_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/provider_roles.dart';
import '../../../data/services/provider_service.dart';

class BecomeProviderPage extends StatefulWidget {
  const BecomeProviderPage({
    super.key,
    this.held = const [],
    this.initialRoles = const [],
    this.suggestedName = '',
    this.service,
  });

  final List<ProviderRole> held;

  /// Roles ticked when the page opens, e.g. from a "Create salon profile"
  /// button.
  final List<ProviderRole> initialRoles;
  final String suggestedName;
  final ProviderService? service;

  @override
  State<BecomeProviderPage> createState() => _BecomeProviderPageState();
}

class _BecomeProviderPageState extends State<BecomeProviderPage> {
  static const Color _primary = Color(0xFF0D0140);

  late final TextEditingController _name = TextEditingController(
    text: widget.suggestedName,
  );
  final TextEditingController _location = TextEditingController();
  late final Set<ProviderRole> _chosen = {
    for (final role in widget.initialRoles)
      if (!widget.held.contains(role)) role,
  };
  bool _saving = false;
  String? _error;

  static const Map<ProviderRole, (IconData, String)> _blurbs = {
    ProviderRole.shop: (
      Icons.storefront_outlined,
      'Sell clothes and accessories, with photos, sizes and stock.',
    ),
    ProviderRole.designer: (
      Icons.design_services_outlined,
      'Show your portfolio and take design requests.',
    ),
    ProviderRole.salon: (
      Icons.content_cut,
      'Hair salon or stylist: take hairstyle bookings and requests.',
    ),
  };

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_chosen.isEmpty) {
      setState(() => _error = 'Tick at least one thing you offer.');
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your business name.');
      return;
    }
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to become a provider.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await (widget.service ?? ProviderService()).become(
        userId: user.uid,
        held: widget.held,
        added: _chosen.toList(),
        businessName: _name.text,
        location: _location.text,
      );
      // The app's home follows the user document, so provider mode opens by
      // itself; this page only needs to get out of the way.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = 'Could not save: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Provider mode')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'What do you offer?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Tick everything that applies. You stay a customer too, and can '
            'switch sides any time.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          for (final role in ProviderRole.values)
            CheckboxListTile(
              key: ValueKey('role_${role.key}'),
              value: widget.held.contains(role) || _chosen.contains(role),
              onChanged: widget.held.contains(role)
                  ? null
                  : (on) => setState(
                      () =>
                          on == true ? _chosen.add(role) : _chosen.remove(role),
                    ),
              secondary: Icon(_blurbs[role]!.$1),
              title: Text(
                role.label.replaceFirst('My ', ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                widget.held.contains(role)
                    ? 'Already set up'
                    : _blurbs[role]!.$2,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('business_name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Business name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('business_location'),
            controller: _location,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Location (e.g. Harare, Avondale)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your listing appears to customers once a curator has verified it.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('start_provider'),
            onPressed: _saving ? null : _start,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(_saving ? 'Saving...' : 'Start provider mode'),
          ),
        ],
      ),
    );
  }
}
