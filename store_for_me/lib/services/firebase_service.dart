import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart'; 

class FirebaseService {
  static Future<void> initialize() async {
    // Note: To use DefaultFirebaseOptions, you must first run 'flutterfire configure'
    // For now, we initialize core without it if we want to avoid compile errors,
    // but FCM/Crashlytics will need the actual project config.
    
    try {
      await Firebase.initializeApp(
         options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics setup
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        
        // Pass all uncaught "fatal" errors from the framework to Crashlytics
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        
        // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      }
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
      debugPrint("Make sure to run 'flutterfire configure' to setup your project.");
    }
  }
}
