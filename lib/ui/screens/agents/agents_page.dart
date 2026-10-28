import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/models/provider_roles.dart';
import '../provider/provider_setup.dart';

class AgentsPage extends StatefulWidget {
  const AgentsPage({super.key});

  @override
  State<AgentsPage> createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  static const _primary = Color(0xFF0D0140);
  int _tab = 0;
  String _query = '';

  String get _selectedAgentType => _tab == 0 ? 'hair' : 'clothes';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Agents',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surface,
        actions: [
          IconButton(
            tooltip: 'Create agent profile',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => openProviderSetup(
              context,
              ProviderRole.salon,
              editor: () => const AgentProfileEditorPage(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search agents, service, location',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _tabButton('Hair Agents', 0)),
                const SizedBox(width: 10),
                Expanded(child: _tabButton('Clothes Agents', 1)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const _AgentRequestsPage(),
                  ),
                ),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('My Agent Requests'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildAgents()),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;
    return FilledButton(
      onPressed: () => setState(() => _tab = index),
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? _primary
            : Theme.of(context).colorScheme.surfaceContainerLow,
        foregroundColor: selected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildAgents() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('agentProfile.active', isEqualTo: true)
          .where('agentProfile.verified', isEqualTo: true)
          .where('agentProfile.type', isEqualTo: _selectedAgentType)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AgentEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Agents could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final agents =
            snapshot.data!.docs
                .map((doc) => _AgentSummary.fromDoc(doc))
                .where(_matchesQuery)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        if (agents.isEmpty) {
          final typeLabel = _selectedAgentType == 'hair' ? 'hair' : 'clothes';
          return _AgentEmptyState(
            icon: _selectedAgentType == 'hair'
                ? Icons.content_cut_rounded
                : Icons.checkroom_outlined,
            title: _query.isEmpty
                ? 'No $typeLabel agents yet.'
                : 'No $typeLabel agents match your search.',
            actionLabel: 'Create Agent Profile',
            onAction: () => openProviderSetup(
              context,
              ProviderRole.salon,
              editor: () => const AgentProfileEditorPage(),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          itemCount: agents.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final agent = agents[index];
            return _AgentCard(
              agent: agent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => _AgentDetailPage(agent: agent),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesQuery(_AgentSummary agent) {
    if (_query.isEmpty) return true;
    final haystack = [
      agent.name,
      agent.location,
      agent.bio,
      agent.rate,
      ...agent.services,
    ].join(' ').toLowerCase();
    return haystack.contains(_query);
  }
}

class _AgentDetailPage extends StatelessWidget {
  const _AgentDetailPage({required this.agent});

  final _AgentSummary agent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: Text(agent.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _AgentAvatar(agent: agent, radius: 38),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(agent.typeLabel),
                        if (agent.location.isNotEmpty) Text(agent.location),
                        if (agent.rate.isNotEmpty) Text(agent.rate),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => _AgentRequestPage(agent: agent),
              ),
            ),
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Request Agent'),
            style: FilledButton.styleFrom(
              backgroundColor: _AgentColors.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 22),
          if (agent.bio.isNotEmpty) ...[
            const _SectionTitle('About'),
            const SizedBox(height: 8),
            Text(agent.bio, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 22),
          ],
          if (agent.services.isNotEmpty) ...[
            const _SectionTitle('Services'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: agent.services
                  .map((service) => Chip(label: Text(service)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgentRequestPage extends StatefulWidget {
  const _AgentRequestPage({required this.agent});

  final _AgentSummary agent;

  @override
  State<_AgentRequestPage> createState() => _AgentRequestPageState();
}

class _AgentRequestPageState extends State<_AgentRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController();
  final _dateController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _serviceController.dispose();
    _dateController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Sign in to request an agent.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('agent_requests').add({
        'agentId': widget.agent.id,
        'agentName': widget.agent.name,
        'agentType': widget.agent.type,
        'customerId': user.uid,
        'customerName': user.displayName ?? user.email ?? 'Customer',
        'service': _serviceController.text.trim(),
        'preferredDate': _dateController.text.trim(),
        'budget': _budgetController.text.trim(),
        'location': _locationController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.agent.id)
          .collection('notifications')
          .add({
            'type': 'agent_request',
            'title': 'New agent request',
            'body':
                '${user.displayName ?? user.email ?? 'A customer'} requested ${_serviceController.text.trim()}.',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'extraData': {'agentId': widget.agent.id, 'customerId': user.uid},
          });

      if (!mounted) return;
      _message('Agent request sent.');
      Navigator.pop(context);
    } catch (error) {
      _message('Unable to send request: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.agent.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _serviceController,
              label: 'Service needed',
              hint: widget.agent.type == 'hair'
                  ? 'Bridal hair, wig install, wash day styling'
                  : 'Personal shopping, event styling, wardrobe planning',
              required: true,
            ),
            _field(
              controller: _dateController,
              label: 'Preferred date',
              hint: 'Example: 30 July',
            ),
            _field(
              controller: _budgetController,
              label: 'Budget',
              hint: 'Example: 50-150',
            ),
            _field(
              controller: _locationController,
              label: 'Location',
              hint: 'City, salon, home visit, or online',
            ),
            _field(
              controller: _notesController,
              label: 'Notes',
              hint: 'Occasion, hair texture, wardrobe goal, timing',
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_saving ? 'Sending...' : 'Send Request'),
              style: FilledButton.styleFrom(
                backgroundColor: _AgentColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _AgentRequestsPage extends StatelessWidget {
  const _AgentRequestsPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('My Agent Requests')),
      body: user == null
          ? const _AgentEmptyState(
              icon: Icons.lock_outline,
              title: 'Sign in to see your agent requests.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('agent_requests')
                  .where('customerId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _AgentEmptyState(
                    icon: Icons.warning_amber_rounded,
                    title: 'Requests could not be loaded.',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) {
                  return const _AgentEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No agent requests yet.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _AgentRequestCard(data: requests[index].data()),
                );
              },
            ),
    );
  }
}

class AgentProfileEditorPage extends StatefulWidget {
  const AgentProfileEditorPage({super.key});

  @override
  State<AgentProfileEditorPage> createState() => AgentProfileEditorPageState();
}

class AgentProfileEditorPageState extends State<AgentProfileEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _servicesController = TextEditingController();
  final _rateController = TextEditingController();
  String _type = 'hair';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _servicesController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final profile = Map<String, dynamic>.from(
      data['agentProfile'] as Map? ?? const {},
    );
    _type = (profile['type'] ?? 'hair').toString() == 'clothes'
        ? 'clothes'
        : 'hair';
    _nameController.text =
        (profile['name'] ?? data['displayName'] ?? user.displayName ?? '')
            .toString();
    _bioController.text = (profile['bio'] ?? '').toString();
    _locationController.text = (profile['location'] ?? '').toString();
    _servicesController.text = _toStringList(profile['services']).join(', ');
    _rateController.text = (profile['rate'] ?? '').toString();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Sign in to create an agent profile.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isAgent': true,
        'agentProfile': {
          'active': true,
          'type': _type,
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'location': _locationController.text.trim(),
          'services': _splitCsv(_servicesController.text),
          'rate': _rateController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (!mounted) return;
      _message('Agent profile saved.');
      Navigator.pop(context);
    } catch (error) {
      _message('Unable to save profile: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'hair',
                  icon: Icon(Icons.content_cut_rounded),
                  label: Text('Hair'),
                ),
                ButtonSegment(
                  value: 'clothes',
                  icon: Icon(Icons.checkroom_outlined),
                  label: Text('Clothes'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _nameController,
              label: 'Agent or studio name',
              required: true,
            ),
            _field(
              controller: _bioController,
              label: 'Bio',
              hint: _type == 'hair'
                  ? 'Tell customers about your hair services'
                  : 'Tell customers about your styling services',
              maxLines: 4,
              required: true,
            ),
            _field(controller: _locationController, label: 'Location'),
            _field(
              controller: _servicesController,
              label: 'Services',
              hint: _type == 'hair'
                  ? 'Braids, wigs, bridal hair, natural hair'
                  : 'Personal shopping, wardrobe edit, event styling',
            ),
            _field(
              controller: _rateController,
              label: 'Rate or price range',
              hint: 'Example: 50-150',
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Agent Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: _AgentColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.agent, required this.onTap});

  final _AgentSummary agent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _AgentAvatar(agent: agent, radius: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(agent.typeLabel),
                    if (agent.location.isNotEmpty) Text(agent.location),
                    const SizedBox(height: 6),
                    Text(
                      agent.services.isEmpty
                          ? 'Fashion service agent'
                          : agent.services.take(3).join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar({required this.agent, required this.radius});

  final _AgentSummary agent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = agent.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _AgentColors.primary,
      backgroundImage: imageUrl.isEmpty
          ? null
          : CachedNetworkImageProvider(imageUrl),
      child: imageUrl.isEmpty
          ? Icon(
              agent.type == 'hair'
                  ? Icons.content_cut_rounded
                  : Icons.checkroom_outlined,
              color: Colors.white,
              size: radius,
            )
          : null,
    );
  }
}

class _AgentRequestCard extends StatelessWidget {
  const _AgentRequestCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString();
    final type = (data['agentType'] ?? '').toString() == 'hair'
        ? 'Hair'
        : 'Clothes';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (data['service'] ?? '$type agent request').toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Agent: ${data['agentName'] ?? 'Agent'}'),
            if ((data['preferredDate'] ?? '').toString().isNotEmpty)
              Text('Date: ${data['preferredDate']}'),
            if ((data['budget'] ?? '').toString().isNotEmpty)
              Text('Budget: ${data['budget']}'),
          ],
        ),
      ),
    );
  }
}

class _AgentEmptyState extends StatelessWidget {
  const _AgentEmptyState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _AgentSummary {
  const _AgentSummary({
    required this.id,
    required this.type,
    required this.name,
    required this.bio,
    required this.location,
    required this.services,
    required this.rate,
    required this.avatarUrl,
  });

  final String id;
  final String type;
  final String name;
  final String bio;
  final String location;
  final List<String> services;
  final String rate;
  final String avatarUrl;

  String get typeLabel => type == 'hair' ? 'Hair Agent' : 'Clothes Agent';

  factory _AgentSummary.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final profile = Map<String, dynamic>.from(
      data['agentProfile'] as Map? ?? const {},
    );
    final type = (profile['type'] ?? 'hair').toString() == 'clothes'
        ? 'clothes'
        : 'hair';
    final name = (profile['name'] ?? data['displayName'] ?? 'Agent').toString();
    final avatar =
        (profile['avatarUrl'] ??
                data['profileImageURL'] ??
                data['profileImageUrl'] ??
                '')
            .toString();
    return _AgentSummary(
      id: doc.id,
      type: type,
      name: name,
      bio: (profile['bio'] ?? '').toString(),
      location: (profile['location'] ?? '').toString(),
      services: _toStringList(profile['services']),
      rate: (profile['rate'] ?? '').toString(),
      avatarUrl: avatar,
    );
  }
}

class _AgentColors {
  static const primary = Color(0xFF0D0140);
}

List<String> _splitCsv(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<String> _toStringList(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return _splitCsv(value);
  }
  return const [];
}
