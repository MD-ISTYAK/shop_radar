import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../data/models/sharing_models.dart';

class TransferService {
  final _progressController = StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get progressStream => _progressController.stream;

  static const int chunkSize = 64 * 1024; // 64KB chunks

  Future<void> sendFile(Socket socket, File file) async {
    final fileName = p.basename(file.path);
    final totalBytes = await file.length();
    int bytesSent = 0;
    
    // Send metadata first
    final metadata = {
      'name': fileName,
      'size': totalBytes,
    };
    final metaString = jsonEncode(metadata) + '\n';
    socket.write(metaString);
    await socket.flush();

    final stopwatch = Stopwatch()..start();
    
    try {
      final stream = file.openRead();
      await for (final chunk in stream) {
        socket.add(chunk);
        bytesSent += chunk.length;
        
        final duration = stopwatch.elapsed.inMilliseconds / 1000;
        final speed = duration > 0 ? (bytesSent / 1024) / duration : 0.0; // KB/s

        _progressController.add(TransferProgress(
          fileName: fileName,
          totalBytes: totalBytes,
          bytesSent: bytesSent,
          speed: speed,
          status: TransferStatus.sending,
        ));
      }
      
      await socket.flush();
      _progressController.add(TransferProgress(
        fileName: fileName,
        totalBytes: totalBytes,
        bytesSent: bytesSent,
        speed: 0,
        status: TransferStatus.completed,
      ));
    } catch (e) {
      _progressController.add(TransferProgress(
        fileName: fileName,
        totalBytes: totalBytes,
        bytesSent: bytesSent,
        speed: 0,
        status: TransferStatus.failed,
        error: e.toString(),
      ));
    } finally {
      stopwatch.stop();
    }
  }

  Future<void> receiveFile(Socket socket, String saveDir) async {
    String? fileName;
    int? totalBytes;
    int bytesReceived = 0;
    IOSink? fileSink;
    
    final stopwatch = Stopwatch()..start();
    bool metaReceived = false;
    
    try {
      await for (final data in socket) {
        if (!metaReceived) {
          // Read metadata (until newline)
          final content = utf8.decode(data, allowMalformed: true);
          if (content.contains('\n')) {
            final line = content.split('\n').first;
            final metadata = jsonDecode(line);
            fileName = metadata['name'];
            totalBytes = metadata['size'];
            
            final filePath = p.join(saveDir, fileName);
            final file = File(filePath);
            if (!await file.parent.exists()) {
              await file.parent.create(recursive: true);
            }
            fileSink = file.openWrite();
            
            // Handle the rest of the data in this chunk after the '\n'
            final metaLength = utf8.encode(line + '\n').length;
            if (data.length > metaLength) {
              final remainingData = data.sublist(metaLength);
              fileSink.add(remainingData);
              bytesReceived += remainingData.length;
            }
            
            metaReceived = true;
          }
        } else {
          fileSink?.add(data);
          bytesReceived += data.length;
        }

        if (fileName != null && totalBytes != null) {
          final duration = stopwatch.elapsed.inMilliseconds / 1000;
          final speed = duration > 0 ? (bytesReceived / 1024) / duration : 0.0;

          _progressController.add(TransferProgress(
            fileName: fileName,
            totalBytes: totalBytes,
            bytesSent: bytesReceived,
            speed: speed,
            status: TransferStatus.receiving,
          ));
          
          if (bytesReceived >= totalBytes) {
            break;
          }
        }
      }
      
      await fileSink?.close();
      _progressController.add(TransferProgress(
        fileName: fileName ?? 'Unknown',
        totalBytes: totalBytes ?? 0,
        bytesSent: bytesReceived,
        speed: 0,
        status: TransferStatus.completed,
      ));
    } catch (e) {
      await fileSink?.close();
      _progressController.add(TransferProgress(
        fileName: fileName ?? 'Unknown',
        totalBytes: totalBytes ?? 0,
        bytesSent: bytesReceived,
        speed: 0,
        status: TransferStatus.failed,
        error: e.toString(),
      ));
    } finally {
      stopwatch.stop();
    }
  }
}
