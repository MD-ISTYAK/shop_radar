import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallet_model.dart';
import '../../services/api_service.dart';

class WalletState {
  final WalletModel? wallet;
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? error;

  WalletState({this.wallet, this.transactions = const [], this.isLoading = false, this.error});

  double get balance => wallet?.balance ?? 0;

  WalletState copyWith({WalletModel? wallet, List<TransactionModel>? transactions, bool? isLoading, String? error}) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final ApiService _api = ApiService();
  WalletNotifier() : super(WalletState());

  Future<void> fetchWallet() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.getWallet();
      final wallet = WalletModel.fromJson(res.data['data']);
      state = state.copyWith(wallet: wallet, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchTransactions() async {
    try {
      final res = await _api.getWalletTransactions();
      final list = (res.data['data'] as List).map((e) => TransactionModel.fromJson(e)).toList();
      state = state.copyWith(transactions: list);
    } catch (_) {}
  }

  Future<bool> addMoney(double amount, String paymentId) async {
    try {
      final res = await _api.addMoneyToWallet(amount, paymentId);
      final wallet = WalletModel.fromJson(res.data['data']);
      state = state.copyWith(wallet: wallet);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) => WalletNotifier());
