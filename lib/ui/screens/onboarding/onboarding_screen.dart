// Introduces first-time users to Banigoba before they authenticate.
//
// These slides market the app; they ask for nothing. Permissions and style
// preferences come after the account exists (September 2026 review). The
// layout follows the Figma intro frames: logo, Skip, illustration, uppercase
// title, one line of copy, and a full-width navy action bar.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One marketing slide.
class OnboardingSlide {
  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

/// The intro sequence, in order.
// UNCLEAR: copy and illustrations are placeholders written from the meeting
// notes. Swap in the Figma illustrations and final marketing copy when ready.
// "Get the look" promises boutiques and salons, which arrive in Phase 5.
const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    icon: Icons.auto_awesome,
    title: 'SEE YOUR NEW LOOK',
    body: 'Upload a photo and try a new outfit or hairstyle on yourself.',
  ),
  OnboardingSlide(
    icon: Icons.trending_up,
    title: 'STYLE YOUR WAY',
    body:
        'Describe what you want, follow a fashion icon, or see trends based '
        'on your location.',
  ),
  OnboardingSlide(
    icon: Icons.volunteer_activism_outlined,
    title: 'SHARE WITH KINDNESS',
    body:
        'Post to friends and the community. Only affirmations here: no likes, '
        'no counts.',
  ),
  OnboardingSlide(
    icon: Icons.storefront_outlined,
    title: 'GET THE LOOK',
    body:
        'Find the pieces in your wardrobe, then at boutiques and salons near '
        'you.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  // UNCLEAR: the meeting suggested showing the intro again after logout.
  // Today it shows once per install. If it should return after logout, clear
  // this key on sign-out.
  static const String doneKey = 'onboarding_done';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _navy = Color(0xFF17008A);

  final PageController _pageController = PageController();
  int _page = 0;

  bool get _isLastPage => _page == onboardingSlides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.doneKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _next() {
    if (_isLastPage) {
      _finishOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 28),
            Image.asset('assets/images/logo.png', width: 150),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  key: const ValueKey('onboarding_skip'),
                  onPressed: _finishOnboarding,
                  style: TextButton.styleFrom(foregroundColor: Colors.black54),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingSlides.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) =>
                    _SlideView(slide: onboardingSlides[index]),
              ),
            ),
            _PageDots(count: onboardingSlides.length, current: _page),
            const SizedBox(height: 24),
            _ActionBar(
              label: _isLastPage ? 'Get Started' : 'Next',
              color: _navy,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final OnboardingSlide slide;

  static const Color _navy = Color(0xFF17008A);
  static const Color _orange = Color(0xFFF08A24);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration: a soft orange disc with the navy motif, echoing the
          // orange-and-navy palette of the Figma illustrations.
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(slide.icon, size: 72, color: _navy),
              const Positioned(
                top: 22,
                right: 26,
                child: CircleAvatar(radius: 9, backgroundColor: _orange),
              ),
            ],
          ),
          const SizedBox(height: 44),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index += 1)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == current
                  ? const Color(0xFF17008A)
                  : Colors.black12,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Full-width navy bar with the primary action, as in the Figma frames.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: color,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: InkWell(
        key: const ValueKey('onboarding_next'),
        onTap: onPressed,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
