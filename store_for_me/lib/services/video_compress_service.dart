import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

/// Service to compress videos before uploading.
/// Reduces file size significantly for faster uploads and less bandwidth.
class VideoCompressService {
  static final VideoCompressService _instance = VideoCompressService._();
  factory VideoCompressService() => _instance;
  VideoCompressService._();

  /// Subscription to track compression progress
  Subscription? _subscription;
  double _progress = 0.0;

  double get progress => _progress;

  /// Compress a video file before upload.
  /// Returns the compressed file path, or the original path if compression fails.
  ///
  /// [filePath] — Path to the original video file
  /// [quality] — Compression quality (default: MediumQuality for good balance)
  /// [deleteOrigin] — Whether to delete the original file after compression
  Future<File> compressVideo(
    String filePath, {
    VideoQuality quality = VideoQuality.MediumQuality,
    bool deleteOrigin = false,
  }) async {
    try {
      final originalFile = File(filePath);
      if (!await originalFile.exists()) {
        debugPrint('[VideoCompress] File not found: $filePath');
        return originalFile;
      }

      // Get original file size
      final originalSize = await originalFile.length();
      debugPrint('[VideoCompress] Original size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Skip compression if file is already small (<2MB)
      if (originalSize < 2 * 1024 * 1024) {
        debugPrint('[VideoCompress] File already small, skipping compression');
        return originalFile;
      }

      // Listen to progress
      _subscription = VideoCompress.compressProgress$.subscribe((progress) {
        _progress = progress;
        debugPrint('[VideoCompress] Progress: ${progress.toStringAsFixed(1)}%');
      });

      final info = await VideoCompress.compressVideo(
        filePath,
        quality: quality,
        deleteOrigin: deleteOrigin,
        includeAudio: true,
      );

      _subscription?.unsubscribe();
      _progress = 0.0;

      if (info == null || info.file == null) {
        debugPrint('[VideoCompress] Compression returned null, using original');
        return originalFile;
      }

      final compressedSize = await info.file!.length();
      final savings = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      debugPrint(
        '[VideoCompress] Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB '
        '(saved $savings%)',
      );

      return info.file!;
    } catch (e) {
      debugPrint('[VideoCompress] Error: $e');
      _subscription?.unsubscribe();
      _progress = 0.0;
      return File(filePath);
    }
  }

  /// Cancel any ongoing compression
  Future<void> cancelCompression() async {
    try {
      await VideoCompress.cancelCompression();
      _subscription?.unsubscribe();
      _progress = 0.0;
    } catch (e) {
      debugPrint('[VideoCompress] Cancel error: $e');
    }
  }

  /// Get a thumbnail from a video file
  Future<File?> getVideoThumbnail(String filePath) async {
    try {
      final thumbnail = await VideoCompress.getFileThumbnail(
        filePath,
        quality: 60,
        position: 1000, // 1 second
      );
      return thumbnail;
    } catch (e) {
      debugPrint('[VideoCompress] Thumbnail error: $e');
      return null;
    }
  }

  /// Get video info (duration, size, etc.)
  Future<MediaInfo?> getVideoInfo(String filePath) async {
    try {
      return await VideoCompress.getMediaInfo(filePath);
    } catch (e) {
      debugPrint('[VideoCompress] MediaInfo error: $e');
      return null;
    }
  }

  /// Clean up temp files created by video_compress
  Future<void> cleanUp() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      debugPrint('[VideoCompress] Cleanup error: $e');
    }
  }
}
