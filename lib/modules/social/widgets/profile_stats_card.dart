// Followers and Following on one raised card, on a profile.
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/social/controllers/profile_controller.dart';
import 'package:banigoba/modules/social/views/user_list_page.dart';
import 'package:banigoba/modules/social/widgets/profile_style.dart';
import 'package:banigoba/shared/widgets/app_toast.dart';

class ProfileStatsCard extends StatelessWidget {
  const ProfileStatsCard({
    super.key,
    required this.controller,
    required this.canSeeContent,
    required this.showTotal,
  });

  final ProfileController controller;
  final bool canSeeContent;

  /// Totals are only shown to the profile's owner.
  final bool showTotal;

  @override
  Widget build(BuildContext context) => _buildStatsCard(
    context,
    controller,
    canSeeContent: canSeeContent,
    showTotal: showTotal,
  );
}

/// Followers and Following, side by side on one raised card.
Widget _buildStatsCard(
  BuildContext context,
  ProfileController controller, {
  required bool canSeeContent,
  required bool showTotal,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final isDark = colors.brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: profileInk(colors).withValues(alpha: isDark ? 0.10 : 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: profilePrimaryColor.withValues(alpha: 0.07),
                  blurRadius: 24,
                  spreadRadius: -6,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatColumn(
                context,
                'Followers',
                controller.followersCount,
                controller.userId,
                'followers',
                canSeeContent,
                showTotal: showTotal,
              ),
            ),
            VerticalDivider(
              width: 1,
              indent: 16,
              endIndent: 16,
              color: colors.outlineVariant,
            ),
            Expanded(
              child: _buildStatColumn(
                context,
                'Following',
                controller.followingCount,
                controller.userId,
                'following',
                canSeeContent,
                showTotal: showTotal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Helper for building statistic columns (Followers/Following)
Widget _buildStatColumn(
  BuildContext context,
  String label,
  Stream<int> stream,
  String userId,
  String type,
  bool canSee, {
  required bool showTotal,
}) {
  final colors = Theme.of(context).colorScheme;
  final labelStyle = TextStyle(
    color: colors.onSurfaceVariant,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  return InkWell(
    onTap: () {
      if (canSee) {
        Get.to<void>(
          () => UserListPage(userId: userId, type: type, title: label),
        );
      } else {
        AppToast.say("Follow this account to see their list");
      }
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      // Totals are a private signal: only the profile's owner sees their
      // numbers (BNG SRS 001; October 2026 review, U-2). Others get the
      // list, without a number.
      child: showTotal
          ? StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Column(
                  children: [
                    Text(
                      count.toString(),
                      key: ValueKey('profile_${type}_total'),
                      style: TextStyle(
                        color: profileInk(colors),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(label, style: labelStyle),
                  ],
                );
              },
            )
          : Column(
              children: [
                Icon(Icons.people_outline, color: profileInk(colors)),
                const SizedBox(height: 4),
                Text(label, style: labelStyle),
              ],
            ),
    ),
  );
}
