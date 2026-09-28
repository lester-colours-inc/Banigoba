// The in-app continuation of the native splash: the icon's mark on brand
// navy, shown while the app works out where to go (onboarding, sign-in,
// permissions, profile). Without it the native splash gave way to a blank
// white screen with a spinner.
//
// Keep the colour and image in step with flutter_native_splash.yaml so the
// hand-off from the native splash reads as one continuous screen.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kBrandSplashNavy = Color(0xFF05105F);

const String _chimeAsset = 'sounds/splash_chime.mp3';

// BrandSplash is rebuilt by several FutureBuilders during startup, so the
// chime is guarded per app launch rather than per widget.
bool _chimePlayed = false;
final AudioPlayer _chimePlayer = AudioPlayer();

class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key});

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> {
  /// The native splash draws the 1520 px logo at 4x, i.e. 380 logical px.
  static const double _logoSize = 380;

  @override
  void initState() {
    super.initState();
    _playChimeOnce();
  }

  Future<void> _playChimeOnce() async {
    if (_chimePlayed) return;
    _chimePlayed = true;
    try {
      // Ambient so the chime respects the silent switch and doesn't
      // interrupt music the user is already playing.
      await _chimePlayer.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: true,
        ).build(),
      );
      await _chimePlayer.play(AssetSource(_chimeAsset));
    } on Exception catch (error) {
      debugPrint('Splash chime failed: $error');
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
              Image.asset(
                'assets/branding/splash_logo.png',
                width: _logoSize,
                height: _logoSize,
                semanticLabel: 'Banigoba',
              ),
              Positioned(
                bottom: 72,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.7),
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
