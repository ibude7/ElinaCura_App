import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A mutation waiting to sync when connectivity returns.
class QueuedMutation {
  const QueuedMutation({
    required this.id,
    required this.method,
    required this.path,
    this.body,
    required this.createdAt,
  });

  factory QueuedMutation.fromJson(Map<String, dynamic> json) {
    return QueuedMutation(
      id: json['id'] as String? ?? '',
      method: json['method'] as String? ?? 'POST',
      path: json['path'] as String? ?? '',
      body: json['body'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        if (body != null) 'body': body,
        'created_at': createdAt.toIso8601String(),
      };
}

class OfflineQueueNotifier extends AsyncNotifier<List<QueuedMutation>> {
  static const _key = 'ec.offline_queue.v1';

  @override
  Future<List<QueuedMutation>> build() async => _load();

  Future<List<QueuedMutation>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => QueuedMutation.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v)),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<QueuedMutation> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(items);
  }

  Future<void> enqueue({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    final current = List<QueuedMutation>.from(state.valueOrNull ?? []);
    current.add(
      QueuedMutation(
        id: 'q-${DateTime.now().millisecondsSinceEpoch}',
        method: method,
        path: path,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
    await _persist(current);
  }

  Future<void> clear() async => _persist([]);

  Future<void> remove(String id) async {
    final current = List<QueuedMutation>.from(state.valueOrNull ?? []);
    current.removeWhere((e) => e.id == id);
    await _persist(current);
  }
}

final offlineQueueProvider =
    AsyncNotifierProvider<OfflineQueueNotifier, List<QueuedMutation>>(
  OfflineQueueNotifier.new,
);
