// The in-app continuation of the native splash and the app's sonic-logo
// moment: the logo on white, then the "g" and `for, "Looking Good!!!"` type in
// beneath it while the sonic logo plays (the designer's animation, rebuilt in
// the app so it is crisp on every screen and about half the 7.8 s video: the
// sound is the video's audio from 2.0 s, where its swell and the accent the
// "g" lands on begin, to 5.9 s, with a short fade-in and fade-out).
// It stays up while the app works out where to go (onboarding, sign-in,
// permissions, profile).
//
// Keep the colour and image in step with flutter_native_splash.yaml so the
// hand-off from the native splash reads as one continuous screen.
import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kBrandSplashBackground = Colors.white;
const Color kBrandNavy = Color(0xFF05105F);

/// The payoff line as a screen reader should say it: the brand's own "g",
/// then the typed text.
const String kBrandPayoffLine = 'g, for "Looking Good!!!"';

/// What is typed beside the "g", exactly as the designer wrote it.
const String kBrandPayoffTyped = 'for, "Looking Good!!!"';

/// How long the splash stays up on a cold start, even when the app is ready
/// sooner, so the payoff line can be read while the sonic logo plays.
const Duration kBrandSplashMinimum = Duration(milliseconds: _minimumMs);
const int _minimumMs = 3800;

const String _sonicLogoAsset = 'sounds/sonic_logo.mp3';

const AssetImage _logo = AssetImage('assets/branding/splash_logo.png');
const AssetImage _gMark = AssetImage('assets/branding/g_mark.png');

/// The native splash draws the 1152 px logo at 4x, i.e. 288 logical px.
const double _logoSize = 288;

// The wordmark sits between 113 and 175 logical px down the 288 px logo
// image (see assets/branding/splash_logo.png), so its middle is at 144.
const double _logoBottomInBox = 175;
const double _payoffGap = 11.5;
const double _payoffHeight = 36;

// Measured from the designer's video, whose wordmark is 723 px wide (ours is
// 172.5): the "g" with its dot is 142 px tall and starts 58 px below the
// wordmark's dots, the text starts 32 px right of the "g", is 456 px wide and its
// capitals are 32 px tall, centred on the "g". Scaled by 172.5 / 723 that is
// the numbers below. The text is PlusJakartaSans Bold, a little wider than
// the video's Helvetica-style bold, so it is set slightly smaller and tighter
// to keep the line's width.
const double _payoffTextGap = 7;
const double _payoffFontSize = 10.4;
const double _payoffTextLift = 0.6;
// A character takes this many characters' worth of typing to fade in fully.
const double _charFade = 1.6;

/// Where the payoff line is centred, relative to the middle of the screen.
const double _payoffDy =
    _logoBottomInBox - _logoSize / 2 + _payoffGap + _payoffHeight / 2;

const int _timelineMs = _minimumMs + 300; // then the spinner fades in

// The payoff line: the "g" fades in on the sound's accent, then the text
// types out over the next second, as in the video (3.8 s, 4.0 s, 5.0 s there).
const Interval _gBeat = Interval(1700 / _timelineMs, 2000 / _timelineMs);
const Interval _typeBeat = Interval(2000 / _timelineMs, 3000 / _timelineMs);
// Only seen if the app is still loading once the brand moment has played.
const Interval _spinnerBeat = Interval(
  _minimumMs / _timelineMs,
  1,
  curve: Curves.easeOut,
);

// BrandSplash is rebuilt by several FutureBuilders during startup, so the
// sonic logo and the spinner are timed per app launch rather than per
// widget.
final Stopwatch _launchClock = Stopwatch();
bool _sonicLogoPlayed = false;
final AudioPlayer _sonicLogoPlayer = AudioPlayer();

void _startLaunchClock() {
  if (!_launchClock.isRunning) _launchClock.start();
}

/// How much longer the splash should stay up this launch. The first call
/// starts the launch clock.
Duration brandSplashTimeRemaining() {
  _startLaunchClock();
  final remaining = kBrandSplashMinimum - _launchClock.elapsed;
  return remaining.isNegative ? Duration.zero : remaining;
}

/// Decodes the logo before the first frame so the hand-off from the native
/// splash doesn't flash an empty navy screen.
Future<void> precacheBrandSplash() {
  final done = Completer<void>();
  final stream = _logo.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (_, _) {
      stream.removeListener(listener);
      done.complete();
    },
    onError: (Object error, StackTrace? stackTrace) {
      stream.removeListener(listener);
      debugPrint('Splash logo failed to decode: $error');
      done.complete();
    },
  );
  stream.addListener(listener);
  return done.future;
}

