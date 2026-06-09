// Presents permission requests after authentication in a short guided flow.
import 'package:flutter/material.dart';

import '../../../data/services/permissions_service.dart';

class PermissionsRequestScreen extends StatefulWidget {
  final Future<void> Function(Map<String, bool> statuses) onPermissionsComplete;

  const PermissionsRequestScreen({
    super.key,
    required this.onPermissionsComplete,
  });

  @override
  State<PermissionsRequestScreen> createState() =>
      _PermissionsRequestScreenState();
}

class _PermissionsRequestScreenState extends State<PermissionsRequestScreen> {
  static const _navy = Color(0xFF17008A);
  final _pageController = PageController();
  int _pageIndex = 0;
  bool _isRequesting = false;

  static const _pages = [
    _PermissionPageData(
      title: 'CAMERA',
      description: 'Banigoba needs permission to\naccess your Camera, Photos.',
      icon: Icons.photo_camera_outlined,
      accentIcon: Icons.image_outlined,
    ),
    _PermissionPageData(
      title: 'ADD YOUR LOCATION',
      description: 'Help us deliver your products to\nthe right place for you',
      icon: Icons.location_on_outlined,
      accentIcon: Icons.map_outlined,
    ),
    _PermissionPageData(
      title: 'DON’T MISS OUT',
      description:
          'Turn on notifications to get\nupdates about new looks & more',
      icon: Icons.notifications_none_rounded,
      accentIcon: Icons.chat_bubble_outline_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _acceptCurrentPermission() async {
    setState(() => _isRequesting = true);
    try {
      switch (_pageIndex) {
        case 0:
          await PermissionsService.requestCameraAndPhotosPermissions();
        case 1:
          await PermissionsService.requestLocationPermission();
        case 2:
          await PermissionsService.requestNotificationPermission();
      }

      if (!mounted) return;
      await _advanceOrFinish();
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _advanceOrFinish() async {
    if (_pageIndex < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final statuses = await PermissionsService.getPermissionsSummary();
    await widget.onPermissionsComplete(statuses);
  }

  Future<void> _skip() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      final statuses = await PermissionsService.getPermissionsSummary();
      await widget.onPermissionsComplete(statuses);
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 22, 0),
              child: SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', width: 132),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isRequesting ? null : _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF333333),
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
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) =>
                    _PermissionPage(data: _pages[index]),
              ),
            ),
            Container(
              width: double.infinity,
              color: _navy,
              padding: EdgeInsets.fromLTRB(
                24,
                21,
                24,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: _isRequesting ? null : _acceptCurrentPermission,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  final _PermissionPageData data;

  const _PermissionPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 3),
          _PermissionIllustration(data: data),
          const SizedBox(height: 42),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF161616),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.3,
              color: Color(0xFF666666),
            ),
          ),
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}

class _PermissionIllustration extends StatelessWidget {
  final _PermissionPageData data;

  const _PermissionIllustration({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF2F2F2),
            ),
          ),
          Icon(data.icon, size: 88, color: const Color(0xFF353447)),
          Positioned(
            right: 15,
            bottom: 14,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF8A3D),
              ),
              child: Icon(data.accentIcon, size: 27, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionPageData {
  final String title;
  final String description;
  final IconData icon;
  final IconData accentIcon;

  const _PermissionPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentIcon,
  });
}
