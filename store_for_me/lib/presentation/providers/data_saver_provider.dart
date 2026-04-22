import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataSaverNotifier extends StateNotifier<bool> {
  DataSaverNotifier() : super(false) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('data_saver_mode') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_saver_mode', state);
  }
}

final dataSaverProvider = StateNotifierProvider<DataSaverNotifier, bool>((ref) {
  return DataSaverNotifier();
});
