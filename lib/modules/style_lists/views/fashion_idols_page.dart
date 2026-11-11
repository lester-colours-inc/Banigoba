// My Fashion Idols (October 2026 review, F-2): people you admire, on
// Banigoba or not, kept by name. "Style me like …" opens a makeover with
// the idol filled in.
//
// Under the list, "In the news" shows the stories from the fashion-content
// engine that name an idol.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/style_lists/controllers/fashion_idols_controller.dart';

import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/modules/home/widgets/idol_news_section.dart';

const int _maxIdolNameLength = 60;

class FashionIdolsPage extends StatelessWidget {
  const FashionIdolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<FashionIdolsController>(
      init: FashionIdolsController(),
      global: false,
      builder: (controller) => _build(context, controller),
    );
  }

  Widget _build(BuildContext context, FashionIdolsController controller) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Fashion Idols')),
      body: StreamBuilder<List<StyleListEntry>>(
        stream: controller.idols,
        builder: (context, snapshot) {
          final idols = snapshot.data ?? const <StyleListEntry>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'People whose style you admire: a musician, an actor, a '
                'designer, a local socialite. Style yourself like them in '
                'one tap. We copy their style of clothes, never their face.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('idol_name'),
                      controller: controller.name,
                      maxLength: _maxIdolNameLength,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) => controller.typed.value = value,
                      onSubmitted: (_) => controller.addIdol(),
                      decoration: const InputDecoration(
                        hintText: 'Add an idol, e.g. Michelle Obama',
                        prefixIcon: Icon(Icons.star_outline),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => FilledButton(
                      key: const ValueKey('add_idol'),
                      onPressed: controller.canAdd ? controller.addIdol : null,
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                idols.isEmpty
                    ? 'No Fashion Idols yet'
                    : 'Your Fashion Idols (${idols.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (final idol in idols)
                Card(
                  key: ValueKey('idol_${idol.id}'),
                  margin: const EdgeInsets.only(top: 10),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            idol.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => controller.styleMeLike(idol.name),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Style me like'),
                        ),
                        IconButton(
                          tooltip: 'Remove ${idol.name}',
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.removeIdol(idol.id),
                        ),
                      ],
                    ),
                  ),
                ),
              IdolNewsSection(names: [for (final idol in idols) idol.name]),
            ],
          );
        },
      ),
    );
  }
}
