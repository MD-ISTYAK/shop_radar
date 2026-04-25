import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileManager {
  static const String magicoFolderName = 'Magico';

  /// Gets the path to the Magico folder in the device's Download directory
  static Future<String> getMagicoPath() async {
    String? baseDir;
    
    if (Platform.isAndroid) {
      // On Android, we try to get the public Download folder
      // /storage/emulated/0/Download
      baseDir = '/storage/emulated/0/Download';
      
      // Verify if it exists, if not fallback to external storage
      if (!await Directory(baseDir).exists()) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Fallback to Android/data/com.example.app/files/Download
          baseDir = p.join(externalDir.path, 'Download');
        } else {
          // Final fallback to documents
          final docsDir = await getApplicationDocumentsDirectory();
          baseDir = docsDir.path;
        }
      }
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      baseDir = dir.path;
    } else {
      final dir = await getDownloadsDirectory();
      baseDir = dir?.path ?? (await getApplicationDocumentsDirectory()).path;
    }

    final magicoPath = p.join(baseDir, magicoFolderName);
    final magicoDir = Directory(magicoPath);
    
    if (!await magicoDir.exists()) {
      await magicoDir.create(recursive: true);
    }
    
    return magicoPath;
  }

  /// Lists all files in the Magico folder
  static Future<List<File>> listFiles() async {
    try {
      final path = await getMagicoPath();
      final dir = Directory(path);
      if (!await dir.exists()) return [];
      
      final List<FileSystemEntity> entities = await dir.list().toList();
      return entities.whereType<File>().toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (e) {
      return [];
    }
  }

  /// Categorizes files into Images, Videos, PDFs, etc.
  static Map<String, List<File>> categorizeFiles(List<File> files) {
    final Map<String, List<File>> categorized = {
      'All': [],
      'Images': [],
      'Videos': [],
      'Documents': [],
    };

    for (var file in files) {
      categorized['All']!.add(file);
      final ext = p.extension(file.path).toLowerCase();
      
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext)) {
        categorized['Images']!.add(file);
      } else if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext)) {
        categorized['Videos']!.add(file);
      } else if (['.pdf', '.doc', '.docx', '.txt', '.pdf'].contains(ext)) {
        categorized['Documents']!.add(file);
      }
    }
    
    return categorized;
  }

  static String getFileSizeString(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length - 1) / 3;
    var suffix = suffixes[i.floor()];
    return (bytes / (1024 * i.floor())).toStringAsFixed(1) + " " + suffix;
  }
}
