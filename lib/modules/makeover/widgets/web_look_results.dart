// Pictures found on the web, and the sheet that searches for them on its own
// (used by the Style idol field). Tapping a picture copies it to the user's
// style references and returns the copy's address.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/makeover/controllers/web_look_search_state.dart';
import 'package:banigoba/modules/makeover/services/web_look_search.dart';
import 'package:banigoba/shared/widgets/app_network_image.dart';

/// What the clothes-only rule looks like to the user, shown under results.
const String kWebLookNote =
    'Pictures from the web. We copy the clothes only, never the person.';

/// The results of [state]: a hint, progress, a message, or the pictures.
/// [onKept] gets the address of the copy when a picture is chosen.
class WebLookResults extends StatelessWidget {
  const WebLookResults({
    super.key,
    required this.state,
    required this.onKept,
    this.controller,
    this.emptyHint = 'Type a name, style or occasion to search the web.',
  });

  final WebLookSearchState state;
  final ValueChanged<String> onKept;
  final ScrollController? controller;
  final String emptyHint;

  Future<void> _choose(WebLook look) async {
    final url = await state.keep(look);
    if (url != null) onKept(url);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final looks = state.looks.toList();
      final error = state.error.value;
      final keeping = state.keeping.value;

      if (state.isSearching.value && looks.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (looks.isEmpty) {
        final message = error.isNotEmpty
            ? error
            : state.query.value.length < 2
            ? emptyHint
            : 'Nothing found on the web for that. Try other words.';
        return _Message(message);
      }

      return Column(
        children: [
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                error,
                key: const ValueKey('web_look_error'),
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3 / 4,
              ),
              itemCount: looks.length,
              itemBuilder: (context, index) => _WebLookTile(
                look: looks[index],
                isKeeping: looks[index] == keeping,
                onTap: keeping == null ? () => _choose(looks[index]) : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              kWebLookNote,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      );
    });
  }
}

class _WebLookTile extends StatelessWidget {
  const _WebLookTile({
    required this.look,
    required this.isKeeping,
    required this.onTap,
  });

  final WebLook look;
  final bool isKeeping;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: look.title.isEmpty ? 'Look from ${look.source}' : look.title,
      child: InkWell(
        key: ValueKey('web_look_${look.imageUrl}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(
                look.thumbnailUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                fallback: ColoredBox(
                  color: colors.surfaceContainerHigh,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
              if (look.source.isNotEmpty)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Text(
                      look.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (isKeeping)
                const ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Searches the web for looks, starting from [initialQuery]. Returns the
/// address of the copied picture, or null when cancelled.
Future<String?> showWebLookSearch(
  BuildContext context, {
  String initialQuery = '',
  String title = 'Find looks on the web',
  WebLookSearch? search,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => _WebLookSearchSheet(
        title: title,
        initialQuery: initialQuery,
        search:
            search ??
            ServerWebLookSearch(
              userId: AppAuth.instance.currentUser?.uid ?? '',
            ),
        controller: controller,
      ),
    ),
  );
}

class _WebLookSearchSheet extends StatefulWidget {
  const _WebLookSearchSheet({
    required this.title,
    required this.initialQuery,
    required this.search,
    required this.controller,
  });

  final String title;
  final String initialQuery;
  final WebLookSearch search;
  final ScrollController controller;

  @override
  State<_WebLookSearchSheet> createState() => _WebLookSearchSheetState();
}

class _WebLookSearchSheetState extends State<_WebLookSearchSheet> {
  late final WebLookSearchState _state = WebLookSearchState(widget.search);
  late final TextEditingController _field = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) {
      _state.searchNow(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    _state.dispose();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            widget.title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: TextField(
            key: const ValueKey('web_look_search'),
            controller: _field,
            onChanged: _state.searchSoon,
            onSubmitted: _state.searchNow,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'e.g. Winky D outfit',
              prefixIcon: Icon(Icons.travel_explore),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: WebLookResults(
            state: _state,
            controller: widget.controller,
            onKept: (url) => Navigator.pop(context, url),
          ),
        ),
      ],
    );
  }
}
