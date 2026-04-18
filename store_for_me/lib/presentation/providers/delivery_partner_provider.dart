import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_partner_model.dart';
import '../../services/api_service.dart';

class DeliveryPartnerState {
  final DeliveryPartnerModel? partner;
  final List<dynamic> availableDeliveries;
  final Map<String, dynamic>? earnings;
  final bool isLoading;
  final String? error;

  DeliveryPartnerState({this.partner, this.availableDeliveries = const [], this.earnings, this.isLoading = false, this.error});

  bool get isRegistered => partner != null;
  bool get isOnline => partner?.isOnline ?? false;
  bool get isKYCVerified => partner?.kycStatus == 'verified';

  DeliveryPartnerState copyWith({DeliveryPartnerModel? partner, List<dynamic>? availableDeliveries, Map<String, dynamic>? earnings, bool? isLoading, String? error}) {
    return DeliveryPartnerState(
      partner: partner ?? this.partner,
      availableDeliveries: availableDeliveries ?? this.availableDeliveries,
      earnings: earnings ?? this.earnings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DeliveryPartnerNotifier extends StateNotifier<DeliveryPartnerState> {
  final ApiService _api = ApiService();
  DeliveryPartnerNotifier() : super(DeliveryPartnerState());

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getPartnerProfile();
      final partner = DeliveryPartnerModel.fromJson(res.data['data']);
      state = state.copyWith(partner: partner, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> register(String vehicleType, {String? vehicleNumber, String? licenseNumber}) async {
    try {
      await _api.registerAsDeliveryPartner({
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber ?? '',
        'licenseNumber': licenseNumber ?? '',
      });
      await fetchProfile();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleOnline({double? lat, double? lng}) async {
    try {
      await _api.togglePartnerOnline(lat: lat, lng: lng);
      await fetchProfile();
    } catch (_) {}
  }

  Future<void> fetchAvailableDeliveries() async {
    try {
      final res = await _api.getAvailableDeliveries();
      state = state.copyWith(availableDeliveries: res.data['data'] ?? []);
    } catch (_) {}
  }

  Future<bool> acceptDelivery(String deliveryId) async {
    try {
      await _api.acceptDelivery(deliveryId);
      await fetchProfile();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeDelivery(String deliveryId) async {
    try {
      await _api.completeDelivery(deliveryId);
      await fetchProfile();
      await fetchEarnings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchEarnings() async {
    try {
      final res = await _api.getPartnerEarnings();
      state = state.copyWith(earnings: res.data['data']);
    } catch (_) {}
  }
}

final deliveryPartnerProvider = StateNotifierProvider<DeliveryPartnerNotifier, DeliveryPartnerState>((ref) => DeliveryPartnerNotifier());
