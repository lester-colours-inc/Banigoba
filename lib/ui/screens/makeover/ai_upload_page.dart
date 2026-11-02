// Collects or reuses a full-body image before the user selects a makeover style.
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../core/supabase/app_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:banigoba/data/services/storage_service.dart';
import '../../../core/app_routes.dart';
import '../../widgets/cart_badge_button.dart';
import '../wardrobe/measurement_page.dart';
import '../../widgets/app_network_image.dart';

/// The starting point of the AI Makeover flow.
/// Users upload a full-body photo or take a selfie to be used for the AI generation.
class AiUploadPage extends StatefulWidget {
  const AiUploadPage({
    super.key,
    this.plannedDate,
    this.eventId,
    this.eventName,
  });

  final DateTime? plannedDate;
  final String? eventId;
  final String? eventName;

  @override
  State<AiUploadPage> createState() => _AiUploadPageState();
}

class _AiUploadPageState extends State<AiUploadPage> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  Uint8List? _selectedImageBytes;
  Uint8List? _existingFullBodyImageBytes;
  String? _existingFullBodyImageUrl;
  bool _isPicking = false;
  bool _isLoadingExistingPicture = false;
  String? _existingImageError;

  // Track selected styling preference chip index
  int _selectedPreferenceIndex = 0;

  // Statically instantiated list of preferences to protect Flutter Web compilation
  static final List<Map<String, dynamic>> _preferences = [
    {'label': 'Casual', 'icon': Icons.brightness_low},
    {'label': 'Afro-Chic', 'icon': Icons.blur_circular},
    {'label': 'Corporate', 'icon': Icons.business_center},
    {'label': 'Streetwear', 'icon': Icons.checkroom},
    {'label': 'Glamour', 'icon': Icons.auto_awesome},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingFullBodyImage();
  }

  Future<void> _loadExistingFullBodyImage() async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[AiUpload] Cannot load image: no authenticated user');
      return;
    }

    debugPrint('[AiUpload] Loading image for user ${user.uid}');

    setState(() {
      _isLoadingExistingPicture = true;
      _existingImageError = null;
      _existingFullBodyImageBytes = null;
    });

    try {
      // The newest full-body photo in the person's own folder.
      final existingUrl = await _storageService.getLatestFullBodyImageUrl(
        user.uid,
      );

      if (existingUrl != null) {
        await _storageService.debugImageAccess(existingUrl);
        if (kIsWeb) {
          debugPrint(
            '[AiUpload] Web detected; using an HTML image element to bypass CORS byte-fetch restrictions',
          );
        } else {
          debugPrint('[AiUpload] Downloading saved image');
          final existingBytes = await _storageService.downloadImageBytes(
            existingUrl,
          );
          if (existingBytes == null) {
            throw StateError('Storage returned no bytes for the saved image.');
          }
          debugPrint(
            '[AiUpload] Saved image bytes loaded: ${existingBytes.length}',
          );
          _existingFullBodyImageBytes = existingBytes;
        }
      } else {
        debugPrint('[AiUpload] No saved full-body image URL was found');
      }
      if (!mounted) return;

      setState(() {
        _existingFullBodyImageUrl = existingUrl;
      });
    } on PostgrestException catch (e, stackTrace) {
      debugPrint(
        '[AiUpload] Image lookup failed: code=${e.code}, message=${e.message}',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _existingImageError = 'Saved photo could not be loaded.';
      });
    } catch (e, stackTrace) {
      debugPrint('[AiUpload] Saved image lookup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _existingImageError = 'Saved photo could not be loaded.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExistingPicture = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPicking = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (image == null) return;

      final imageBytes = await image.readAsBytes();
      debugPrint(
        '[AiUpload] Picked ${imageBytes.length} bytes from ${source.name}',
      );
      setState(() {
        _selectedImageBytes = imageBytes;
        _existingImageError = null;
      });

      await _saveFullBodyImageToUserDocument(imageBytes);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeasurementPage(
            imageBytes: imageBytes,
            plannedDate: widget.plannedDate,
            eventId: widget.eventId,
            eventName: widget.eventName,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[AiUpload] Pick/upload flow failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to pick or save image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  Future<void> _saveFullBodyImageToUserDocument(Uint8List imageBytes) async {
    final user = AppAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final imageUrl = await _storageService.uploadFullBodyImageBytes(
      imageBytes,
      user.uid,
    );
    debugPrint(
      '[AiUpload] Upload returned URL: ${StorageService.describeDownloadUrl(imageUrl)}',
    );

    // The newest file in the person's folder is their current full-body photo.
    debugPrint('[AiUpload] Saved full-body photo for ${user.uid}');
  }

  @override
  Widget build(BuildContext context) {
    // Custom Brand Colors Extracted Directly From UI Mockup Design
    final primaryBlue = Color(0xFF0A0088);
    final accentYellow = Color(0xFFFFAE00);
    final lightPinkBg = Theme.of(context).colorScheme.surfaceContainerLow;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {},
        ),
        actions: [
          CartBadgeButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text(
              'My Daily Dress Up',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            SizedBox(height: 25),

            Text(
              'Upload Your Image to Start',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),

            // Main Frame Upload Display Block
            _buildUploadPlaceholder(lightPinkBg),
            SizedBox(height: 15),

            if (_existingFullBodyImageUrl != null &&
                _selectedImageBytes == null)
              Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _isPicking ? null : _useExistingSavedPhoto,
                  icon: Icon(Icons.refresh, size: 18, color: Colors.white),
                  label: Text('Use Saved FullBody Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

            // Side-by-Side Functional Button Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPicking
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Upload Photo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPicking
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: Icon(
                      Icons.add_a_photo_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Take a Photo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentYellow,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Preference Header Text
            Text(
              'Styling Preferences',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 16),

            // Horizontal Preference Picker Row Section
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _preferences.length,
                itemBuilder: (context, index) {
                  final item = _preferences[index];
                  final isSelected = _selectedPreferenceIndex == index;
                  return _buildPreferenceItem(
                    label: item['label'],
                    icon: item['icon'],
                    isSelected: isSelected,
                    activeColor: primaryBlue,
                    onTap: () =>
                        setState(() => _selectedPreferenceIndex = index),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(Color bgColor) {
    final hasImage =
        _selectedImageBytes != null || _existingFullBodyImageUrl != null;

    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: hasImage ? Colors.white : bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _selectedImageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: _clearSelectedImage,
                      ),
                    ),
                  ),
                ],
              )
            : _isLoadingExistingPicture
            ? Center(child: CircularProgressIndicator())
            : (_existingFullBodyImageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb
                            ? AppNetworkImage(
                                _existingFullBodyImageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                fallback: _buildImageLoadError(),
                              )
                            : _existingFullBodyImageBytes != null
                            ? Image.memory(
                                _existingFullBodyImageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                    '[AiUpload] Image.memory failed: $error',
                                  );
                                  debugPrintStack(stackTrace: stackTrace);
                                  return _buildImageLoadError();
                                },
                              )
                            : Center(child: CircularProgressIndicator()),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.black45,
                            child: IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: _clearSelectedImage,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _existingImageError != null
                  ? _buildImageLoadError()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file_outlined,
                          size: 60,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Upload Your Photo to Begin',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }

  Widget _buildImageLoadError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            SizedBox(height: 12),
            Text(
              _existingImageError ?? 'Saved photo could not be displayed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadExistingFullBodyImage,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _existingFullBodyImageBytes = null;
      _existingFullBodyImageUrl = null;
      _existingImageError = null;
    });
  }

  Future<void> _useExistingSavedPhoto() async {
    final savedUrl = _existingFullBodyImageUrl;
    if (savedUrl == null) return;

    if (kIsWeb) {
      debugPrint(
        '[AiUpload] Passing saved image URL to style selection on web',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeasurementPage(
            imageUrl: savedUrl,
            plannedDate: widget.plannedDate,
            eventId: widget.eventId,
            eventName: widget.eventName,
          ),
        ),
      );
      return;
    }

    final cachedBytes = _existingFullBodyImageBytes;
    if (cachedBytes != null) {
      debugPrint(
        '[AiUpload] Reusing ${cachedBytes.length} cached saved-image bytes',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MeasurementPage(
            imageBytes: cachedBytes,
            plannedDate: widget.plannedDate,
            eventId: widget.eventId,
            eventName: widget.eventName,
          ),
        ),
      );
      return;
    }

    debugPrint(
      '[AiUpload] Loading saved image bytes from '
      '${StorageService.describeDownloadUrl(savedUrl)}',
    );
    setState(() {
      _isPicking = true;
    });

    final savedBytes = await _storageService.downloadImageBytes(savedUrl);
    if (!mounted) return;

    setState(() {
      _isPicking = false;
    });

    if (savedBytes == null) {
      debugPrint('[AiUpload] Saved image byte download returned null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved image could not be loaded. Please upload it again.',
          ),
        ),
      );
      return;
    }

    debugPrint('[AiUpload] Saved image ready: ${savedBytes.length} bytes');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeasurementPage(
          imageBytes: savedBytes,
          plannedDate: widget.plannedDate,
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );
  }

  Widget _buildPreferenceItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withAlpha((0.15 * 255).round()),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? activeColor
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
