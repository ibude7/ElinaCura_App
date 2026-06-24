import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/models.dart';

/// Stable key for a single dose slot of a medication (medId + 24h time).
String doseSlotKey(String medId, String time) => '$medId@$time';

/// 'yyyy-mm-dd' key for a calendar day.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// On-device record of which dose slots the user marked taken, grouped by day.
/// Lets us show real adherence without a backend round-trip, and persists
/// across launches via SharedPreferences.
class DoseLogNotifier extends AsyncNotifier<Map<String, Set<String>>> {
  static const _key = 'ec.dose_log.v1';

  @override
  Future<Map<String, Set<String>>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (day, slots) => MapEntry(
          day,
          (slots as List).map((e) => e.toString()).toSet(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist(Map<String, Set<String>> value) async {
    final prefs = await SharedPreferences.getInstance();
    final encodable = value.map((k, v) => MapEntry(k, v.toList()));
    await prefs.setString(_key, jsonEncode(encodable));
  }

  /// Toggle a dose slot's taken state for [day] (defaults to today).
  Future<void> toggle(String slot, {DateTime? day}) async {
    final current = Map<String, Set<String>>.from(state.valueOrNull ?? {});
    final key = dayKey(day ?? DateTime.now());
    final daySet = Set<String>.from(current[key] ?? const <String>{});
    if (!daySet.add(slot)) daySet.remove(slot);
    current[key] = daySet;
    state = AsyncData(current);
    await _persist(current);
  }

  bool isTaken(String slot, {DateTime? day}) {
    final key = dayKey(day ?? DateTime.now());
    return state.valueOrNull?[key]?.contains(slot) ?? false;
  }
}

final doseLogProvider =
    AsyncNotifierProvider<DoseLogNotifier, Map<String, Set<String>>>(
  DoseLogNotifier.new,
);

/// Snapshot of adherence derived from the dose log + the user's medications.
class AdherenceData {
  const AdherenceData({
    required this.todayTaken,
    required this.todayScheduled,
    required this.weekRatios,
  });

  final int todayTaken;
  final int todayScheduled;

  /// 7 entries, oldest first, each 0..1 — the trailing week including today.
  final List<double> weekRatios;

  double get todayRatio => todayScheduled == 0 ? 0 : todayTaken / todayScheduled;
  int get todayPercent => (todayRatio * 100).round();
  bool get hasSchedule => todayScheduled > 0;
}

/// Pure, testable computation of adherence from a dose log and medications.
AdherenceData computeAdherence(
  Map<String, Set<String>> log,
  List<MedicationItem> meds, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final slotsPerDay = <String>[
    for (final m in meds)
      for (final t in m.times) doseSlotKey(m.id, t),
  ];
  final scheduledPerDay = slotsPerDay.length;
  final slotSet = slotsPerDay.toSet();

  int takenOn(DateTime d) =>
      log[dayKey(d)]?.where(slotSet.contains).length ?? 0;

  final week = <double>[];
  final base = DateTime(today.year, today.month, today.day);
  for (var i = 6; i >= 0; i--) {
    final taken = takenOn(base.subtract(Duration(days: i)));
    week.add(
      scheduledPerDay == 0 ? 0 : (taken / scheduledPerDay).clamp(0.0, 1.0),
    );
  }

  return AdherenceData(
    todayTaken: takenOn(today),
    todayScheduled: scheduledPerDay,
    weekRatios: week,
  );
}
