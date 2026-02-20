import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

import '../network/api_client.dart';
import 'image_compress_service.dart';

/// Result of an image upload operation
class ImageUploadResult {
  final String url;
  final String publicId;
  final int? width;
  final int? height;
  final String? format;
  final int? bytes;

  const ImageUploadResult({
    required this.url,
    required this.publicId,
    this.width,
    this.height,
    this.format,
    this.bytes,
  });

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) {
    return ImageUploadResult(
      url: json['url'] as String,
      publicId: json['public_id'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      format: json['format'] as String?,
      bytes: json['bytes'] as int?,
    );
  }
}

/// Service that handles image picking, compression, and upload.
class ImageUploadService {
  final ApiClient _apiClient;
  final ImagePicker _picker;

  ImageUploadService({required ApiClient apiClient})
      : _apiClient = apiClient,
        _picker = ImagePicker();

  /// Pick an image from gallery, compress it, and upload.
  /// [folder] organizes images in Cloudinary (e.g., "members", "assets").
  /// Returns null if user cancels.
  Future<ImageUploadResult?> pickAndUpload({
    String folder = '',
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 80,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
    );

    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return uploadBytes(
      bytes: bytes,
      fileName: picked.name,
      folder: folder,
      quality: quality,
    );
  }

  /// Compress and upload raw image bytes.
  Future<ImageUploadResult?> uploadBytes({
    required Uint8List bytes,
    String fileName = 'image.jpg',
    String folder = '',
    int quality = 80,
  }) async {
    // Compress the image before uploading
    final compressed = await ImageCompressService.compressToMaxSize(
      bytes,
      startQuality: quality,
    );

    if (compressed == null || compressed.isEmpty) {
      throw Exception('Erro ao comprimir imagem');
    }

    // Upload via backend multipart endpoint
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        compressed,
        filename: fileName.endsWith('.jpg') ? fileName : '${fileName.split('.').first}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
      if (folder.isNotEmpty) 'folder': folder,
    });

    final response = await _apiClient.dio.post(
      '/v1/upload/image',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return ImageUploadResult.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      response.data['error']?['message'] ?? 'Erro ao fazer upload',
    );
  }

  /// Delete an image by its Cloudinary public_id.
  Future<bool> deleteImage(String publicId) async {
    final response = await _apiClient.dio.delete(
      '/v1/upload/image',
      data: {'public_id': publicId},
    );

    return response.statusCode == 200;
  }
}
