// Explains app permissions, requests them, and reports their current status.
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/services/permissions_service.dart';

class PermissionsRequestScreen extends StatefulWidget {
  final VoidCallback onPermissionsComplete;

  const PermissionsRequestScreen({
    super.key,
    required this.onPermissionsComplete,
  });

  @override
  State<PermissionsRequestScreen> createState() => _PermissionsRequestScreenState();
}

class _PermissionsRequestScreenState extends State<PermissionsRequestScreen> {
  static const Color primaryColor = Color(0xFF0D0140);
  bool _isRequesting = false;
  Map<String, bool> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadPermissionStatuses();
  }

  Future<void> _loadPermissionStatuses() async {
    final statuses = await PermissionsService.getPermissionsSummary();
    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
      });
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    await PermissionsService.requestAllPermissions();

    if (mounted) {
      await _loadPermissionStatuses();
      setState(() {
        _isRequesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'App Permissions',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To provide you with the best experience, we need a few permissions.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            _buildPermissionItem(
              icon: Icons.camera_alt_outlined,
              title: 'Camera',
              description: 'For AR glasses try-on and selfies',
              isGranted: _permissionStatuses['camera'] ?? false,
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              icon: Icons.photo_library_outlined,
              title: 'Photos',
              description: 'To access and upload your images',
              isGranted: _permissionStatuses['photos'] ?? false,
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              icon: Icons.location_on_outlined,
              title: 'Location',
              description: 'For weather-based fashion recommendations',
              isGranted: _permissionStatuses['location'] ?? false,
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              description: 'To get updates about styles and offers',
              isGranted: _permissionStatuses['notifications'] ?? false,
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestAllPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Allow Permissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : widget.onPermissionsComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  side: BorderSide(color: Colors.grey.shade300),
                  disabledBackgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Skip for Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green.shade50 : Colors.grey.shade50,
        border: Border.all(
          color: isGranted ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: isGranted ? Colors.green : primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGranted ? Colors.green : Colors.grey.shade300,
            ),
            child: isGranted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