@visibleForTesting
void debugResetBrandSplash() {
  _launchClock
    ..stop()
    ..reset();
  _sonicLogoPlayed = false;
}

class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key});

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;
  late final CurvedAnimation _spinnerIn;
  late final CurvedAnimation _gIn;
  late final CurvedAnimation _typed;

  @override
  void initState() {
    super.initState();
    _startLaunchClock();
    _timeline =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: _timelineMs),
        )..forward(
          from: math.min(1, _launchClock.elapsedMilliseconds / _timelineMs),
        );
    _spinnerIn = CurvedAnimation(parent: _timeline, curve: _spinnerBeat);
    _gIn = CurvedAnimation(parent: _timeline, curve: _gBeat);
    _typed = CurvedAnimation(parent: _timeline, curve: _typeBeat);
    _playSonicLogoOnce();
  }

  @override
  void dispose() {
    _spinnerIn.dispose();
    _gIn.dispose();
    _typed.dispose();
    _timeline.dispose();
    super.dispose();
  }

  Future<void> _playSonicLogoOnce() async {
    if (_sonicLogoPlayed) return;
    _sonicLogoPlayed = true;
    try {
      // Ambient so the sonic logo respects the silent switch and doesn't
      // interrupt music the user is already playing.
      await _sonicLogoPlayer.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
        ).build(),
      );
      await _sonicLogoPlayer.play(AssetSource(_sonicLogoAsset));
    } on Exception catch (error) {
      debugPrint('Sonic logo failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reduced motion: the finished line, no typing.
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: const ValueKey('brand_splash'),
        backgroundColor: kBrandSplashBackground,
        body: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Image(
                key: ValueKey('brand_splash_logo'),
                image: _logo,
                width: _logoSize,
                height: _logoSize,
                semanticLabel: 'Banigoba. $kBrandPayoffLine',
              ),
              Transform.translate(
                offset: const Offset(0, _payoffDy),
                child: ExcludeSemantics(
                  child: _PayoffLine(
                    gIn: still ? const AlwaysStoppedAnimation(1) : _gIn,
                    typed: still ? const AlwaysStoppedAnimation(1) : _typed,
                  ),
                ),
              ),
              Positioned(
                bottom: 72,
                child: FadeTransition(
                  key: const ValueKey('brand_splash_spinner'),
                  opacity: _spinnerIn,
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: kBrandNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "g" and `for, "Looking Good!!!"`, the text typed out a character at a
/// time, the newest ones still fading in.
class _PayoffLine extends StatelessWidget {
  const _PayoffLine({required this.gIn, required this.typed});

  final Animation<double> gIn;
  final Animation<double> typed;

  static const Color _ink = Color(0xFF0B0B0D);
  static const TextStyle _style = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontWeight: FontWeight.w700,
    fontSize: _payoffFontSize,
    letterSpacing: -0.2,
    height: 1,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _payoffHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FadeTransition(
            key: const ValueKey('brand_splash_g'),
            opacity: gIn,
            child: const Image(image: _gMark, height: _payoffHeight),
          ),
          const SizedBox(width: _payoffTextGap),
          Transform.translate(
            offset: const Offset(0, -_payoffTextLift),
            child: AnimatedBuilder(
              animation: typed,
              builder: (context, _) => Text.rich(
                key: const ValueKey('brand_splash_line'),
                // Every character is always laid out (transparent until it
                // is typed), so the line does not shift as it types.
                TextSpan(
                  style: _style,
                  children: typedPayoffSpans(typed.value, _ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One span per character of [kBrandPayoffTyped]: [progress] (0 to 1) is how
/// far the typing has got, and each character fades in over [_charFade]
/// characters of it, so the line has a soft leading edge, not a cursor.
@visibleForTesting
List<TextSpan> typedPayoffSpans(double progress, Color ink) {
  // Run a little past the end so the last character gets to full strength.
  final position =
      progress.clamp(0.0, 1.0) * (kBrandPayoffTyped.length + _charFade - 1);
  return [
    for (var i = 0; i < kBrandPayoffTyped.length; i++)
      TextSpan(
        text: kBrandPayoffTyped[i],
        style: TextStyle(
          color: ink.withValues(
            alpha: ((position - i) / _charFade).clamp(0.0, 1.0),
          ),
        ),
      ),
  ];
}
