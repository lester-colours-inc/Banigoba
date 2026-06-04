import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:banigoba/data/services/storage_service.dart';
import 'style_selection_page.dart';

/// The starting point of the AI Makeover flow.
/// Users upload a full-body photo or take a selfie to be used for the AI generation.
class AiUploadPage extends StatefulWidget {
  const AiUploadPage({super.key});

  @override
  State<AiUploadPage> createState() => _AiUploadPageState();
}

class _AiUploadPageState extends State<AiUploadPage> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Uint8List? _selectedImageBytes;
  String? _existingFullBodyImageUrl;
  bool _isPicking = false;
  bool _isLoadingExistingPicture = false;
  
  // Track selected styling preference chip index
  int _selectedPreferenceIndex = 0;

  // Statically instantiated list of preferences to protect Flutter Web compilation
  static const List<Map<String, dynamic>> _preferences = [
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingExistingPicture = true;
    });

    final existingUrl = await _storageService.getLatestFullBodyImageUrl(user.uid);
    if (!mounted) return;

    setState(() {
      _existingFullBodyImageUrl = existingUrl;
      _isLoadingExistingPicture = false;
    });
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
      setState(() {
        _selectedImageBytes = imageBytes;
      });

      await _saveFullBodyImageToUserDocument(imageBytes);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StyleSelectionPage(imageBytes: imageBytes),
        ),
      );
    } catch (e) {
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final imageUrl = await _storageService.uploadFullBodyImageBytes(imageBytes, user.uid);

    await _firestore.collection('users').doc(user.uid).set(
      {
        'latestFullBodyImageUrl': imageUrl,
        'fullBodyImageUrls': FieldValue.arrayUnion([imageUrl]),
        'fullBodyImageUploadedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom Brand Colors Extracted Directly From UI Mockup Design
    const primaryBlue = Color(0xFF0A0088);
    const accentYellow = Color(0xFFFFAE00);
    const lightPinkBg = Color(0xFFFFF2F2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'My Daily Dress Up',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 15),
            
            // Segment Switch Selector Row (Mine, My Friends, Community)
            Row(
              children: [
                _buildSegmentTab('Mine', isActive: true, activeColor: primaryBlue),
                _buildSegmentTab('My Friends', isActive: false, activeColor: primaryBlue),
                _buildSegmentTab('Community', isActive: false, activeColor: primaryBlue),
              ],
            ),
            const SizedBox(height: 25),
            
            const Text(
              'Upload Your Image to Start',
              style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Main Frame Upload Display Block
            _buildUploadPlaceholder(lightPinkBg),
            const SizedBox(height: 15),

            if (_existingFullBodyImageUrl != null && _selectedImageBytes == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _isPicking ? null : _useExistingSavedPhoto,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                  label: const Text('Use Saved FullBody Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

            // Side-by-Side Functional Button Controls
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPicking ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 20, color: Colors.white),
                    label: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPicking ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.white),
                    label: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentYellow,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Preference Header Text
            const Text(
              'Styling Preferences',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),

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
                    onTap: () => setState(() => _selectedPreferenceIndex = index),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(String label, {required bool isActive, required Color activeColor}) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.shade500,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(Color bgColor) {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: bgColor,
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
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        onPressed: _clearSelectedImage,
                      ),
                    ),
                  ),
                ],
              )
            : _isLoadingExistingPicture
                ? const Center(child: CircularProgressIndicator())
                : (_existingFullBodyImageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _existingFullBodyImageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image, size: 64, color: Colors.black26),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: CircleAvatar(
                              backgroundColor: Colors.black45,
                              child: IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                onPressed: _clearSelectedImage,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_outlined, size: 60, color: Colors.black26),
                          const SizedBox(height: 12),
                          const Text(
                            'Upload Your Photo to Begin',
                            style: TextStyle(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      )),
      ),
    );
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _existingFullBodyImageUrl = null;
    });
  }

  Future<void> _useExistingSavedPhoto() async {
    final savedUrl = _existingFullBodyImageUrl;
    if (savedUrl == null) return;

    setState(() {
      _isPicking = true;
    });

    final savedBytes = await _storageService.downloadImageBytes(savedUrl);
    if (!mounted) return;

    setState(() {
      _isPicking = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => savedBytes != null
            ? StyleSelectionPage(imageBytes: savedBytes)
            : StyleSelectionPage(imageUrl: savedUrl),
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
        padding: const EdgeInsets.only(right: 20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? activeColor : Colors.grey.shade200),
                boxShadow: isSelected 
                  ? [BoxShadow(color: activeColor.withAlpha((0.15 * 255).round()), blurRadius: 6, offset: const Offset(0, 3))]
                  : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey.shade400,
              ),
            )
          ],
        ),
      ),
    );
  }
}
