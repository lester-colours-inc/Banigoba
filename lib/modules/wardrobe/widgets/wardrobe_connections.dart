// Smart Wardrobe › Shops & Designers: the user's own salons, shops and
// designers (My Circle, review items P-7 and W-2), then the directories to
// find more.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:banigoba/app/routes/app_routes.dart';
import 'package:banigoba/modules/social/services/circle_service.dart';

class WardrobeConnections extends StatefulWidget {
  const WardrobeConnections({super.key, required this.userId});

  final String userId;

  @override
  State<WardrobeConnections> createState() => _WardrobeConnectionsState();
}

class _WardrobeConnectionsState extends State<WardrobeConnections> {
  final CircleService _circle = CircleService();
  late final Stream<List<CircleMember>> _members = _circle.watch(widget.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CircleMember>>(
      stream: _members,
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <CircleMember>[];
        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _MyCircle(
              members: members,
              onRemove: (member) => _circle.remove(widget.userId, member.id),
            ),
            const SizedBox(height: 20),
            ..._directories,
          ],
        );
      },
    );
  }

  static const List<Widget> _directories = [
    _ConnectionCard(
      key: ValueKey('wardrobe_shops'),
      icon: Icons.storefront_outlined,
      title: 'Shops',
      subtitle: 'Browse boutiques and follow the ones you buy from.',
      route: AppRoutes.shops,
    ),
    SizedBox(height: 12),
    _ConnectionCard(
      key: ValueKey('wardrobe_designers'),
      icon: Icons.design_services_outlined,
      title: 'Fashion designers',
      subtitle: 'Find designers and follow their new collections.',
      route: AppRoutes.fashionDesigners,
    ),
    SizedBox(height: 12),
    _ConnectionCard(
      key: ValueKey('wardrobe_body_profile'),
      icon: Icons.straighten,
      title: 'My sizes and measurements',
      subtitle: 'So shops can suggest pieces that fit you.',
      route: AppRoutes.bodyProfile,
    ),
  ];
}

class _MyCircle extends StatelessWidget {
  const _MyCircle({required this.members, required this.onRemove});

  final List<CircleMember> members;
  final ValueChanged<CircleMember> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Circle',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          members.isEmpty
              ? 'Your own salons, shops and designers. Add them when you send '
                    'a look, and they will come first next time.'
              : 'Your own salons, shops and designers come first when you '
                    'send a look.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        for (final kind in CircleKind.values)
          if (members.where((m) => m.kind == kind).toList() case final ofKind
              when ofKind.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              kind.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final member in ofKind)
              ListTile(
                key: ValueKey('my_circle_${member.id}'),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: member.avatarUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(member.avatarUrl),
                  child: member.avatarUrl.isEmpty
                      ? const Icon(Icons.storefront_outlined)
                      : null,
                ),
                title: Text(member.name),
                subtitle: member.detail.isEmpty ? null : Text(member.detail),
                trailing: IconButton(
                  tooltip: 'Remove from My Circle',
                  icon: const Icon(Icons.group_remove_outlined),
                  onPressed: () => onRemove(member),
                ),
              ),
          ],
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, color: colors.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
