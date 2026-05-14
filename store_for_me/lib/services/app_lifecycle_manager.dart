import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'video_cache_manager.dart';
import 'video_compress_service.dart';

/// Observes the app lifecycle to manage video cache cleanup.
///
/// The cache is ONLY cleared when the app is fully closed (detached state).
/// It is NOT cleared when the app is minimized (paused/inactive state).
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._();

  bool _isRegistered = false;

  /// Register the lifecycle observer. Call this once in main().
  void register() {
    if (_isRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _isRegistered = true;
    debugPrint('[AppLifecycle] Observer registered');
  }

  /// Unregister the lifecycle observer.
  void unregister() {
    if (!_isRegistered) return;
    WidgetsBinding.instance.removeObserver(this);
    _isRegistered = false;
    debugPrint('[AppLifecycle] Observer unregistered');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        // App is being closed — clear video cache and compression temp files
        debugPrint('[AppLifecycle] App DETACHED — clearing video cache');
        VideoCacheManager().clearAll();
        VideoCompressService().cleanUp();
        // Potential fix for Geolocator NPE: ensure no listeners are active
        // (Geolocator usually handles this but explicit stop is safer)
        break;

      case AppLifecycleState.paused:
        // App minimized — do NOT clear cache (user explicitly requested this)
        debugPrint('[AppLifecycle] App PAUSED — keeping cache intact');
        break;

      case AppLifecycleState.inactive:
        // App transitioning (e.g. phone call, dialog) — do nothing
        debugPrint('[AppLifecycle] App INACTIVE — no action');
        break;

      case AppLifecycleState.resumed:
        // App back to foreground — no action needed
        debugPrint('[AppLifecycle] App RESUMED');
        break;

      case AppLifecycleState.hidden:
        // App hidden but not paused — no action
        debugPrint('[AppLifecycle] App HIDDEN — no action');
        break;
    }
  }
}
