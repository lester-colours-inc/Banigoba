// Introduces first-time users to Banigoba before they authenticate.
//
// These slides market the app; they ask for nothing. Permissions and style
// preferences come after the account exists (September 2026 review). The
// layout follows the Figma "Intro" frames (node 510:2245): logo, a fanned
// three-photo illustration, a soft grey card holding a two-tone title and one
// line of copy, page dots, and a full-width navy action bar.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:banigoba/modules/onboarding/controllers/onboarding_controller.dart';

/// One marketing slide. The title renders as [lead] in near-black over
/// [highlight] in bold navy, as in Figma.
class OnboardingSlide {
  const OnboardingSlide({
    required this.lead,
    required this.highlight,
    required this.body,
  });

  final String lead;
  final String highlight;
  final String body;

  String get title => '$lead $highlight';
}

/// The intro sequence, in order. Copy is taken from the Figma intro frames.
// UNCLEAR: all three Figma slides reuse the same model photo. Swap in a
// distinct photo per slide if design supplies them.
const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    lead: 'Style',
    highlight: 'Discovery',
    body: 'Browse curated hairstyle galleries and cultural looks.',
  ),
  OnboardingSlide(
    lead: 'Community',
    highlight: 'Feed',
    body: 'Share your own styles, get feedback, and connect with creators.',
  ),
  OnboardingSlide(
    lead: 'Personalized',
    highlight: 'Experience',
    body: 'Save favorites, follow trends, and build your style profile.',
  ),
];

// Figma palette for the intro frames.
const Color _navy = Color(0xFF0E007B);
const Color _ink = Color(0xFF080808);
const Color _bodyGrey = Color(0xFF454545);
const Color _cardGrey = Color(0xFFF7F7F7);
const Color _periwinkle = Color(0xFF848CFF);
const Color _plum = Color(0xFF83008A);
const Color _orchid = Color(0xFFE0ACE3);
const Color _dotActive = Color(0xFFA5A2A5);
const Color _dotIdle = Color(0xFFD9D9D9);

const String _modelImage = 'assets/images/onboarding_model.png';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // UNCLEAR: the meeting suggested showing the intro again after logout.
  // Today it shows once per install. If it should return after logout, clear
  // this key on sign-out.
  static const String doneKey = onboardingDoneKey;

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage(_modelImage), context);
    // Scoped to this screen: created and disposed with the widget.
    return GetBuilder<OnboardingController>(
      init: OnboardingController(slideCount: onboardingSlides.length),
      global: false,
      builder: (controller) => _OnboardingView(controller: controller),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/images/logo.png', width: 142),
                  // UNCLEAR: the Figma frames have no Skip. Kept, subtle, so
                  // returning users are not forced through every slide.
                  Positioned(
                    top: 0,
                    right: 8,
                    child: TextButton(
                      key: const ValueKey('onboarding_skip'),
                      onPressed: controller.finish,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black38,
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              itemCount: onboardingSlides.length,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (context, index) => _SlideView(
                slide: onboardingSlides[index],
                dots: Obx(
                  () => _PageDots(
                    count: onboardingSlides.length,
                    current: controller.page.value,
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => _ActionBar(
              label: controller.isLastPage ? 'Get Started' : 'Next',
              onPressed: controller.next,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.dots});

  final OnboardingSlide slide;
  final Widget dots;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _FannedPhotos(),
              ),
              const SizedBox(height: 36),
              _CopyCard(slide: slide, dots: dots),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three rounded photos fanned out: tilted periwinkle cards either side and
/// a plum-to-orchid card in the middle. Positions are the Figma coordinates
/// on a 375pt canvas, scaled to the available width.
class _FannedPhotos extends StatelessWidget {
  const _FannedPhotos();

  static const double _canvasWidth = 375;
  static const double _canvasHeight = 240;
  static const double _tilt = 6 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AspectRatio(
        aspectRatio: _canvasWidth / _canvasHeight,
        child: FittedBox(
          child: SizedBox(
            width: _canvasWidth,
            height: _canvasHeight,
            child: Stack(
              children: [
                _sideCard(left: 32, angle: -_tilt, mirrored: true),
                _sideCard(left: 212, angle: _tilt, mirrored: false),
                Positioned(
                  left: 107,
                  top: 0,
                  child: Container(
                    width: 161,
                    height: 238,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_plum, _orchid],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 101,
                  top: 18,
                  child: _Photo(width: 170, height: 220, radius: 63),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sideCard({
    required double left,
    required double angle,
    required bool mirrored,
  }) {
    return Positioned(
      left: left,
      top: 38,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 131,
          height: 173,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: _periwinkle,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Transform.flip(
            flipX: mirrored,
            child: const _Photo(width: 131, height: 168, radius: 50),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        _modelImage,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        // Decorative: the title and copy carry the meaning.
        excludeFromSemantics: true,
      ),
    );
  }
}

class _CopyCard extends StatelessWidget {
  const _CopyCard({required this.slide, required this.dots});

  final OnboardingSlide slide;
  final Widget dots;

  // UNCLEAR: Figma sets this copy in Poppins. The app has no Poppins yet, so
  // it uses the platform font. Bundle Poppins if the brand requires it.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x21000000), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Text(
            slide.lead,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          Text(
            slide.highlight,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 250,
            child: Text(
              slide.body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                color: _bodyGrey,
              ),
            ),
          ),
          const SizedBox(height: 16),
          dots,
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
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: index == current ? 13 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == current ? _dotActive : _dotIdle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Full-width navy bar with the primary action, as in the Figma frames.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: _navy,
      child: InkWell(
        key: const ValueKey('onboarding_next'),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 26, 24, 26 + bottomInset),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
