import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/delivery_partner_model.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class DeliveryPartnerState {
  final DeliveryPartnerModel? partner;
  final List<dynamic> availableDeliveries;
  final List<dynamic> activeDeliveries;
  final Map<String, dynamic>? earnings;
  final bool isLoading;
  final String? error;

  DeliveryPartnerState({this.partner, this.availableDeliveries = const [], this.activeDeliveries = const [], this.earnings, this.isLoading = false, this.error});

  bool get isRegistered => partner != null;
  bool get isOnline => partner?.isOnline ?? false;
  bool get isKYCVerified => partner?.kycStatus == 'verified';

  DeliveryPartnerState copyWith({DeliveryPartnerModel? partner, List<dynamic>? availableDeliveries, List<dynamic>? activeDeliveries, Map<String, dynamic>? earnings, bool? isLoading, String? error}) {
    return DeliveryPartnerState(
      partner: partner ?? this.partner,
      availableDeliveries: availableDeliveries ?? this.availableDeliveries,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      earnings: earnings ?? this.earnings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DeliveryPartnerNotifier extends StateNotifier<DeliveryPartnerState> {
  final ApiService _api = ApiService();
  final SocketService _socket = SocketService();
  
  DeliveryPartnerNotifier() : super(DeliveryPartnerState()) {
    initializeSockets();
  }

  void initializeSockets() {
    _socket.onDeliveryNewRequest((data) {
      final updatedList = List<dynamic>.from(state.availableDeliveries);
      // Avoid duplicates
      final exists = updatedList.any((d) => d['_id'] == data['_id']);
      if (!exists) {
        updatedList.insert(0, data);
        state = state.copyWith(availableDeliveries: updatedList);
      }
    });

    _socket.onDeliveryClaimed((data) {
      final deliveryId = data['deliveryId'];
      final claimerId = data['claimerId'];
      
      // If someone else claimed it, remove from available
      final updatedList = state.availableDeliveries.where((d) => d['_id'] != deliveryId).toList();
      state = state.copyWith(availableDeliveries: updatedList);
      
      // If we claimed it, we already updated our activeDeliveries in acceptDelivery()
    });
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getPartnerProfile();
      final profileData = res.data['data'];
      final partner = DeliveryPartnerModel.fromJson(profileData);
      final activeDeliveries = profileData['activeDeliveries'] ?? [];
      state = state.copyWith(partner: partner, activeDeliveries: activeDeliveries, isLoading: false);
      
      // Also fetch earnings if registered
      if (partner.id.isNotEmpty) {
        fetchEarnings();
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
          state = state.copyWith(isLoading: false, partner: null, error: null);
        } else {
          final message = e.response?.data['message'] ?? e.message ?? 'Something went wrong';
          state = state.copyWith(isLoading: false, error: message.toString());
        }
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<bool> register(String vehicleType, {String? vehicleNumber, String? licenseNumber}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.registerAsDeliveryPartner({
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber ?? '',
        'licenseNumber': licenseNumber ?? '',
      });
      
      if (res.data['success']) {
        final partner = DeliveryPartnerModel.fromJson(res.data['data']);
        state = state.copyWith(partner: partner, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Registration failed');
      return false;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final message = e.response?.data['message'];
        if (message == 'Already registered as delivery partner') {
          await fetchProfile(); // Recovery: Fetch the profile anyway
          return true;
        }
        state = state.copyWith(isLoading: false, error: message);
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> verifySelf() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.dio.post('/delivery-partner/verify-self');
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> toggleOnline({double? lat, double? lng}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.togglePartnerOnline(lat: lat, lng: lng);
      await fetchProfile();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchAvailableDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getAvailableDeliveries();
      state = state.copyWith(availableDeliveries: res.data['data'] ?? [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> acceptDelivery(String deliveryId) async {
    try {
      final res = await _api.acceptDelivery(deliveryId);
      if (res.data['success']) {
        final updatedAvailable = state.availableDeliveries.where((d) => d['_id'] != deliveryId).toList();
        state = state.copyWith(availableDeliveries: updatedAvailable);
        await fetchProfile();
        return null; // Success
      }
      return res.data['message'] ?? 'Failed to accept';
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        return e.response?.data['message'] ?? 'Already taken';
      }
      return 'Connection error';
    }
  }

  Future<bool> completeDelivery(String deliveryId, FormData data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.completeDelivery(deliveryId, data);
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> fetchEarnings() async {
    try {
      final res = await _api.getPartnerEarnings();
      state = state.copyWith(earnings: res.data['data']);
    } catch (e) {
      // Just log internally or set error if needed
      print('Earnings Fetch Error: $e');
    }
  }

  @override
  void dispose() {
    _socket.offEvent('delivery:newRequest');
    _socket.offEvent('delivery:claimed');
    super.dispose();
  }
}

final deliveryPartnerProvider = StateNotifierProvider<DeliveryPartnerNotifier, DeliveryPartnerState>((ref) => DeliveryPartnerNotifier());



