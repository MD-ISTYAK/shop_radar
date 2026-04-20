import 'dart:async';
import 'dart:io';

class ConnectionService {
  ServerSocket? _serverSocket;
  Socket? _clientSocket;

  final _connectionController = StreamController<Socket>.broadcast();
  Stream<Socket> get onNewConnection => _connectionController.stream;

  Future<void> startServer(int port) async {
    _serverSocket?.close();
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _serverSocket!.listen((socket) {
      _connectionController.add(socket);
    });
  }

  Future<Socket> connectToPeer(String ip, int port) async {
    _clientSocket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
    return _clientSocket!;
  }

  Future<void> stopServer() async {
    await _serverSocket?.close();
    _serverSocket = null;
  }

  Future<void> disconnect() async {
    await _clientSocket?.close();
    _clientSocket = null;
  }
}
