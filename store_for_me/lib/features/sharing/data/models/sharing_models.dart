import 'dart:io';

enum TransferStatus {
  idle,
  connecting,
  sending,
  receiving,
  completed,
  failed,
  cancelled
}

enum TransferType {
  upload,
  download
}

class PeerDevice {
  final String name;
  final String ip;
  final int port;

  PeerDevice({
    required this.name,
    required this.ip,
    required this.port,
  });

  @override
  String toString() => 'PeerDevice(name: $name, ip: $ip, port: $port)';
}

class TransferProgress {
  final String id;
  final String fileName;
  final String? peerName;
  final int totalBytes;
  final int bytesSent;
  final double speed; // in KB/s or MB/s
  final TransferStatus status;
  final TransferType type;
  final String? error;

  TransferProgress({
    required this.id,
    required this.fileName,
    this.peerName,
    required this.totalBytes,
    required this.bytesSent,
    required this.speed,
    required this.status,
    required this.type,
    this.error,
  });

  double get progress => totalBytes > 0 ? bytesSent / totalBytes : 0.0;

  TransferProgress copyWith({
    String? id,
    String? fileName,
    String? peerName,
    int? totalBytes,
    int? bytesSent,
    double? speed,
    TransferStatus? status,
    TransferType? type,
    String? error,
  }) {
    return TransferProgress(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      peerName: peerName ?? this.peerName,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesSent: bytesSent ?? this.bytesSent,
      speed: speed ?? this.speed,
      status: status ?? this.status,
      type: type ?? this.type,
      error: error ?? this.error,
    );
  }
}
