import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────────────────────────────────────── Domain model ──

/// Every health metric the app can track locally.
enum VitalType {
  heartRate,
  restingHR,
  bloodPressureSystolic,
  bloodPressureDiastolic,
  bloodOxygen,
  hrv,
  weight,
  steps,
}

extension VitalTypeX on VitalType {
  String get key => name;

  String get label => switch (this) {
        VitalType.heartRate => 'Heart rate',
        VitalType.restingHR => 'Resting HR',
        VitalType.bloodPressureSystolic => 'Blood pressure',
        VitalType.bloodPressureDiastolic => 'BP diastolic',
        VitalType.bloodOxygen => 'Blood oxygen',
        VitalType.hrv => 'HRV',
        VitalType.weight => 'Weight',
        VitalType.steps => 'Steps',
      };

  String get unit => switch (this) {
        VitalType.heartRate || VitalType.restingHR => 'bpm',
        VitalType.bloodPressureSystolic ||
        VitalType.bloodPressureDiastolic =>
          'mmHg',
        VitalType.bloodOxygen => '%',
        VitalType.hrv => 'ms',
        VitalType.weight => 'kg',
        VitalType.steps => 'steps',
      };

  IconData get icon => switch (this) {
        VitalType.heartRate || VitalType.restingHR => Icons.favorite_rounded,
        VitalType.bloodPressureSystolic ||
        VitalType.bloodPressureDiastolic =>
          Icons.speed_rounded,
        VitalType.bloodOxygen => Icons.air_rounded,
        VitalType.hrv => Icons.show_chart_rounded,
        VitalType.weight => Icons.monitor_weight_rounded,
        VitalType.steps => Icons.directions_walk_rounded,
      };

  /// Dominant display color for this vital's category.
  Color get color => switch (this) {
        VitalType.heartRate || VitalType.restingHR => const Color(0xFFE84040),
        VitalType.bloodPressureSystolic ||
        VitalType.bloodPressureDiastolic =>
          const Color(0xFFE84040),
        VitalType.bloodOxygen => const Color(0xFF0D9488),
        VitalType.hrv => const Color(0xFF9333EA),
        VitalType.weight => const Color(0xFF0EA5E9),
        VitalType.steps => const Color(0xFF4285F4),
      };

  Color get fillColor => switch (this) {
        VitalType.heartRate || VitalType.restingHR => const Color(0xFFFFEBEB),
        VitalType.bloodPressureSystolic ||
        VitalType.bloodPressureDiastolic =>
          const Color(0xFFFFEBEB),
        VitalType.bloodOxygen => const Color(0xFFCCFBF1),
        VitalType.hrv => const Color(0xFFF3E8FF),
        VitalType.weight => const Color(0xFFE0F2FE),
        VitalType.steps => const Color(0xFFE8F0FE),
      };

  /// "In range" normal bounds. Null means no defined clinical range.
  (double, double)? get normalRange => switch (this) {
        VitalType.heartRate => (60, 100),
        VitalType.restingHR => (40, 80),
        VitalType.bloodPressureSystolic => (90, 120),
        VitalType.bloodPressureDiastolic => (60, 80),
        VitalType.bloodOxygen => (95, 100),
        VitalType.hrv => (20, 65),
        _ => null,
      };

  /// Return 'Good', 'In range', 'Moderate', 'High', or null if no range.
  String? statusLabel(double value) {
    final range = normalRange;
    if (range == null) return null;
    if (value < range.$1) return 'Low';
    if (value > range.$2) return 'High';
    return 'In range';
  }

  bool? isInRange(double value) {
    final range = normalRange;
    if (range == null) return null;
    return value >= range.$1 && value <= range.$2;
  }
}

// ─────────────────────────────────────────── Single reading ──

class VitalEntry {
  const VitalEntry({required this.timestamp, required this.value});

  factory VitalEntry.fromJson(Map<String, dynamic> json) => VitalEntry(
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
        value: (json['v'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'ts': timestamp.millisecondsSinceEpoch,
        'v': value,
      };

  final DateTime timestamp;
  final double value;
}

typedef VitalsLog = Map<VitalType, List<VitalEntry>>;

// ─────────────────────────────────────────── Riverpod store ──

class VitalsNotifier extends AsyncNotifier<VitalsLog> {
  static const _key = 'ec.vitals.v2';
  static const _maxEntries = 90;

  @override
  Future<VitalsLog> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <VitalType, List<VitalEntry>>{};
      for (final type in VitalType.values) {
        final entries = decoded[type.key] as List?;
        if (entries != null) {
          result[type] = entries
              .whereType<Map<String, dynamic>>()
              .map(VitalEntry.fromJson)
              .toList();
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Add a reading and persist immediately.
  Future<void> log(VitalType type, double value) async {
    final current =
        Map<VitalType, List<VitalEntry>>.from(state.valueOrNull ?? {});
    final entries = List<VitalEntry>.from(current[type] ?? [])
      ..add(VitalEntry(timestamp: DateTime.now(), value: value));
    if (entries.length > _maxEntries) {
      entries.removeRange(0, entries.length - _maxEntries);
    }
    current[type] = entries;
    state = AsyncData(current);
    await _persist(current);
  }

  /// Most-recent reading for [type], or null.
  VitalEntry? latest(VitalType type) {
    final entries = state.valueOrNull?[type];
    return (entries?.isNotEmpty == true) ? entries!.last : null;
  }

  /// Most-recent [n] readings for [type] (oldest-first, chart-ready).
  List<VitalEntry> lastN(VitalType type, {int n = 7}) {
    final entries = state.valueOrNull?[type] ?? [];
    return entries.length <= n ? List.of(entries) : entries.sublist(entries.length - n);
  }

  /// Number of distinct types that have at least one reading.
  int get trackedCount =>
      (state.valueOrNull ?? {}).entries.where((e) => e.value.isNotEmpty).length;

  Future<void> _persist(VitalsLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final encodable = <String, dynamic>{
      for (final e in log.entries)
        e.key.key: e.value.map((v) => v.toJson()).toList(),
    };
    await prefs.setString(_key, jsonEncode(encodable));
  }
}

final vitalsProvider =
    AsyncNotifierProvider<VitalsNotifier, VitalsLog>(VitalsNotifier.new);
