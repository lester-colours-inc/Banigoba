// My Fashion Idols (October 2026 review, F-2): people you admire, on
// Banigoba or not, kept by name. "Style me like …" opens a makeover with
// the idol filled in.
//
// Under the list, "In the news" shows the stories from the fashion-content
// engine that name an idol.
import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:flutter/material.dart';

import 'package:banigoba/modules/style_lists/services/style_lists_service.dart';
import 'package:banigoba/modules/home/widgets/idol_news_section.dart';
import 'package:banigoba/modules/makeover/views/makeover_page.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

const int _maxIdolNameLength = 60;

class FashionIdolsPage extends StatefulWidget {
  const FashionIdolsPage({super.key});

  @override
  State<FashionIdolsPage> createState() => _FashionIdolsPageState();
}

class _FashionIdolsPageState extends State<FashionIdolsPage> {
  final StyleListsService _lists = StyleListsService();
  final String _userId = AppAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<StyleListEntry>> _idols = _lists.watch(
    _userId,
    StyleList.idols,
  );
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addIdol() async {
    final name = _name.text.trim();
    final id = idolIdFor(name);
    if (id.isEmpty) return;
    try {
      await _lists.add(
        _userId,
        StyleList.idols,
        StyleListEntry(id: id, name: name),
      );
      _name.clear();
      setState(() {});
    } on PostgrestException catch (error) {
      AppToast.say('Could not add $name: ${error.message}');
    }
  }

  void _styleMeLike(String name) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => MakeoverPage(initialIdolName: name),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Fashion Idols')),
      body: StreamBuilder<List<StyleListEntry>>(
        stream: _idols,
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
                      controller: _name,
                      maxLength: _maxIdolNameLength,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _addIdol(),
                      decoration: const InputDecoration(
                        hintText: 'Add an idol, e.g. Michelle Obama',
                        prefixIcon: Icon(Icons.star_outline),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: const ValueKey('add_idol'),
                    onPressed: idolIdFor(_name.text).isEmpty ? null : _addIdol,
                    child: const Text('Add'),
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
                          onPressed: () => _styleMeLike(idol.name),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Style me like'),
                        ),
                        IconButton(
                          tooltip: 'Remove ${idol.name}',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              _lists.remove(_userId, StyleList.idols, idol.id),
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
