import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class PhotoEditApi {
TODO: Add error handling, logging, and support for additional endpoints as needed
TODO: add API key management and secure storage for production use
  final String apiKey;
  static const String _baseUrl = 'https://api.fashn.ai';
  static const Duration _pollInterval = Duration(seconds: 2);
  static const Duration _pollTimeout = Duration(minutes: 2);

  PhotoEditApi({required this.apiKey});

  Future<String> _prepareImageInput({String? imageUrl, File? imageFile}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = extension == 'jpg' || extension == 'jpeg' ? 'image/jpeg' : 'image/$extension';
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    throw ArgumentError('Either imageUrl or imageFile must be provided.');
  }

  Map<String, String> get _authHeaders => {
        HttpHeaders.authorizationHeader: 'Bearer $apiKey',
        HttpHeaders.contentTypeHeader: 'application/json',
      };

  Future<String> _createPrediction(
    String modelName,
    Map<String, dynamic> inputs,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/v1/run'),
      headers: _authHeaders,
      body: jsonEncode({
        'model_name': modelName,
        'inputs': inputs,
      }),
    );

    if (response.statusCode != 200) {
      throw HttpException('Fashn API request failed: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
    final id = body['id']?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException('Fashn API response missing prediction id.');
    }
    return id;
  }

  Future<FashnPrediction> _pollPrediction(String predictionId) async {
    final uri = Uri.parse('$_baseUrl/v1/status/$predictionId');
    return await Future.any([
      Future.delayed(_pollTimeout, () => throw TimeoutException('Fashn prediction polling timed out.')),
      _pollUntilComplete(uri, predictionId),
    ]);
  }

  Future<FashnPrediction> _pollUntilComplete(Uri uri, String predictionId) async {
    while (true) {
      final response = await http.get(uri, headers: _authHeaders);
      if (response.statusCode != 200) {
        throw HttpException('Fashn status check failed: ${response.statusCode} ${response.body}');
      }

      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status']?.toString();
      final error = body['error'] as Map<String, dynamic>?;
      final output = <String>[];

      if (body['output'] is List) {
        for (final item in body['output'] as List) {
          output.add(item.toString());
        }
      }

      if (status == 'completed') {
        return FashnPrediction(
          id: body['id']?.toString() ?? predictionId,
          status: status ?? 'completed',
          output: output,
          error: error,
        );
      }

      if (status == 'failed') {
        throw FashnApiException(
          id: body['id']?.toString() ?? predictionId,
          message: error?['message']?.toString() ?? 'Fashn prediction failed.',
          error: error,
        );
      }

      await Future.delayed(_pollInterval);
    }
  }

  Future<List<String>> removeBackground({
    String? imageUrl,
    File? imageFile,
    bool returnBase64 = false,
  }) async {
    final imageInput = await _prepareImageInput(imageUrl: imageUrl, imageFile: imageFile);
    final predictionId = await _createPrediction(
      'background-remove',
      {
        'image': imageInput,
        if (returnBase64) 'return_base64': true,
      },
    );

    final result = await _pollPrediction(predictionId);
    return result.output;
  }

  Future<List<String>> tryOnClothes({
    String? modelImageUrl,
    File? modelImageFile,
    String? garmentImageUrl,
    File? garmentImageFile,
    String modelName = 'tryon-v1.6',
    String category = 'auto',
    String garmentPhotoType = 'auto',
    String mode = 'balanced',
    int numImages = 1,
    String outputFormat = 'png',
    bool returnBase64 = false,
  }) async {
    final modelImage = await _prepareImageInput(imageUrl: modelImageUrl, imageFile: modelImageFile);
    final garmentImage = await _prepareImageInput(imageUrl: garmentImageUrl, imageFile: garmentImageFile);

    final predictionId = await _createPrediction(
      modelName,
      {
        'model_image': modelImage,
        'garment_image': garmentImage,
        'category': category,
        'garment_photo_type': garmentPhotoType,
        'mode': mode,
        'num_samples': numImages,
        'output_format': outputFormat,
        if (returnBase64) 'return_base64': true,
      },
    );

    final result = await _pollPrediction(predictionId);
    return result.output;
  }

  Future<List<String>> applyHairStyle({
    String? imageUrl,
    File? imageFile,
    required String prompt,
    String modelName = 'edit',
    String generationMode = 'balanced',
    int numImages = 1,
    String outputFormat = 'png',
    bool returnBase64 = false,
  }) async {
    final imageInput = await _prepareImageInput(imageUrl: imageUrl, imageFile: imageFile);

    final predictionId = await _createPrediction(
      modelName,
      {
        'image': imageInput,
        'prompt': prompt,
        'generation_mode': generationMode,
        'num_images': numImages,
        'output_format': outputFormat,
        if (returnBase64) 'return_base64': true,
      },
    );

    final result = await _pollPrediction(predictionId);
    return result.output;
  }

  /// Converts a packshot product image into a realistic model wearing the product
  /// Uses Fashn Product to Model endpoint for e-commerce applications
  /// 
  /// Parameters:
  /// - productImageUrl or productImageFile: The product image (flat-lay or ghost mannequin)
  /// - modelImageUrl or modelImageFile: Optional reference model image for pose/style guidance
  /// - prompt: Optional instructions for customization (e.g., "model wearing the product in a studio")
  Future<List<String>> createProductModel({
    String? productImageUrl,
    File? productImageFile,
    String? modelImageUrl,
    File? modelImageFile,
    String? prompt,
    String resolution = '1k',
    String generationMode = 'balanced',
    int numImages = 1,
    String outputFormat = 'png',
    bool returnBase64 = false,
  }) async {
    final productImage = await _prepareImageInput(imageUrl: productImageUrl, imageFile: productImageFile);

    final inputs = {
      'product_image': productImage,
      'resolution': resolution,
      'generation_mode': generationMode,
      'num_images': numImages,
      'output_format': outputFormat,
      if (returnBase64) 'return_base64': true,
      if (prompt != null && prompt.isNotEmpty) 'prompt': prompt,
    };

    if (modelImageUrl != null && modelImageUrl.isNotEmpty) {
      inputs['model_image'] = modelImageUrl;
    } else if (modelImageFile != null) {
      inputs['model_image'] = await _prepareImageInput(imageFile: modelImageFile);
    }

    final predictionId = await _createPrediction('product-to-model', inputs);
    final result = await _pollPrediction(predictionId);
    return result.output;
  }

  /// Cleans up packshot images by removing backgrounds and creating transparent PNGs
  /// Ideal for preparing product images for e-commerce catalogs
  /// 
  /// Parameters:
  /// - imageUrl or imageFile: The packshot product image to clean
  /// - returnBase64: Whether to return base64 or CDN URLs
  Future<List<String>> cleanProductPackshot({
    String? imageUrl,
    File? imageFile,
    bool returnBase64 = false,
  }) async {
    return await removeBackground(
      imageUrl: imageUrl,
      imageFile: imageFile,
      returnBase64: returnBase64,
    );
  }
}

class FashnPrediction {
  final String id;
  final String status;
  final List<String> output;
  final Map<String, dynamic>? error;

  FashnPrediction({
    required this.id,
    required this.status,
    required this.output,
    this.error,
  });
}

class FashnApiException implements Exception {
  final String id;
  final String message;
  final Map<String, dynamic>? error;

  FashnApiException({
    required this.id,
    required this.message,
    this.error,
  });

  @override
  String toString() => 'FashnApiException(id: $id, message: $message, error: $error)';
}
