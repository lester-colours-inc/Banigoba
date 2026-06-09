// Provides the complete AI hairstyle flow from photo upload to saved looks.
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_routes.dart';
import '../../../data/services/hairstyle_service.dart';

const _hairNavy = Color(0xFF17008A);
const _hairOrange = Color(0xFFFFB51B);
const _hairBlush = Color(0xFFFFF2F2);

const _styleOptions = [
  _HairStyleOption(
    name: 'Long Locs',
    prompt:
        'Give the person long natural locs with realistic texture, preserving their face, pose, skin tone, and background.',
    imageUrl:
        'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?auto=format&fit=crop&w=600&q=85',
  ),
  _HairStyleOption(
    name: 'Textured Updo',
    prompt:
        'Give the person a polished textured natural updo, preserving their face, pose, skin tone, and background.',
    imageUrl:
        'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=600&q=85',
  ),
  _HairStyleOption(
    name: 'Braided Fade',
    prompt:
        'Give the person a neat braided fade hairstyle with realistic edges, preserving their face, pose, skin tone, and background.',
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=600&q=85',
  ),
];

class HairStylePage extends StatefulWidget {
  const HairStylePage({super.key});

  @override
  State<HairStylePage> createState() => _HairStylePageState();
}

class _HairStylePageState extends State<HairStylePage> {
  final _picker = ImagePicker();
  final _hairstyleService = HairstyleService();
  int _selectedTab = 0;
  bool _isPicking = false;
  bool _isLoadingLatest = true;
  String? _latestSelfieUrl;

  @override
  void initState() {
    super.initState();
    _loadLatestSelfie();
  }

