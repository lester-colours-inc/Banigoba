// Generates, displays, and saves the completed AI-styled look.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../data/services/makeover_service.dart';

class StyledLookPage extends StatefulWidget {
  final String style;
  final String sourceImageUrl;
  final List<String> generatedImageUrls;

  const StyledLookPage({
    super.key,
    required this.style,
    required this.sourceImageUrl,
    required this.generatedImageUrls,
  });

  static Color primaryColor = Color(0xFF0D0140);

  @override
  State<StyledLookPage> createState() => _StyledLookPageState();
}

class _StyledLookPageState extends State<StyledLookPage> {
  final MakeoverService _makeoverService = MakeoverService();
  bool _isSaving = false;

  Future<void> _saveLook() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be signed in to save your look.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _makeoverService.saveGeneratedMakeover(
        userId: user.uid,
        style: widget.style,
        generatedImageUrls: widget.generatedImageUrls,
        sourceImageUrl: widget.sourceImageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your AI makeover has been saved to your wardrobe.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save look: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Your Styled Look',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.shopping_bag_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {},
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
        padding: EdgeInsets.all(25),
        child: Column(
          children: [
            _buildMainLookCard(),
            SizedBox(height: 25),
            Row(
              children: widget.generatedImageUrls
                  .take(3)
                  .map(
                    (url) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: _buildSmallImageCard(url),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveLook,
              style: ElevatedButton.styleFrom(
                backgroundColor: StyledLookPage.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save to Wardrobe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Try Another Style',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainLookCard() {
    final firstImageUrl = widget.generatedImageUrls.isNotEmpty
        ? widget.generatedImageUrls.first
        : widget.sourceImageUrl;
    return Container(
      width: double.infinity,
      height: 450,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.network(
          firstImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallImageCard(String imageUrl) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
