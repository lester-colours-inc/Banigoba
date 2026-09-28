// Builds packing checklists from the garments in selected saved outfits.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/services/outfit_service.dart';
import '../../widgets/app_network_image.dart';

class TripPackerPage extends StatefulWidget {
  const TripPackerPage({super.key});

  @override
  State<TripPackerPage> createState() => _TripPackerPageState();
}

class _TripPackerPageState extends State<TripPackerPage> {
  static const _primaryColor = Color(0xFF0D0140);
  final OutfitService _outfitService = OutfitService();
  final Set<String> _selectedIds = {};
  bool _isSaving = false;

  Future<void> _saveList(List<_PackingOutfit> outfits) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedIds.isEmpty) return;
    final nameController = TextEditingController(text: 'My Trip');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name your packing list'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Trip name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final selected = outfits
        .where((outfit) => _selectedIds.contains(outfit.id))
        .toList();
    final itemNames =
        selected
            .expand((outfit) => outfit.itemNames)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    setState(() => _isSaving = true);
    try {
      await _outfitService.createPackingList(
        userId: user.uid,
        name: name,
        outfitIds: selected.map((outfit) => outfit.id).toList(),
        itemNames: itemNames,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$name packing list created.')));
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Packer')),
      body: user == null
          ? const Center(child: Text('Sign in to create a packing list.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _outfitService.watchSavedOutfits(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final outfits = snapshot.data!.docs
                    .map((doc) => _PackingOutfit(doc.id, doc.data()))
                    .where((outfit) => outfit.itemNames.isNotEmpty)
                    .toList();
                if (outfits.isEmpty) {
                  return const Center(
                    child: Text('Save outfits first to build a packing list.'),
                  );
                }
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Select outfits. Every garment name will become a packing checklist item.',
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: outfits.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final outfit = outfits[index];
                          final selected = _selectedIds.contains(outfit.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (_) => setState(() {
                              selected
                                  ? _selectedIds.remove(outfit.id)
                                  : _selectedIds.add(outfit.id);
                            }),
                            secondary: SizedBox(
                              width: 58,
                              child: outfit.imageUrl.isEmpty
                                  ? const Icon(Icons.checkroom_outlined)
                                  : AppNetworkImage(
                                      outfit.imageUrl,
                                      fit: BoxFit.contain,
                                      fallback: const Icon(
                                        Icons.checkroom_outlined,
                                      ),
                                    ),
                            ),
                            title: Text(outfit.name),
                            subtitle: Text(outfit.itemNames.join(', ')),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FilledButton.icon(
                          onPressed: _selectedIds.isEmpty || _isSaving
                              ? null
                              : () => _saveList(outfits),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            minimumSize: const Size(double.infinity, 54),
                          ),
                          icon: const Icon(Icons.luggage),
                          label: Text(
                            _isSaving
                                ? 'Creating list...'
                                : 'Create Packing List',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PackingOutfit {
  const _PackingOutfit(this.id, this.data);

  final String id;
  final Map<String, dynamic> data;

  String get name => (data['name'] ?? 'Saved Outfit').toString();
  String get imageUrl =>
      (data['imageUrl'] ?? data['avatarImageUrl'] ?? '').toString();
  List<String> get itemNames {
    final products = data['products'];
    if (products is! Iterable) return const [];
    return products
        .whereType<Map>()
        .map((product) => (product['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
