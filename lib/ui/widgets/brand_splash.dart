// The in-app continuation of the native splash and the app's sonic-logo
// moment: the logo with its payoff line on brand navy while the sonic logo
// plays. It stays up while the app works out where to go (onboarding,
// sign-in, permissions, profile).
//
// Keep the colour and image in step with flutter_native_splash.yaml so the
// hand-off from the native splash reads as one continuous screen.
import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kBrandSplashNavy = Color(0xFF05105F);

const String kBrandPayoffLine = 'Beauty Is In The Eyes Of The Beholder';

/// How long the splash stays up on a cold start, even when the app is ready
/// sooner, so the payoff line can be read while the sonic logo plays.
const Duration kBrandSplashMinimum = Duration(milliseconds: _minimumMs);
const int _minimumMs = 2600;

const String _sonicLogoAsset = 'sounds/sonic_logo.mp3';

const AssetImage _logo = AssetImage('assets/branding/splash_logo.png');

/// The native splash draws the 1152 px logo at 4x, i.e. 288 logical px.
const double _logoSize = 288;

const int _timelineMs = _minimumMs + 300; // then the spinner fades in
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
    _playSonicLogoOnce();
  }

  @override
  void dispose() {
    _spinnerIn.dispose();
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const ValueKey('brand_splash'),
        backgroundColor: kBrandSplashNavy,
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
              Positioned(
                bottom: 72,
                child: FadeTransition(
                  key: const ValueKey('brand_splash_spinner'),
                  opacity: _spinnerIn,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withValues(alpha: 0.7),
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
