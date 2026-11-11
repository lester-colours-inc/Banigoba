// The "Hair Uploads" tab: a card that opens the hairstyle upload screen.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/admin/views/hairstyle_catalog_upload_page.dart';

class HairstyleCatalogPanel extends StatelessWidget {
  const HairstyleCatalogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF0D0140),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.content_cut_outlined),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage hairstyle uploads',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Add catalog hairstyles and edit metadata such as length, '
              'texture, multiple style types, multiple occasions, colour, and '
              'maintenance level.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.to<void>(
                  () => const TemporaryHairstyleUploadPage(curatorMode: true),
                ),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Open Hairstyle Upload'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D0140),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
