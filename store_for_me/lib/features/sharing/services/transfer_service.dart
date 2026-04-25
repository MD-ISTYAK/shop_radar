import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../data/models/sharing_models.dart';

class TransferService {
  final _progressController = StreamController<TransferProgress>.broadcast();
  Stream<TransferProgress> get progressStream => _progressController.stream;

  static const int chunkSize = 64 * 1024; // 64KB chunks

  /// Sends multiple files to a peer
  Future<void> sendFiles(Socket socket, List<File> files, String myName) async {
    String? peerName;
    
    try {
      // 1. Handshake: Send my name and wait for peer name
      socket.write('HANDSHAKE:$myName\n');
      await socket.flush();
      
      // Wait for peer handshake (timeout after 5s)
      final handshakeCompleter = Completer<String>();
      final subscription = socket.listen((data) {
        final msg = utf8.decode(data, allowMalformed: true);
        if (msg.startsWith('HANDSHAKE:')) {
          handshakeCompleter.complete(msg.split(':').last.trim());
        }
      });
      
      peerName = await handshakeCompleter.future.timeout(const Duration(seconds: 5));
      await subscription.cancel();

      // 2. Send File Count
      socket.write('COUNT:${files.length}\n');
      await socket.flush();

      // 3. Send Files one by one
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = p.basename(file.path);
        final totalBytes = await file.length();
        final fileId = 'tx_${DateTime.now().millisecondsSinceEpoch}_$i';
        
        int bytesSent = 0;
        
        // Send metadata
        final metadata = {
          'id': fileId,
          'name': fileName,
          'size': totalBytes,
        };
        socket.write('METADATA:${jsonEncode(metadata)}\n');
        await socket.flush();

        final stopwatch = Stopwatch()..start();
        final stream = file.openRead();
        
        await for (final chunk in stream) {
          socket.add(chunk);
          bytesSent += chunk.length;
          
          final duration = stopwatch.elapsed.inMilliseconds / 1000;
          final speed = duration > 0 ? (bytesSent / 1024) / duration : 0.0;

          _progressController.add(TransferProgress(
            id: fileId,
            fileName: fileName,
            peerName: peerName,
            totalBytes: totalBytes,
            bytesSent: bytesSent,
            speed: speed,
            status: TransferStatus.sending,
            type: TransferType.upload,
          ));
        }
        
        await socket.flush();
        stopwatch.stop();
        
        _progressController.add(TransferProgress(
          id: fileId,
          fileName: fileName,
          peerName: peerName,
          totalBytes: totalBytes,
          bytesSent: bytesSent,
          speed: 0,
          status: TransferStatus.completed,
          type: TransferType.upload,
        ));
        
        // Brief pause between files to ensure buffer clear
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _progressController.add(TransferProgress(
        id: 'error',
        fileName: 'Error',
        totalBytes: 0,
        bytesSent: 0,
        speed: 0,
        status: TransferStatus.failed,
        type: TransferType.upload,
        error: e.toString(),
      ));
    } finally {
      // Don't close here, the caller should close the socket
    }
  }

  /// Receives multiple files from a peer
  Future<void> receiveFiles(Socket socket, String saveDir, String myName) async {
    String? peerName;
    int? fileCount;
    int filesReceived = 0;
    
    try {
      // 1. Handshake: Send my name
      socket.write('HANDSHAKE:$myName\n');
      await socket.flush();

      String buffer = '';
      IOSink? currentFileSink;
      String? currentFileName;
      int? currentTotalBytes;
      int currentBytesReceived = 0;
      String? currentFileId;
      Stopwatch? stopwatch;

      await for (final data in socket) {
        if (currentFileSink == null) {
          // Parsing protocol headers
          buffer += utf8.decode(data, allowMalformed: true);
          
          while (buffer.contains('\n')) {
            final index = buffer.indexOf('\n');
            final line = buffer.substring(0, index).trim();
            buffer = buffer.substring(index + 1);

            if (line.startsWith('HANDSHAKE:')) {
              peerName = line.split(':').last;
            } else if (line.startsWith('COUNT:')) {
              fileCount = int.tryParse(line.split(':').last);
            } else if (line.startsWith('METADATA:')) {
              final metadata = jsonDecode(line.split('METADATA:').last);
              currentFileId = metadata['id'];
              currentFileName = metadata['name'];
              currentTotalBytes = metadata['size'];
              currentBytesReceived = 0;
              
              final filePath = p.join(saveDir, currentFileName);
              final file = File(filePath);
              if (!await file.parent.exists()) {
                await file.parent.create(recursive: true);
              }
              currentFileSink = file.openWrite();
              stopwatch = Stopwatch()..start();
              
              // If there's still data in buffer that belongs to the file
              if (buffer.isNotEmpty) {
                final remainingData = utf8.encode(buffer);
                currentFileSink.add(remainingData);
                currentBytesReceived += remainingData.length;
                buffer = ''; // Reset buffer as it's now consumed as binary
              }
              break; // Break header parsing loop to handle binary data
            }
          }
        } else {
          // Writing binary file data
          currentFileSink.add(data);
          currentBytesReceived += data.length;

          if (currentFileName != null && currentTotalBytes != null) {
            final duration = (stopwatch?.elapsed.inMilliseconds ?? 1) / 1000;
            final speed = duration > 0 ? (currentBytesReceived / 1024) / duration : 0.0;

            _progressController.add(TransferProgress(
              id: currentFileId!,
              fileName: currentFileName,
              peerName: peerName,
              totalBytes: currentTotalBytes,
              bytesSent: currentBytesReceived,
              speed: speed,
              status: TransferStatus.receiving,
              type: TransferType.download,
            ));

            if (currentBytesReceived >= currentTotalBytes) {
              await currentFileSink.close();
              stopwatch?.stop();
              
              _progressController.add(TransferProgress(
                id: currentFileId,
                fileName: currentFileName,
                peerName: peerName,
                totalBytes: currentTotalBytes,
                bytesSent: currentBytesReceived,
                speed: 0,
                status: TransferStatus.completed,
                type: TransferType.download,
              ));
              
              currentFileSink = null;
              currentFileName = null;
              filesReceived++;
              
              if (fileCount != null && filesReceived >= fileCount) {
                return; // All files received
              }
            }
          }
        }
      }
    } catch (e) {
      // Log or notify error
    } finally {
      // Cleanup
    }
  }
}