  Future<void> _loadLatestSelfie() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingLatest = false);
      return;
    }

    try {
      final url = await _hairstyleService.getLatestSelfieUrl(user.uid);
      if (!mounted) return;
      setState(() {
        _latestSelfieUrl = url;
        _isLoadingLatest = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingLatest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load saved selfie: $error')),
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (image == null || !mounted) return;

      final bytes = await image.readAsBytes();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Sign in to save your hairstyle selfie.');
      }
      final imageUrl = await _hairstyleService.saveLatestSelfie(
        userId: user.uid,
        imageBytes: bytes,
      );
      if (!mounted) return;
      setState(() => _latestSelfieUrl = imageUrl);
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              HairAnalysisPage(sourceBytes: bytes, sourceImageUrl: imageUrl),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open the photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _useLatestSelfie() async {
    final imageUrl = _latestSelfieUrl;
    if (imageUrl == null || _isPicking) return;

    setState(() => _isPicking = true);
    try {
      final bytes = await _hairstyleService.downloadSelfie(imageUrl);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              HairAnalysisPage(sourceBytes: bytes, sourceImageUrl: imageUrl),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved selfie could not be loaded. Upload it again. $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _HairHeader(
            title: 'Hair Style Feed',
            onMenu: () => Scaffold.of(context).openDrawer(),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HairTabs(
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedTab == 0)
                    _buildMineContent()
                  else
                    _EmptyHairFeed(
                      title: _selectedTab == 1
                          ? 'No friend styles yet'
                          : 'Community styles are coming soon',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMineContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 230,
          decoration: BoxDecoration(
            color: _latestSelfieUrl == null ? _hairBlush : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildSelfiePreview(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _HairButton(
                label: 'Upload Photo',
                icon: Icons.photo_outlined,
                color: _hairNavy,
                loading: _isPicking,
                onPressed: () => _pickPhoto(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HairButton(
                label: 'Take a Photo',
                icon: Icons.add_rounded,
                color: _hairOrange,
                loading: _isPicking,
                onPressed: () => _pickPhoto(ImageSource.camera),
              ),
            ),
          ],
        ),
        if (_latestSelfieUrl != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isPicking ? null : _useLatestSelfie,
              style: OutlinedButton.styleFrom(
                foregroundColor: _hairNavy,
                side: const BorderSide(color: _hairNavy),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              icon: const Icon(Icons.history_rounded),
              label: const Text(
                'Use Latest Selfie',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Styling Preferences',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _HairActionStrip(
          selectedIndex: 0,
          onJourney: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const HairJourneyPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildSelfiePreview() {
    if (_isLoadingLatest) {
      return const Center(child: CircularProgressIndicator(color: _hairNavy));
    }

    final imageUrl = _latestSelfieUrl;
    if (imageUrl == null) return _buildUploadPlaceholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildUploadPlaceholder(),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'Latest selfie',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_rounded, size: 78, color: Colors.grey.shade400),
        const SizedBox(height: 10),
        Text(
          'Upload Your Photo to Begin',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class HairAnalysisPage extends StatefulWidget {
  const HairAnalysisPage({
    super.key,
    required this.sourceBytes,
    required this.sourceImageUrl,
  });

  final Uint8List sourceBytes;
  final String sourceImageUrl;

  @override
  State<HairAnalysisPage> createState() => _HairAnalysisPageState();
}

class _HairAnalysisPageState extends State<HairAnalysisPage> {
  double _eyes = 0.72;
  double _cheeks = 0.58;
  double _lips = 0.55;

  @override
  Widget build(BuildContext context) {
    return _HairFlowScaffold(
      title: 'Start Your Makeover',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HairTabs(selectedIndex: 0),
          const SizedBox(height: 24),
          const Text(
            'Analyzing Your Look',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: Image.memory(widget.sourceBytes, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 22),
          _FaceSlider(
            label: 'Eyes',
            value: _eyes,
            onChanged: (value) => setState(() => _eyes = value),
          ),
          _FaceSlider(
            label: 'Cheeks',
            value: _cheeks,
            onChanged: (value) => setState(() => _cheeks = value),
          ),
          _FaceSlider(
            label: 'Lips',
            value: _lips,
            onChanged: (value) => setState(() => _lips = value),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 180,
              child: _HairButton(
                label: 'Confirm Features',
                color: _hairNavy,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => HairStyleSelectionPage(
                      sourceBytes: widget.sourceBytes,
                      sourceImageUrl: widget.sourceImageUrl,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HairStyleSelectionPage extends StatefulWidget {
  const HairStyleSelectionPage({
    super.key,
    required this.sourceBytes,
    required this.sourceImageUrl,
  });

  final Uint8List sourceBytes;
  final String sourceImageUrl;

  @override
  State<HairStyleSelectionPage> createState() => _HairStyleSelectionPageState();
}

class _HairStyleSelectionPageState extends State<HairStyleSelectionPage> {
  int _selectedStyle = 0;

  @override
  Widget build(BuildContext context) {
    return _HairFlowScaffold(
      title: 'Choose Your Style',
      bottom: _HairActionStrip(
        selectedIndex: 0,
        onJourney: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const HairJourneyPage()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HairTabs(selectedIndex: 0),
          const SizedBox(height: 24),
          const Text(
            'Set Your Style Preferences',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _StyleRow(
            options: _styleOptions,
            selectedIndex: _selectedStyle,
            onSelected: (index) => setState(() => _selectedStyle = index),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Your Idol',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _StyleRow(
            options: _styleOptions.reversed.toList(),
            selectedIndex: _selectedStyle,
            onSelected: (index) => setState(() => _selectedStyle = index),
          ),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 210,
              child: _HairButton(
                label: 'Start My Makeover',
                icon: Icons.keyboard_double_arrow_right_rounded,
                color: _hairNavy,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => _HairResultPage(
                      sourceBytes: widget.sourceBytes,
                      sourceImageUrl: widget.sourceImageUrl,
                      style: _styleOptions[_selectedStyle],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HairResultPage extends StatefulWidget {
  const _HairResultPage({
    required this.sourceBytes,
    required this.sourceImageUrl,
    required this.style,
  });

  final Uint8List sourceBytes;
  final String sourceImageUrl;
  final _HairStyleOption style;

  @override
  State<_HairResultPage> createState() => _HairResultPageState();
}

class _HairResultPageState extends State<_HairResultPage> {
  final _service = HairstyleService();
  HairstyleGeneration? _generation;
  Object? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to generate a hairstyle.');
      return;
    }

    try {
      final generation = await _service.generate(
        userId: user.uid,
        sourceBytes: widget.sourceBytes,
        styleName: widget.style.name,
        prompt: widget.style.prompt,
        sourceImageUrl: widget.sourceImageUrl,
      );
      if (mounted) setState(() => _generation = generation);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    final generation = _generation;
    if (user == null || generation == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await _service.saveLook(
        userId: user.uid,
        styleName: widget.style.name,
        prompt: widget.style.prompt,
        generation: generation,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hairstyle saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to save: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _HairFlowScaffold(
      title: 'Your Styled Look',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your New Look',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 0.83,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildResultImage(),
            ),
          ),
          if (_generation?.isPreview == true) ...[
            const SizedBox(height: 10),
            const Text(
              'Preview mode: add FASHN_API_KEY to generate the selected hairstyle.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HairButton(
                  label: 'Compare Idols',
                  icon: Icons.compare_arrows_rounded,
                  color: _hairNavy,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HairButton(
                  label: 'Save Look',
                  icon: Icons.download_rounded,
                  color: _hairNavy,
                  loading: _isSaving,
                  onPressed: _save,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HairButton(
                  label: 'Try Another Style',
                  icon: Icons.refresh_rounded,
                  color: _hairNavy,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultImage() {
    if (_error != null) {
      return ColoredBox(
        color: _hairBlush,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Unable to create this look.\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _generate,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final generation = _generation;
    if (generation == null) {
      return ColoredBox(
        color: _hairBlush,
        child: const Center(child: CircularProgressIndicator(color: _hairNavy)),
      );
    }

    return Image.network(
      generation.resultImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          Image.memory(widget.sourceBytes, fit: BoxFit.cover),
    );
  }
}

class HairJourneyPage extends StatelessWidget {
  const HairJourneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return _HairFlowScaffold(
      title: 'Your Styling Journey',
      bottom: const _HairActionStrip(selectedIndex: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HairTabs(selectedIndex: 0),
          const SizedBox(height: 24),
          if (user == null)
            const _EmptyHairFeed(title: 'Sign in to see saved hairstyles')
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: HairstyleService().watchSavedLooks(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _hairNavy),
                  );
                }
                final looks = snapshot.data?.docs ?? [];
                if (looks.isEmpty) {
                  return const _EmptyHairFeed(
                    title: 'Your saved hairstyles will appear here',
                  );
                }

                final recent = looks.take(3).toList();
                final older = looks.skip(3).take(3).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recently',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SavedLookRow(looks: recent),
                    if (older.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const Text(
                        'Some time ago',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SavedLookRow(looks: older),
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 220,
                        child: _HairButton(
                          label: 'View All Saved Styles',
                          icon: Icons.keyboard_double_arrow_right_rounded,
                          color: _hairNavy,
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HairFlowScaffold extends StatelessWidget {
  const _HairFlowScaffold({
    required this.title,
    required this.child,
    this.bottom,
  });

  final String title;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _HairHeader(
              title: title,
              onMenu: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
                child: child,
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: bottom,
              ),
          ],
        ),
      ),
      bottomNavigationBar: const _HairBottomBar(),
    );
  }
}

class _HairHeader extends StatelessWidget {
  const _HairHeader({
    required this.title,
    required this.onMenu,
    required this.onBack,
  });

  final String title;
  final VoidCallback onMenu;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Menu',
                onPressed: onMenu,
                icon: const Icon(Icons.menu_rounded),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Back',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Cart',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.cart),
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    const Positioned(
                      right: 8,
                      top: 7,
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HairTabs extends StatelessWidget {
  const _HairTabs({required this.selectedIndex, this.onSelected});

  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mine', 'My Friends', 'Community'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = selectedIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < labels.length - 1 ? 10 : 0),
            child: OutlinedButton(
              onPressed: onSelected == null
                  ? null
                  : () => onSelected?.call(index),
              style: OutlinedButton.styleFrom(
                foregroundColor: selected ? Colors.white : Colors.grey.shade600,
                backgroundColor: selected ? _hairNavy : Colors.white,
                disabledForegroundColor: selected
                    ? Colors.white
                    : Colors.grey.shade600,
                disabledBackgroundColor: selected ? _hairNavy : Colors.white,
                side: BorderSide(
                  color: selected ? _hairNavy : Colors.grey.shade200,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  labels[index],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HairButton extends StatelessWidget {
  const _HairButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.65),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.check_rounded, size: 20),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _FaceSlider extends StatelessWidget {
  const _FaceSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _hairNavy,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: _hairNavy,
              trackHeight: 4,
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_HairStyleOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final selected = selectedIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < options.length - 1 ? 10 : 0,
            ),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 0.95,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: selected ? _hairNavy : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          option.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.face_retouching_natural),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _HairActionStrip extends StatelessWidget {
  const _HairActionStrip({required this.selectedIndex, this.onJourney});

  final int selectedIndex;
  final VoidCallback? onJourney;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bolt_rounded, 'AI Hair Styling'),
      (Icons.inbox_outlined, 'Results'),
      (Icons.history_rounded, 'Styling Timeline'),
      (Icons.share_rounded, 'Save & Share'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: _hairBlush,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: index == 2 ? onJourney : null,
              borderRadius: BorderRadius.circular(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 31,
                    decoration: BoxDecoration(
                      color: selected ? _hairNavy : _hairOrange,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(item.$1, color: Colors.white, size: 19),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SavedLookRow extends StatelessWidget {
  const _SavedLookRow({required this.looks});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> looks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        if (index >= looks.length) {
          return const Expanded(child: SizedBox());
        }
        final data = looks[index].data();
        final url = (data['resultImageUrl'] ?? '').toString();
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
            child: AspectRatio(
              aspectRatio: 0.92,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyHairFeed extends StatelessWidget {
  const _EmptyHairFeed({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 44,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _HairBottomBar extends StatelessWidget {
  const _HairBottomBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Home',
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home_outlined),
            ),
            const Text('DD', style: TextStyle(fontWeight: FontWeight.w800)),
            const CircleAvatar(
              radius: 22,
              backgroundColor: _hairNavy,
              child: Text(
                'HS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.search_rounded),
            const Icon(Icons.chat_bubble_outline_rounded),
          ],
        ),
      ),
    );
  }
}

class _HairStyleOption {
  const _HairStyleOption({
    required this.name,
    required this.prompt,
    required this.imageUrl,
  });

  final String name;
  final String prompt;
  final String imageUrl;
}
