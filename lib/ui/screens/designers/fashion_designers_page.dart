import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/notification_service.dart';
import '../../../data/services/shop_chat_service.dart';
import '../shop/shop_chat_page.dart';

class FashionDesignersPage extends StatefulWidget {
  const FashionDesignersPage({super.key});

  @override
  State<FashionDesignersPage> createState() => _FashionDesignersPageState();
}

class _FashionDesignersPageState extends State<FashionDesignersPage> {
  static const _primary = Color(0xFF0D0140);
  int _view = 0;
  int _customerTab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'Fashion Designers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.shopping_bag_outlined),
                  label: Text('Customer'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.design_services_outlined),
                  label: Text('Designer'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (value) =>
                  setState(() => _view = value.first),
            ),
          ),
          Expanded(
            child: _view == 0
                ? _buildCustomerView(colors)
                : _buildDesignerWorkspace(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerView(ColorScheme colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
          child: TextField(
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search designers, style, location',
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
              Expanded(child: _tabButton('Designers', 0, _customerTab)),
              const SizedBox(width: 10),
              Expanded(child: _tabButton('My Requests', 1, _customerTab)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _customerTab == 0
              ? _buildDesigners()
              : _buildCustomerRequests(),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index, int selectedIndex) {
    final selected = selectedIndex == index;
    return FilledButton(
      onPressed: () => setState(() => _customerTab = index),
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

  Widget _buildDesigners() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('designerProfile.active', isEqualTo: true)
          .where('designerProfile.verified', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _DesignerEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Designers could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final designers =
            snapshot.data!.docs
                .map((doc) => _DesignerSummary.fromDoc(doc))
                .where(_matchesQuery)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));

        if (designers.isEmpty) {
          return _DesignerEmptyState(
            icon: Icons.design_services_outlined,
            title: _query.isEmpty
                ? 'No designer profiles yet.'
                : 'No designers match your search.',
            actionLabel: 'Create Designer Profile',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const _DesignerProfileEditorPage(),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          itemCount: designers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final designer = designers[index];
            return _DesignerCard(
              designer: designer,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => _DesignerDetailPage(designer: designer),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _matchesQuery(_DesignerSummary designer) {
    if (_query.isEmpty) return true;
    final haystack = [
      designer.name,
      designer.location,
      designer.bio,
      designer.priceRange,
      ...designer.specialties,
    ].join(' ').toLowerCase();
    return haystack.contains(_query);
  }

  Widget _buildCustomerRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _DesignerEmptyState(
        icon: Icons.lock_outline,
        title: 'Sign in to see your custom design requests.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('design_requests')
          .where('customerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _DesignerEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Requests could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.docs.toList()
          ..sort(_compareRequestsNewestFirst);
        if (requests.isEmpty) {
          return const _DesignerEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No custom design requests yet.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data();
            return _RequestCard(
              data: data,
              onMessage: () => _openDesignerConversation(
                designerId: (data['designerId'] ?? '').toString(),
                designerName: (data['designerName'] ?? 'Designer').toString(),
                customerId: user.uid,
                customerName: (data['customerName'] ?? 'Customer').toString(),
                asDesigner: false,
                requestId: doc.id,
                requestData: data,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesignerWorkspace() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _DesignerEmptyState(
        icon: Icons.lock_outline,
        title: 'Sign in to manage your designer workspace.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      children: [
        _buildDesignerProfilePanel(user.uid),
        const SizedBox(height: 18),
        _buildDesignerMessagesButton(),
        const SizedBox(height: 18),
        const _SectionTitle('Incoming Requests'),
        const SizedBox(height: 12),
        _buildIncomingDesignerRequests(user.uid),
      ],
    );
  }

  Widget _buildDesignerMessagesButton() {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: _DesignerColors.primary,
          foregroundColor: Colors.white,
          child: Icon(Icons.chat_bubble_outline),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Reply to customers about their custom designs.'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const ShopChatInboxPage(sellerOnly: true),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignerProfilePanel(String userId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final profile = Map<String, dynamic>.from(
          data['designerProfile'] as Map? ?? const {},
        );
        final active = profile['active'] == true;
        final name = (profile['name'] ?? data['displayName'] ?? 'Designer')
            .toString();
        final bio = (profile['bio'] ?? '').toString();
        final specialties = _toStringList(profile['specialties']);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      active
                          ? Icons.verified_outlined
                          : Icons.design_services_outlined,
                      color: _DesignerColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        active ? name : 'Create your designer profile',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (specialties.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties
                        .take(4)
                        .map((item) => Chip(label: Text(item)))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const _DesignerProfileEditorPage(),
                      ),
                    ),
                    icon: Icon(active ? Icons.edit_outlined : Icons.add),
                    label: Text(
                      active ? 'Edit Designer Profile' : 'Create Profile',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _DesignerColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingDesignerRequests(String designerId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('design_requests')
          .where('designerId', isEqualTo: designerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _DesignerEmptyState(
            icon: Icons.warning_amber_rounded,
            title: 'Incoming requests could not be loaded.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.docs.toList()
          ..sort(_compareRequestsNewestFirst);
        if (requests.isEmpty) {
          return const _DesignerEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No custom design requests yet.',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = requests[index];
            return _RequestCard(
              data: doc.data(),
              designerView: true,
              onMessage: () => _openDesignerConversation(
                designerId: designerId,
                designerName: 'Designer',
                customerId: (doc.data()['customerId'] ?? '').toString(),
                customerName: (doc.data()['customerName'] ?? 'Customer')
                    .toString(),
                asDesigner: true,
                requestId: doc.id,
                requestData: doc.data(),
              ),
              onStatusSelected: (status) =>
                  _updateRequestStatus(doc.id, status, doc.data()),
            );
          },
        );
      },
    );
  }

  Future<void> _updateRequestStatus(
    String requestId,
    String status,
    Map<String, dynamic> requestData,
  ) async {
    final requestRef = FirebaseFirestore.instance
        .collection('design_requests')
        .doc(requestId);
    final currentStatus = (requestData['status'] ?? 'pending').toString();

    await requestRef.set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (currentStatus == status) return;

    final customerId = (requestData['customerId'] ?? '').toString();
    if (customerId.isEmpty) return;

    final designerId = (requestData['designerId'] ?? '').toString();
    final designerName = (requestData['designerName'] ?? 'Designer').toString();
    final occasion = (requestData['occasion'] ?? 'custom design').toString();
    final statusLabel = _requestStatusLabel(status).toLowerCase();

    await NotificationService().addNotification(
      receiverId: customerId,
      title: 'Design request $statusLabel',
      body: '$designerName $statusLabel your $occasion request.',
      type: 'designer_request_status',
      extraData: {
        'designerId': designerId,
        'designerName': designerName,
        'requestId': requestId,
        'requestStatus': status,
        'requestOccasion': occasion,
        'fromName': designerName,
      },
    );
  }

  String _requestStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'completed':
        return 'Completed';
      default:
        return 'Updated';
    }
  }

  int _compareRequestsNewestFirst(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    return _requestCreatedAt(b.data()).compareTo(_requestCreatedAt(a.data()));
  }

  DateTime _requestCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _openDesignerConversation({
    required String designerId,
    required String designerName,
    required String customerId,
    required String customerName,
    required bool asDesigner,
    required String requestId,
    required Map<String, dynamic> requestData,
  }) async {
    if (designerId.isEmpty || customerId.isEmpty) return;
    final chatId = await ShopChatService().ensureDesignerConversation(
      designerId: designerId,
      customerId: customerId,
      designerName: designerName,
    );
    await ShopChatService().addDesignRequestReference(
      chatId: chatId,
      requestId: requestId,
      occasion: (requestData['occasion'] ?? 'Custom design').toString(),
      budget: (requestData['budget'] ?? '').toString(),
      deadline: (requestData['deadline'] ?? '').toString(),
      status: (requestData['status'] ?? '').toString(),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ShopChatPage(
          chatId: chatId,
          title: asDesigner ? customerName : designerName,
          asSeller: asDesigner,
        ),
      ),
    );
  }
}

class DesignerDetailPage extends StatelessWidget {
  const DesignerDetailPage({super.key, required this.designerId});

  final String designerId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(designerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: _DesignerEmptyState(
              icon: Icons.warning_amber_rounded,
              title: 'Designer profile could not be loaded.',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!.exists) {
          return const Scaffold(
            body: _DesignerEmptyState(
              icon: Icons.design_services_outlined,
              title: 'Designer profile not found.',
            ),
          );
        }

        return _DesignerDetailPage(
          designer: _DesignerSummary.fromDoc(snapshot.data!),
        );
      },
    );
  }
}

class _DesignerDetailPage extends StatelessWidget {
  const _DesignerDetailPage({required this.designer});

  final _DesignerSummary designer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(title: Text(designer.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _DesignerHero(designer: designer),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => _DesignRequestPage(designer: designer),
              ),
            ),
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Request Custom Design'),
            style: FilledButton.styleFrom(
              backgroundColor: _DesignerColors.primary,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openDesignerConversation(context),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Message Designer'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 22),
          if (designer.bio.isNotEmpty) ...[
            _SectionTitle('About'),
            const SizedBox(height: 8),
            Text(designer.bio, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 22),
          ],
          if (designer.specialties.isNotEmpty) ...[
            _SectionTitle('Specialties'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: designer.specialties
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
            const SizedBox(height: 22),
          ],
          if (designer.portfolioImages.isNotEmpty) ...[
            _SectionTitle('Portfolio'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: designer.portfolioImages.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    designer.portfolioImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: colors.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDesignerConversation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to message this designer.')),
      );
      return;
    }
    final chatId = await ShopChatService().ensureDesignerConversation(
      designerId: designer.id,
      customerId: user.uid,
      designerName: designer.name,
    );
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ShopChatPage(chatId: chatId, title: designer.name, asSeller: false),
      ),
    );
  }
}

class _DesignRequestPage extends StatefulWidget {
  const _DesignRequestPage({required this.designer});

  final _DesignerSummary designer;

  @override
  State<_DesignRequestPage> createState() => _DesignRequestPageState();
}

class _DesignRequestPageState extends State<_DesignRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _occasionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _measurementsController = TextEditingController();
  final _inspirationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _occasionController.dispose();
    _budgetController.dispose();
    _deadlineController.dispose();
    _measurementsController.dispose();
    _inspirationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Sign in to request a custom design.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('design_requests').add({
        'designerId': widget.designer.id,
        'designerName': widget.designer.name,
        'customerId': user.uid,
        'customerName': user.displayName ?? user.email ?? 'Customer',
        'occasion': _occasionController.text.trim(),
        'budget': _budgetController.text.trim(),
        'deadline': _deadlineController.text.trim(),
        'measurements': _measurementsController.text.trim(),
        'inspirationUrls': _splitCsv(_inspirationController.text),
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.designer.id)
          .collection('notifications')
          .add({
            'type': 'designer_collection',
            'title': 'New custom design request',
            'body':
                '${user.displayName ?? user.email ?? 'A customer'} requested a custom design.',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'extraData': {
              'customerId': user.uid,
              'designerId': widget.designer.id,
            },
          });

      if (!mounted) return;
      _message('Custom design request sent.');
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
      appBar: AppBar(title: const Text('Custom Design Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.designer.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _occasionController,
              label: 'Occasion or piece',
              hint: 'Wedding dress, graduation suit, event outfit',
              required: true,
            ),
            _field(
              controller: _budgetController,
              label: 'Budget',
              hint: 'Example: 150-300',
            ),
            _field(
              controller: _deadlineController,
              label: 'Deadline',
              hint: 'Example: 30 July',
            ),
            _field(
              controller: _measurementsController,
              label: 'Measurements and fit notes',
              hint: 'Add sizes, fit preference, or saved measurement notes',
              maxLines: 3,
            ),
            _field(
              controller: _inspirationController,
              label: 'Inspiration image links',
              hint: 'Paste links separated by commas',
              maxLines: 2,
            ),
            _field(
              controller: _notesController,
              label: 'Design notes',
              hint: 'Fabric, colors, cultural details, modesty, styling',
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
                backgroundColor: _DesignerColors.primary,
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

class _DesignerProfileEditorPage extends StatefulWidget {
  const _DesignerProfileEditorPage();

  @override
  State<_DesignerProfileEditorPage> createState() =>
      _DesignerProfileEditorPageState();
}

class _DesignerProfileEditorPageState
    extends State<_DesignerProfileEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _specialtiesController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _portfolioController = TextEditingController();
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
    _specialtiesController.dispose();
    _priceRangeController.dispose();
    _portfolioController.dispose();
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
      data['designerProfile'] as Map? ?? const {},
    );
    _nameController.text =
        (profile['name'] ?? data['displayName'] ?? user.displayName ?? '')
            .toString();
    _bioController.text = (profile['bio'] ?? '').toString();
    _locationController.text = (profile['location'] ?? '').toString();
    _specialtiesController.text = _toStringList(
      profile['specialties'],
    ).join(', ');
    _priceRangeController.text = (profile['priceRange'] ?? '').toString();
    _portfolioController.text = _toStringList(
      profile['portfolioImages'],
    ).join(', ');
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message('Sign in to create a designer profile.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isDesigner': true,
        'designerProfile': {
          'active': true,
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'location': _locationController.text.trim(),
          'specialties': _splitCsv(_specialtiesController.text),
          'priceRange': _priceRangeController.text.trim(),
          'portfolioImages': _splitCsv(_portfolioController.text),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (!mounted) return;
      _message('Designer profile saved.');
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
      appBar: AppBar(title: const Text('Designer Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              controller: _nameController,
              label: 'Designer or studio name',
              required: true,
            ),
            _field(
              controller: _bioController,
              label: 'Bio',
              hint: 'Tell customers what you design',
              maxLines: 4,
              required: true,
            ),
            _field(controller: _locationController, label: 'Location'),
            _field(
              controller: _specialtiesController,
              label: 'Specialties',
              hint: 'Bridal, streetwear, tailoring, gowns',
            ),
            _field(
              controller: _priceRangeController,
              label: 'Price range',
              hint: 'Example: 100-500',
            ),
            _field(
              controller: _portfolioController,
              label: 'Portfolio image links',
              hint: 'Paste image URLs separated by commas',
              maxLines: 3,
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
              label: Text(_saving ? 'Saving...' : 'Save Designer Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: _DesignerColors.primary,
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

class _DesignerCard extends StatelessWidget {
  const _DesignerCard({required this.designer, required this.onTap});

  final _DesignerSummary designer;
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
              _DesignerAvatar(designer: designer, radius: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      designer.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (designer.location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(designer.location),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      designer.specialties.isEmpty
                          ? 'Custom fashion design'
                          : designer.specialties.take(3).join(' • '),
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

class _DesignerHero extends StatelessWidget {
  const _DesignerHero({required this.designer});

  final _DesignerSummary designer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _DesignerAvatar(designer: designer, radius: 38),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    designer.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (designer.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(designer.location),
                  ],
                  if (designer.priceRange.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('From ${designer.priceRange}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignerAvatar extends StatelessWidget {
  const _DesignerAvatar({required this.designer, required this.radius});

  final _DesignerSummary designer;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = designer.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _DesignerColors.primary,
      backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
      child: imageUrl.isEmpty
          ? Text(
              designer.name.isEmpty ? 'D' : designer.name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.7,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.data,
    this.designerView = false,
    this.onMessage,
    this.onStatusSelected,
  });

  final Map<String, dynamic> data;
  final bool designerView;
  final VoidCallback? onMessage;
  final ValueChanged<String>? onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString();
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
                    (data['occasion'] ?? 'Custom design').toString(),
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
            Text(
              designerView
                  ? 'Customer: ${data['customerName'] ?? 'Customer'}'
                  : 'Designer: ${data['designerName'] ?? 'Designer'}',
            ),
            if ((data['deadline'] ?? '').toString().isNotEmpty)
              Text('Deadline: ${data['deadline']}'),
            if ((data['budget'] ?? '').toString().isNotEmpty)
              Text('Budget: ${data['budget']}'),
            if (designerView &&
                (data['measurements'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Measurements: ${data['measurements']}'),
            ],
            if ((data['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                data['notes'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onMessage != null || designerView && onStatusSelected != null)
              const SizedBox(height: 12),
            if (onMessage != null)
              OutlinedButton.icon(
                onPressed: onMessage,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  designerView ? 'Message Customer' : 'Message Designer',
                ),
              ),
            if (designerView && onStatusSelected != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusButton('Accept', 'accepted'),
                  _statusButton('Decline', 'declined'),
                  _statusButton('Complete', 'completed'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String label, String status) {
    return OutlinedButton(
      onPressed: () => onStatusSelected?.call(status),
      child: Text(label),
    );
  }
}

class _DesignerEmptyState extends StatelessWidget {
  const _DesignerEmptyState({
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

class _DesignerSummary {
  const _DesignerSummary({
    required this.id,
    required this.name,
    required this.bio,
    required this.location,
    required this.specialties,
    required this.priceRange,
    required this.portfolioImages,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String bio;
  final String location;
  final List<String> specialties;
  final String priceRange;
  final List<String> portfolioImages;
  final String avatarUrl;

  factory _DesignerSummary.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final profile = Map<String, dynamic>.from(
      data['designerProfile'] as Map? ?? const {},
    );
    final name =
        (profile['name'] ?? data['displayName'] ?? data['email'] ?? 'Designer')
            .toString();
    final portfolioImages = _toStringList(profile['portfolioImages']);
    final avatar =
        (profile['avatarUrl'] ??
                data['profileImageURL'] ??
                data['profileImageUrl'] ??
                (portfolioImages.isEmpty ? '' : portfolioImages.first))
            .toString();
    return _DesignerSummary(
      id: doc.id,
      name: name,
      bio: (profile['bio'] ?? '').toString(),
      location: (profile['location'] ?? '').toString(),
      specialties: _toStringList(profile['specialties']),
      priceRange: (profile['priceRange'] ?? '').toString(),
      portfolioImages: portfolioImages,
      avatarUrl: avatar,
    );
  }
}

class _DesignerColors {
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
