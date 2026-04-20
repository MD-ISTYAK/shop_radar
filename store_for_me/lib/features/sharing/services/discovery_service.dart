import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../data/models/sharing_models.dart';

class DiscoveryService {
  static const String serviceType = '_shopradar._tcp.local';
  MDnsClient? _mdnsClient;
  bool _isBroadcasting = false;

  final _deviceController = StreamController<PeerDevice>.broadcast();
  Stream<PeerDevice> get discoveredDevices => _deviceController.stream;

  Future<void> startDiscovery() async {
    _mdnsClient?.stop();
    _mdnsClient = MDnsClient();
    await _mdnsClient!.start();

    final Stream<PtrResourceRecord> ptrStream = _mdnsClient!
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceType));

    await for (final PtrResourceRecord ptr in ptrStream) {
      final Stream<SrvResourceRecord> srvStream = _mdnsClient!
          .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName));

      await for (final SrvResourceRecord srv in srvStream) {
        final Stream<IPAddressResourceRecord> ipStream = _mdnsClient!
            .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target));

        await for (final IPAddressResourceRecord ip in ipStream) {
          final device = PeerDevice(
            name: srv.target.split('.').first,
            ip: ip.address.address,
            port: srv.port,
          );
          _deviceController.add(device);
        }
      }
    }
  }

  Future<void> stopDiscovery() async {
    _mdnsClient?.stop();
    _mdnsClient = null;
  }

  // Note: Standard multidns package in Dart doesn't have easy "broadcast" (Responder) 
  // implementation outside of specific plugins like 'bonsoir' or 'nsd'.
  // However, I will implement a basic "listening" logic and a way to announce via a 
  // custom UDP broadcast as a fallback if mDNS responder is complex in pure dart.
  // For production, usually 'bonsoir' is preferred. 
  // Given the constraints to use 'multicast_dns', I'll focus on the lookup.
  // For broadcasting, I'll use a UDP broadcast fallback.

  Future<void> startBroadcasting(String deviceName, int port) async {
    if (_isBroadcasting) return;
    _isBroadcasting = true;

    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
      socket.broadcastEnabled = true;
      Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (!_isBroadcasting) {
          timer.cancel();
          socket.close();
          return;
        }
        final info = NetworkInfo();
        final ip = await info.getWifiIP();
        if (ip != null) {
          final message = 'SHOP_RADAR_PEER:$deviceName:$ip:$port';
          socket.send(message.codeUnits, InternetAddress('255.255.255.255'), 5556);
        }
      });
    });
  }

  Future<void> stopBroadcasting() async {
    _isBroadcasting = false;
  }

  // Fallback Discovery via UDP
  Future<void> startFallbackDiscovery() async {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 5556).then((socket) {
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data);
            if (message.startsWith('SHOP_RADAR_PEER:')) {
              final parts = message.split(':');
              if (parts.length == 4) {
                final device = PeerDevice(
                  name: parts[1],
                  ip: parts[2],
                  port: int.parse(parts[3]),
                );
                _deviceController.add(device);
              }
            }
          }
        }
      });
    });
  }
}
