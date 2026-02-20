import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for compressing images before upload.
/// Reduces size to save Cloudinary bandwidth and storage (free tier).
class ImageCompressService {
  /// Maximum width/height for uploaded images
  static const int maxDimension = 1920;

  /// JPEG quality (0-100). 80 gives good quality at ~60-70% size reduction
  static const int defaultQuality = 80;

  /// Maximum file size in bytes (500KB)
  static const int maxFileSize = 500 * 1024;

  /// Compress image bytes to JPEG with quality reduction and resize.
  /// Returns compressed bytes.
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int quality = defaultQuality,
    int minWidth = maxDimension,
    int minHeight = maxDimension,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      return result;
    } catch (e) {
      // If compression fails, return original bytes
      return imageBytes;
    }
  }

  /// Compress image from file path.
  static Future<Uint8List?> compressFromPath(
    String filePath, {
    int quality = defaultQuality,
    int minWidth = maxDimension,
    int minHeight = maxDimension,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        filePath,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Progressively compress until under maxFileSize.
  /// Starts at the given quality and reduces by 10 each iteration.
  static Future<Uint8List?> compressToMaxSize(
    Uint8List imageBytes, {
    int maxBytes = maxFileSize,
    int startQuality = 85,
    int minWidth = maxDimension,
    int minHeight = maxDimension,
  }) async {
    // If already small enough, just return
    if (imageBytes.length <= maxBytes) {
      return imageBytes;
    }

    int quality = startQuality;
    Uint8List? compressed = imageBytes;

    while (quality > 10 && (compressed?.length ?? 0) > maxBytes) {
      compressed = await compressImage(
        imageBytes,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );
      quality -= 10;
    }

    return compressed;
  }
}
