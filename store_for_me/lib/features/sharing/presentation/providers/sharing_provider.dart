import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/discovery_service.dart';
import '../../services/connection_service.dart';
import '../../services/transfer_service.dart';
import '../../data/models/sharing_models.dart';
import '../../../../core/utils/file_manager.dart';

class SharingState {
  final List<PeerDevice> discoveredDevices;
  final Map<String, TransferProgress> activeTransfers;
  final bool isReceiving;
  final bool isSending;
  final String? error;

  SharingState({
    this.discoveredDevices = const [],
    this.activeTransfers = const {},
    this.isReceiving = false,
    this.isSending = false,
    this.error,
  });

  SharingState copyWith({
    List<PeerDevice>? discoveredDevices,
    Map<String, TransferProgress>? activeTransfers,
    bool? isReceiving,
    bool? isSending,
    String? error,
  }) {
    return SharingState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      activeTransfers: activeTransfers ?? this.activeTransfers,
      isReceiving: isReceiving ?? this.isReceiving,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }
}

class SharingNotifier extends StateNotifier<SharingState> {
  final DiscoveryService _discoveryService;
  final ConnectionService _connectionService;
  final TransferService _transferService;

  SharingNotifier(
    this._discoveryService,
    this._connectionService,
    this._transferService,
  ) : super(SharingState());

  void startDiscovery() {
    state = state.copyWith(discoveredDevices: []);
    _discoveryService.discoveredDevices.listen((device) {
      if (!state.discoveredDevices.any((d) => d.ip == device.ip)) {
        state = state.copyWith(
          discoveredDevices: [...state.discoveredDevices, device],
        );
      }
    });
    _discoveryService.startDiscovery();
    _discoveryService.startFallbackDiscovery();
  }

  void stopDiscovery() {
    _discoveryService.stopDiscovery();
  }

  Future<void> startReceiveMode(String deviceName) async {
    state = state.copyWith(isReceiving: true, error: null, activeTransfers: {});
    try {
      await _connectionService.startServer(5555);
      await _discoveryService.startBroadcasting(deviceName, 5555);

      _connectionService.onNewConnection.listen((socket) async {
        final savePath = await FileManager.getMagicoPath();
        
        _transferService.progressStream.listen((progress) {
          state = state.copyWith(
            activeTransfers: {
              ...state.activeTransfers,
              progress.id: progress,
            },
          );
        });

        await _transferService.receiveFiles(socket, savePath, deviceName);
        socket.destroy();
      });
    } catch (e) {
      state = state.copyWith(isReceiving: false, error: e.toString());
    }
  }

  Future<void> stopReceiveMode() async {
    await _connectionService.stopServer();
    await _discoveryService.stopBroadcasting();
    state = state.copyWith(isReceiving: false);
  }

  Future<void> sendFilesToDevice(PeerDevice device, List<File> files, String myName) async {
    state = state.copyWith(isSending: true, error: null, activeTransfers: {});
    try {
      final socket = await _connectionService.connectToPeer(device.ip, device.port);
      
      _transferService.progressStream.listen((progress) {
        state = state.copyWith(
          activeTransfers: {
            ...state.activeTransfers,
            progress.id: progress,
          },
        );
      });

      await _transferService.sendFiles(socket, files, myName);
      await socket.flush();
      socket.destroy();
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  void resetTransfer() {
    state = state.copyWith(activeTransfers: {});
  }
}

final discoveryServiceProvider = Provider((ref) => DiscoveryService());
final connectionServiceProvider = Provider((ref) => ConnectionService());
final transferServiceProvider = Provider((ref) => TransferService());

final sharingProvider = StateNotifierProvider<SharingNotifier, SharingState>((ref) {
  return SharingNotifier(
    ref.watch(discoveryServiceProvider),
    ref.watch(connectionServiceProvider),
    ref.watch(transferServiceProvider),
  );
});
