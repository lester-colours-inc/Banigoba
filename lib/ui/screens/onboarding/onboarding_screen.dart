import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends StatefulWidget {
  final bool permissionsOnly;
  final VoidCallback? onPermissionsComplete;

  const OnboardingScreen({
    super.key,
    this.permissionsOnly = false,
    this.onPermissionsComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [];

    if (!widget.permissionsOnly) {
      pages.add(_buildWelcomePage());
    }

    pages.addAll([
      _buildPermissionPage(
        title: "CAMERA & PHOTO LIBRARY",
        description: "Banigoba needs permission to access your Camera and Photo Library.",
        image: Icons.camera_alt_outlined,
        onAccept: () async {
          await Permission.camera.request();
          if (Platform.isIOS) {
            await Permission.photos.request();
            await Permission.photosAddOnly.request();
          } else if (Platform.isAndroid) {
            await Permission.storage.request();
          }
          _nextPage();
        },
      ),
      _buildPermissionPage(
        title: "ADD YOUR LOCATION",
        description: "Help us deliver your products to the right place for you",
        image: Icons.location_on_outlined,
        onAccept: () async {
          await Permission.location.request();
          _nextPage();
        },
      ),
      _buildPermissionPage(
        title: "DONT' MISS OUT",
        description: "Turn on notifications to get updates about new looks & more",
        image: Icons.notifications_none_outlined,
        onAccept: () async {
          await Permission.notification.request();
          if (widget.permissionsOnly) {
            widget.onPermissionsComplete?.call();
          } else {
            _finishOnboarding();
          }
        },
        isLast: true,
      ),
    ]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: pages,
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1490481651871-ab68de25d43d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.1),
              const Color(0xFF0D0140).withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Image.asset(
              'assets/images/logo.png',
              width: 250,
              color: Colors.white,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D0140),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Let\'s Start',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionPage({
    required String title,
    required String description,
    required IconData image,
    required VoidCallback onAccept,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLast ? () {
                if (widget.permissionsOnly) {
                  widget.onPermissionsComplete?.call();
                } else {
                  _finishOnboarding();
                }
              } : _nextPage,
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/logo.png',
            height: 60,
          ),
          const Spacer(),
          Icon(
            image,
            size: 150,
            color: Colors.orange.shade300,
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D0140),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
