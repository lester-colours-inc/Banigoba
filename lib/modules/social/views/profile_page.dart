// Displays user profiles, public looks, and follow controls.
//
// Laid out like the Home feed's lookbook: a cover (pastel banner, photo,
// name), the follow controls, then the person's public looks as the same
// studio-frame cards Home uses.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:banigoba/core/supabase/app_auth.dart';
import 'package:banigoba/modules/notifications/widgets/notification_bell_button.dart';
import 'package:banigoba/modules/settings/services/safety_service.dart';
import 'package:banigoba/modules/settings/views/edit_profile_page.dart';
import 'package:banigoba/modules/social/controllers/profile_controller.dart';
import 'package:banigoba/modules/social/widgets/profile_cover.dart';
import 'package:banigoba/modules/social/widgets/profile_follow_button.dart';
import 'package:banigoba/modules/social/widgets/profile_lookbook.dart';
import 'package:banigoba/modules/social/widgets/profile_photo_changer.dart';
import 'package:banigoba/modules/social/widgets/profile_stats_card.dart';
import 'package:banigoba/modules/social/widgets/profile_style.dart';
import 'package:banigoba/modules/social/widgets/safety_actions.dart';
import 'package:banigoba/shared/widgets/bottom_navigation.dart';

/// Screen displaying user profile details and public Daily Dress Up posts.
class ProfilePage extends StatelessWidget {
  final String? userId; // If null, displays the current user's profile
  // False when embedded as a MainScreen tab, which already supplies its own
  // bottom navigation bar around this page's IndexedStack.
  final bool showBottomNav;
  const ProfilePage({super.key, this.userId, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    final targetUserId = userId ?? AppAuth.instance.currentUser?.uid;
    if (targetUserId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }
    // Scoped to this page: created and disposed with the widget.
    return GetBuilder<ProfileController>(
      init: ProfileController(userId: targetUserId),
      global: false,
      builder: (controller) =>
          _ProfileView(controller: controller, showBottomNav: showBottomNav),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.controller, required this.showBottomNav});

  final ProfileController controller;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    final isMe = controller.isMe;
    return StreamBuilder<Map<String, dynamic>>(
      stream: controller.profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }

        final userData = snapshot.data!;
        final userName = (userData['displayName'] ?? 'User').toString();
        // Your own email, from your sign-in; it is not on the public
        // profile (U-5).
        final userEmail = isMe
            ? (AppAuth.instance.currentUser?.email ?? '')
            : '';
        final username = (userData['username'] ?? '').toString();
        final profileImageUrl = (userData['profileImageUrl'] ?? '').toString();

        return StreamBuilder<bool>(
          stream: controller.isFollowing,
          builder: (context, followingSnapshot) {
            final isFollowing = followingSnapshot.data ?? false;
            final bool canSeeContent = isMe || isFollowing;
            final colors = Theme.of(context).colorScheme;
            final ink = profileInk(colors);

            return Scaffold(
              backgroundColor: colors.surface,
              // The cover's banner runs up behind the app bar, which turns
              // solid once the page scrolls under it.
              extendBodyBehindAppBar: true,
              appBar: _appBar(context, colors, ink, userName),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    ProfileCover(
                      name: userName,
                      photoUrl: profileImageUrl,
                      username: username,
                      // Your email is shown to you only, never to others.
                      email: userEmail,
                      onChangePhoto: isMe
                          ? () => changeProfilePhoto(context)
                          : null,
                    ),
                    // Follow/Unfollow Button (if not viewing own profile)
                    if (!isMe) ...[
                      const SizedBox(height: 18),
                      ProfileFollowButton(
                        controller: controller,
                        isFollowing: isFollowing,
                      ),
                    ],
                    const SizedBox(height: 22),
                    // Followers/Following stats
                    ProfileStatsCard(
                      controller: controller,
                      canSeeContent: canSeeContent,
                      showTotal: isMe,
                    ),
                    // Follow starts with finding people (U-3).
                    if (isMe) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        key: const ValueKey('profile_edit'),
                        onPressed: () =>
                            Get.to<void>(() => const EditProfilePage()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ink,
                          shape: const StadiumBorder(),
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit profile'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey('profile_find_people'),
                        onPressed: controller.openSearch,
                        style: TextButton.styleFrom(
                          foregroundColor: ink,
                          backgroundColor: ink.withValues(alpha: 0.06),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          minimumSize: const Size(0, 44),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.person_search_outlined),
                        label: const Text('Find people to follow'),
                      ),
                    ],
                    ProfileLookbookHeading(isMe: isMe),
                    ProfileLookbook(
                      controller: controller,
                      userName: userName,
                      profileImageUrl: profileImageUrl,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: showBottomNav
                  ? CustomBottomNavigation(
                      currentIndex: -1,
                      onTap: controller.openMainTab,
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _appBar(
    BuildContext context,
    ColorScheme colors,
    Color ink,
    String userName,
  ) {
    final isMe = controller.isMe;
    return AppBar(
      title: Text(
        isMe ? 'My Profile' : userName,
        style: TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      backgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.scrolledUnder)
            ? colors.surface
            : Colors.transparent,
      ),
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      // Clock and battery stay readable over the pale banner.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: colors.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: colors.brightness,
      ),
      actions: [
        if (isMe) ...[
          NotificationBellButton(color: ink, iconSize: 24),
          IconButton(
            icon: const Icon(Icons.straighten),
            tooltip: 'My Profile Details',
            onPressed: controller.openBodyProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: controller.signOut,
          ),
        ],
        // Report or block this person (App Store 1.2).
        if (!isMe)
          PopupMenuButton<String>(
            key: const ValueKey('profile_safety_menu'),
            tooltip: 'More options',
            onSelected: (action) async {
              if (action == 'report') {
                await showReportSheet(
                  context,
                  subject: 'profile',
                  onReport: (reason) => SafetyService.instance.reportProfile(
                    controller.userId,
                    reason,
                  ),
                );
                return;
              }
              final blocked = await confirmBlock(
                context,
                userId: controller.userId,
                name: userName,
              );
              if (blocked && context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: Text('Report profile'),
              ),
              PopupMenuItem(value: 'block', child: Text('Block $userName')),
            ],
          ),
      ],
    );
  }
}
