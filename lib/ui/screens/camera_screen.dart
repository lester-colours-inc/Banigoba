import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../data/services/face_detector_service.dart';
import '../../data/services/pose_detector_service.dart';
import '../../data/services/segmentation_service.dart';
import '../../data/services/ar_try_on_service.dart';
import '../widgets/ar_overlay.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

/// Screen that handles real-time AR try-on using the device camera
class CameraScreen extends StatefulWidget {
  final String? imageUrl;
  final String? category;

  const CameraScreen({
    super.key,
    this.imageUrl,
    this.category,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  final PoseDetectorService _poseDetectorService = PoseDetectorService();
  final SegmentationService _segmentationService = SegmentationService();
  final ArTryOnService _arService = ArTryOnService();
  
  bool _isBusy = false;
  List<Face> _faces = [];
  List<Pose> _poses = [];
  SegmentationMask? _mask;
  ui.Image? _overlayImage;
  String _currentCategory = 'accessories';

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category ?? 'accessories';
    _setupAR();
    _initializeCamera();
  }

  /// Loads the try-on image (glasses, shirt, etc.)
  Future<void> _setupAR() async {
    final String path = widget.imageUrl ?? 'assets/images/glasses5.png';
    final image = await _arService.loadImage(path);
    if (mounted) {
      setState(() {
        _overlayImage = image;
      });
    }
  }

  /// Initializes the camera and starts the image stream for face detection
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) {
        // Stream images to the face detector
        controller.startImageStream(_processCameraImage);
        setState(() {});
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  /// Processes each frame from the camera to detect relevant features based on category
  void _processCameraImage(CameraImage image) async {
    final controller = _controller;
    if (_isBusy || controller == null || !controller.value.isInitialized) return;
    
    _isBusy = true;

    try {
      final category = _currentCategory.toLowerCase();
      
      if (category.contains('accessories') || category.contains('glasses') || category.contains('hats')) {
        final faces = await _faceDetectorService.processImage(image, controller.description);
        if (mounted) setState(() { _faces = faces; _poses = []; _mask = null; });
      } else if (category.contains('tops') || category.contains('outerwear') || category.contains('shirts') || category.contains('bottoms')) {
        final poses = await _poseDetectorService.processImage(image, controller.description);
        if (mounted) setState(() { _poses = poses; _faces = []; _mask = null; });
      } else {
        // Default to segmentation for other categories
        final mask = await _segmentationService.processImage(image, controller.description);
        if (mounted) setState(() { _mask = mask; _faces = []; _poses = []; });
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetectorService.dispose();
    _poseDetectorService.dispose();
    _segmentationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final previewSize = controller.value.previewSize!;

    return Scaffold(
      appBar: AppBar(
        title: Text("AR ${_currentCategory[0].toUpperCase()}${_currentCategory.substring(1)} Try-on"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview scaled to cover the screen
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: Stack(
                children: [
                  CameraPreview(controller),
                  // The AR Overlay layer
                  if (_faces.isNotEmpty || _poses.isNotEmpty || _mask != null)
                    Positioned.fill(
                      child: ArOverlay(
                        faces: _faces,
                        poses: _poses,
                        mask: _mask,
                        previewSize: previewSize,
                        overlayImage: _overlayImage,
                        category: _currentCategory,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Debug info overlay
          // Positioned(
          //   bottom: 50,
          //   left: 20,
          //   right: 20,
          //   child: Container(
          //     padding: const EdgeInsets.all(12),
          //     decoration: BoxDecoration(
          //       color: Colors.black54,
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     child: Text(
          //       "Detecting: $_currentCategory\nFaces: ${_faces.length}\nOverlay: ${_overlayImage != null ? 'Loaded' : 'Loading...'}",
          //       style: const TextStyle(color: Colors.white, fontSize: 14),
          //       textAlign: TextAlign.center,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
