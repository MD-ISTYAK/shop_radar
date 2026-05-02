import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

/// A sliding-window video cache that keeps the latest N videos on disk.
/// - Window size: 15 videos (configurable)
/// - Evicts oldest when full
/// - Clears ONLY on app close (detached), NOT on minimize (paused/inactive)
/// - Returns local file path for cached videos, enabling offline-like playback
class VideoCacheManager {
  static final VideoCacheManager _instance = VideoCacheManager._();
  factory VideoCacheManager() => _instance;
  VideoCacheManager._();

  /// Max number of videos to keep cached at once
  static const int maxCacheSize = 15;

  /// LRU-ordered map: URL → local file path
  /// LinkedHashMap preserves insertion order (oldest first)
  final LinkedHashMap<String, String> _cache = LinkedHashMap<String, String>();

  /// Track in-progress downloads to avoid duplicates
  final Map<String, Future<String?>> _pendingDownloads = {};

  /// Dio instance for downloading videos
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Cache directory path (lazily initialized)
  String? _cacheDirPath;

  /// Whether the cache has been initialized
  bool _initialized = false;

  /// Initialize the cache directory
  Future<void> _ensureInit() async {
    if (_initialized) return;

    final dir = await getTemporaryDirectory();
    _cacheDirPath = '${dir.path}/shop_radar_video_cache';
    final cacheDir = Directory(_cacheDirPath!);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _initialized = true;

    debugPrint('[VideoCache] Initialized at $_cacheDirPath');
  }

  /// Get a cached video file path, or download and cache it.
  /// Returns the local file path if successful, null otherwise.
  ///
  /// [url] - The remote video URL
  /// [videoId] - Unique identifier for the video (used as filename)
  Future<String?> getCachedVideo(String url, String videoId) async {
    if (url.isEmpty || videoId.isEmpty) return null;

    await _ensureInit();

    // 1. Check if already cached
    if (_cache.containsKey(url)) {
      final cachedPath = _cache[url]!;
      final file = File(cachedPath);
      if (await file.exists()) {
        // Move to end (most recently used) by removing and re-adding
        _cache.remove(url);
        _cache[url] = cachedPath;
        debugPrint('[VideoCache] HIT: $videoId');
        return cachedPath;
      } else {
        // File was deleted externally, remove from cache
        _cache.remove(url);
      }
    }

    // 2. Check if download is already in progress for this URL
    if (_pendingDownloads.containsKey(url)) {
      debugPrint('[VideoCache] Waiting for pending download: $videoId');
      return await _pendingDownloads[url];
    }

    // 3. Download and cache
    final downloadFuture = _downloadAndCache(url, videoId);
    _pendingDownloads[url] = downloadFuture;

    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _pendingDownloads.remove(url);
    }
  }

  /// Download video and add to cache, evicting oldest if at capacity.
  Future<String?> _downloadAndCache(String url, String videoId) async {
    try {
      // Generate a safe filename from the videoId
      final extension = _getExtension(url);
      final filename = '${videoId.replaceAll(RegExp(r'[^\w]'), '_')}$extension';
      final filePath = '$_cacheDirPath/$filename';
      final file = File(filePath);

      // If file already exists on disk (from a previous session), reuse it
      if (await file.exists()) {
        _cache[url] = filePath;
        debugPrint('[VideoCache] DISK HIT: $videoId');
        return filePath;
      }

      // Evict oldest entries if at capacity BEFORE downloading
      await _evictIfNeeded();

      // Download
      debugPrint('[VideoCache] Downloading: $videoId');
      await _dio.download(url, filePath);

      final downloadedFile = File(filePath);
      if (await downloadedFile.exists()) {
        final sizeKB = (await downloadedFile.length()) / 1024;
        _cache[url] = filePath;
        debugPrint('[VideoCache] CACHED: $videoId (${sizeKB.toStringAsFixed(0)} KB) [${_cache.length}/$maxCacheSize]');
        return filePath;
      }

      return null;
    } catch (e) {
      debugPrint('[VideoCache] Download error for $videoId: $e');
      return null;
    }
  }

  /// Evict the oldest cached video(s) if at or over capacity.
  Future<void> _evictIfNeeded() async {
    while (_cache.length >= maxCacheSize) {
      final oldestUrl = _cache.keys.first;
      final oldestPath = _cache.remove(oldestUrl);

      if (oldestPath != null) {
        try {
          final file = File(oldestPath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('[VideoCache] EVICTED oldest video');
          }
        } catch (e) {
          debugPrint('[VideoCache] Evict delete error: $e');
        }
      }
    }
  }

  /// Check if a video is currently cached
  bool isCached(String url) => _cache.containsKey(url);

  /// Get the current cache size
  int get cacheSize => _cache.length;

  /// Prefetch videos for upcoming reels (call this during scroll)
  /// Downloads videos in the background without blocking.
  ///
  /// [videos] — List of (url, videoId) pairs to prefetch
  void prefetch(List<MapEntry<String, String>> videos) {
    for (final entry in videos) {
      if (!_cache.containsKey(entry.key) && !_pendingDownloads.containsKey(entry.key)) {
        // Fire-and-forget download
        getCachedVideo(entry.key, entry.value).catchError((_) => null);
      }
    }
  }

  /// Clear the ENTIRE cache — call ONLY on app close (detached state).
  /// Do NOT call on minimize (paused/inactive).
  Future<void> clearAll() async {
    debugPrint('[VideoCache] Clearing all cached videos (${_cache.length} entries)');

    // Cancel any pending downloads
    _pendingDownloads.clear();

    // Delete all cached files
    for (final path in _cache.values) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _cache.clear();

    // Also clean the cache directory for any orphaned files
    if (_cacheDirPath != null) {
      try {
        final dir = Directory(_cacheDirPath!);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          await dir.create(recursive: true);
        }
      } catch (e) {
        debugPrint('[VideoCache] Directory cleanup error: $e');
      }
    }

    debugPrint('[VideoCache] Cache cleared');
  }

  /// Get file extension from URL
  String _getExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final extIdx = path.lastIndexOf('.');
      if (extIdx != -1) {
        final ext = path.substring(extIdx);
        // Only return common video extensions
        if (['.mp4', '.mov', '.avi', '.webm', '.mkv'].contains(ext.toLowerCase())) {
          return ext;
        }
      }
    } catch (_) {}
    return '.mp4'; // Default to mp4
  }
}
