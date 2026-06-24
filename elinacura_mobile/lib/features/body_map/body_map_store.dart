import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tappable anatomical regions on the front-body silhouette.
enum BodyRegion {
  head,
  chest,
  abdomen,
  leftArm,
  rightArm,
  leftLeg,
  rightLeg,
}

extension BodyRegionX on BodyRegion {
  String get label => switch (this) {
        BodyRegion.head => 'Head',
        BodyRegion.chest => 'Chest',
        BodyRegion.abdomen => 'Abdomen',
        BodyRegion.leftArm => 'Left arm',
        BodyRegion.rightArm => 'Right arm',
        BodyRegion.leftLeg => 'Left leg',
        BodyRegion.rightLeg => 'Right leg',
      };
}

/// Maps free-text condition names to the body regions they implicate, so the
/// silhouette can highlight relevant zones in jade.
Set<BodyRegion> zonesForConditions(List<String> conditions) {
  final zones = <BodyRegion>{};
  for (final raw in conditions) {
    final c = raw.toLowerCase();
    if (c.contains('diabet') ||
        c.contains('kidney') ||
        c.contains('liver') ||
        c.contains('stomach') ||
        c.contains('ibs') ||
        c.contains('gi') ||
        c.contains('crohn')) {
      zones.add(BodyRegion.abdomen);
    }
    if (c.contains('hypertens') ||
        c.contains('heart') ||
        c.contains('cardi') ||
        c.contains('asthma') ||
        c.contains('copd') ||
        c.contains('lung') ||
        c.contains('respir')) {
      zones.add(BodyRegion.chest);
    }
    if (c.contains('migraine') ||
        c.contains('headache') ||
        c.contains('anxiety') ||
        c.contains('depress') ||
        c.contains('insomnia')) {
      zones.add(BodyRegion.head);
    }
    if (c.contains('arthrit') || c.contains('joint') || c.contains('fibro')) {
      zones.addAll([
        BodyRegion.leftArm,
        BodyRegion.rightArm,
        BodyRegion.leftLeg,
        BodyRegion.rightLeg,
      ]);
    }
  }
  return zones;
}

/// A logged symptom for a body region.
class SymptomEntry {
  const SymptomEntry({
    required this.severity,
    required this.note,
    required this.timestamp,
  });

  /// 1..5
  final int severity;
  final String note;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        's': severity,
        'n': note,
        't': timestamp.millisecondsSinceEpoch,
      };

  factory SymptomEntry.fromJson(Map<String, dynamic> j) => SymptomEntry(
        severity: (j['s'] as num?)?.toInt() ?? 1,
        note: j['n'] as String? ?? '',
        timestamp:
            DateTime.fromMillisecondsSinceEpoch((j['t'] as num?)?.toInt() ?? 0),
      );
}

/// Persisted latest symptom per region (on-device).
class SymptomLogNotifier extends AsyncNotifier<Map<BodyRegion, SymptomEntry>> {
  static const _key = 'ec.body_map.v1';

  @override
  Future<Map<BodyRegion, SymptomEntry>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <BodyRegion, SymptomEntry>{};
      for (final region in BodyRegion.values) {
        final v = decoded[region.name];
        if (v is Map<String, dynamic>) {
          out[region] = SymptomEntry.fromJson(v);
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> log(BodyRegion region, int severity, String note) async {
    final current =
        Map<BodyRegion, SymptomEntry>.from(state.valueOrNull ?? {});
    current[region] = SymptomEntry(
      severity: severity,
      note: note,
      timestamp: DateTime.now(),
    );
    state = AsyncData(current);
    final prefs = await SharedPreferences.getInstance();
    final encodable = {
      for (final e in current.entries) e.key.name: e.value.toJson(),
    };
    await prefs.setString(_key, jsonEncode(encodable));
  }

  Future<void> clear(BodyRegion region) async {
    final current =
        Map<BodyRegion, SymptomEntry>.from(state.valueOrNull ?? {});
    current.remove(region);
    state = AsyncData(current);
    final prefs = await SharedPreferences.getInstance();
    final encodable = {
      for (final e in current.entries) e.key.name: e.value.toJson(),
    };
    await prefs.setString(_key, jsonEncode(encodable));
  }
}

final symptomLogProvider =
    AsyncNotifierProvider<SymptomLogNotifier, Map<BodyRegion, SymptomEntry>>(
  SymptomLogNotifier.new,
);
