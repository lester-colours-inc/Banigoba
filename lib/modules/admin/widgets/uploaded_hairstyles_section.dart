// "Uploaded Hairstyles": the catalogue entries, each with an Edit button.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/admin/controllers/uploaded_hairstyles_controller.dart';
import 'package:banigoba/modules/admin/models/hairstyle_catalog_options.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

class UploadedHairstylesSection extends StatelessWidget {
  const UploadedHairstylesSection({
    super.key,
    required this.curatorMode,
    required this.onEdit,
  });

  final bool curatorMode;
  final void Function(String docId, Map<String, dynamic> data) onEdit;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UploadedHairstylesController>(
      init: UploadedHairstylesController(curatorMode: curatorMode),
      global: false,
      builder: (controller) {
        if (controller.userId.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              curatorMode ? 'Uploaded Hairstyles' : 'Your Uploaded Hairstyles',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Obx(() {
              final error = controller.error.value;
              if (error != null) {
                return HairCatalogMessage(
                  message: 'Uploaded hairstyles could not be loaded.',
                  detail: error,
                );
              }
              if (!controller.loaded.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: hairNavy),
                  ),
                );
              }
              final docs = controller.docs;
              if (docs.isEmpty) {
                return HairCatalogMessage(
                  message: curatorMode
                      ? 'Uploaded hairstyles will appear here.'
                      : 'Your uploaded hairstyles will appear here.',
                );
              }
              return Column(
                children: [
                  for (final doc in docs)
                    UploadedHairstyleTile(
                      data: doc,
                      onEdit: () => onEdit(doc['id'].toString(), doc),
                    ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class UploadedHairstyleTile extends StatelessWidget {
  const UploadedHairstyleTile({
    super.key,
    required this.data,
    required this.onEdit,
  });

  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final name = (data['name'] ?? data['cutType'] ?? 'Hairstyle').toString();
    final styles = stringListFromDynamic(data['styleTypes']);
    final occasions = stringListFromDynamic(data['occasions']);
    final details =
        [
              data['hairType'],
              styles.isEmpty ? data['styleType'] : styles.join(', '),
              occasions.isEmpty ? data['occasion'] : occasions.join(', '),
            ]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty && value != 'Other')
            .join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            width: 58,
            height: 58,
            child: imageUrl.isEmpty
                ? Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: const Icon(Icons.content_cut_outlined),
                  )
                : AppNetworkImage(imageUrl, fit: BoxFit.cover),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: details.isEmpty
            ? null
            : Text(details, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
          style: TextButton.styleFrom(foregroundColor: hairNavy),
        ),
      ),
    );
  }
}

class HairCatalogMessage extends StatelessWidget {
  const HairCatalogMessage({super.key, required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          if (detail?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              detail!.trim(),
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
