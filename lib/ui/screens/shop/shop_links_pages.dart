// The shop's side of "Share my stock" (K-9): its links, making a new one,
// and sending one.
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/shop_link.dart';
import '../../../data/services/shop_link_service.dart';
import 'share_shop_link_panel.dart';
import 'shared_stock_page.dart';
import 'shop_link_form.dart';

/// "Share my stock": the shop's links, each can be sent again or switched
/// off, and a button for a new one.
class ShopLinksPage extends StatefulWidget {
  const ShopLinksPage({super.key});

  @override
  State<ShopLinksPage> createState() => _ShopLinksPageState();
}

class _ShopLinksPageState extends State<ShopLinksPage> {
  final ShopLinkService _service = ShopLinkService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late Future<List<ShopLink>> _links = _service.mine(_userId);

  void _reload() => setState(() => _links = _service.mine(_userId));

  Future<void> _newLink() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const CreateShopLinkPage()),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Share my stock')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('new_shop_link'),
        onPressed: _newLink,
        icon: const Icon(Icons.add_link),
        label: const Text('New link'),
      ),
      body: FutureBuilder<List<ShopLink>>(
        future: _links,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Your links could not be loaded.'));
          }
          final links = snapshot.data;
          if (links == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (links.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Share all your stock, a category or a few pieces as a link '
                  'or QR code: people can try them on and buy. Tap "New link".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: links.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final link = links[index];
              return Card(
                child: ListTile(
                  key: ValueKey('my_link_${link.id}'),
                  title: Text(
                    link.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${link.scopeLabel} · ${link.audience.label}'
                    '${link.active ? '' : ' · switched off'}',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ShareShopLinkPage(link: link),
                    ),
                  ),
                  trailing: Switch(
                    value: link.active,
                    onChanged: (on) async {
                      await _service.setActive(link, active: on);
                      _reload();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Making a new link from the shop's own pieces.
class CreateShopLinkPage extends StatefulWidget {
  const CreateShopLinkPage({super.key});

  @override
  State<CreateShopLinkPage> createState() => _CreateShopLinkPageState();
}

class _CreateShopLinkPageState extends State<CreateShopLinkPage> {
  final ShopLinkService _service = ShopLinkService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Future<(String, List<Map<String, dynamic>>)> _data = _load();

  Future<(String, List<Map<String, dynamic>>)> _load() async {
    final db = FirebaseFirestore.instance;
    final user = (await db.collection('users').doc(_userId).get()).data();
    final shop = user?['shop'];
    final name = shop is Map && (shop['name'] ?? '').toString().isNotEmpty
        ? shop['name'].toString()
        : (user?['displayName'] ?? 'My shop').toString();
    final products = await db
        .collection('products')
        .where('uploaderId', isEqualTo: _userId)
        .get();
    return (
      name,
      [
        for (final doc in products.docs) {...doc.data(), 'id': doc.id},
      ],
    );
  }

  Future<void> _create(ShopLink draft) async {
    final id = await _service.create(draft);
    if (!mounted) return;
    final saved = ShopLink.fromMap(id, draft.toMap());
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => ShareShopLinkPage(link: saved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New link')),
      body: FutureBuilder<(String, List<Map<String, dynamic>>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Your stock could not be loaded.'));
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.$2.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Add pieces in Products & Inventory first, then share them.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ShopLinkForm(
            ownerId: _userId,
            shopName: data.$1,
            products: data.$2,
            onSubmit: _create,
          );
        },
      ),
    );
  }
}

/// Sending a link: QR, WhatsApp, other apps, copy.
class ShareShopLinkPage extends StatelessWidget {
  const ShareShopLinkPage({super.key, required this.link});

  final ShopLink link;

  void _say(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _whatsApp(BuildContext context) async {
    final opened = await launchUrl(
      whatsAppShareUri(shareMessage(link)),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      _say(context, 'WhatsApp could not be opened.');
    }
  }

  Future<void> _more(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(text: shareMessage(link), subject: link.title),
    );
  }

  Future<void> _qr(BuildContext context) async {
    final image = await QrPainter(
      data: link.url,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
    ).toImageData(900, format: ui.ImageByteFormat.png);
    if (image == null) {
      if (context.mounted) _say(context, 'The QR code could not be made.');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        text: shareMessage(link),
        files: [
          XFile.fromData(
            image.buffer.asUint8List(),
            mimeType: 'image/png',
            name: 'banigoba-${link.id}.png',
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link.url));
    if (context.mounted) _say(context, 'Link copied.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send your link'),
        actions: [
          IconButton(
            tooltip: 'See it as a buyer',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SharedStockPage(linkId: link.id),
              ),
            ),
          ),
        ],
      ),
      body: ShareShopLinkPanel(
        link: link,
        onWhatsApp: () => _whatsApp(context),
        onShareMore: () => _more(context),
        onShareQr: () => _qr(context),
        onCopy: () => _copy(context),
      ),
    );
  }
}
