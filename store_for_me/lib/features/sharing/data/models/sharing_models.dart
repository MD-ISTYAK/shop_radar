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
  final String fileName;
  final int totalBytes;
  final int bytesSent;
  final double speed; // in KB/s or MB/s
  final TransferStatus status;
  final String? error;

  TransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.bytesSent,
    required this.speed,
    required this.status,
    this.error,
  });

  double get progress => totalBytes > 0 ? bytesSent / totalBytes : 0.0;

  TransferProgress copyWith({
    String? fileName,
    int? totalBytes,
    int? bytesSent,
    double? speed,
    TransferStatus? status,
    String? error,
  }) {
    return TransferProgress(
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesSent: bytesSent ?? this.bytesSent,
      speed: speed ?? this.speed,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}
