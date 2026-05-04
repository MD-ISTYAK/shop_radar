import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryItem {
  final String id;
  final String fileName;
  final int sizeBytes;
  final String? fileType; // 'app', 'video', 'photo', 'file', 'music'
  final String peerName;
  final bool isSent;
  final String status; // 'success' | 'failed'
  final DateTime timestamp;
  final String? filePath;

  HistoryItem({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    this.fileType,
    required this.peerName,
    required this.isSent,
    required this.status,
    required this.timestamp,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        'fileType': fileType,
        'peerName': peerName,
        'isSent': isSent,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'filePath': filePath,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        sizeBytes: json['sizeBytes'] as int,
        fileType: json['fileType'] as String?,
        peerName: json['peerName'] as String,
        isSent: json['isSent'] as bool,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        filePath: json['filePath'] as String?,
      );
}

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  static const _key = 'file_share_history';

  HistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => HistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = list;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> addItem(HistoryItem item) async {
    state = [item, ...state];
    await _save();
  }

  Future<void> removeItem(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryItem>>(
        (_) => HistoryNotifier());
