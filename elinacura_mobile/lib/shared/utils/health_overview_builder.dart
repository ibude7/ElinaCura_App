import '../../shared/models/models.dart';

/// Port of buildHealthOverview from useHealthOverview.js
class HealthOverviewBuilder {
  static HealthOverview build(HealthProfile? profile) {
    final hasProfile = profile != null;
    final medications = hasProfile
        ? profile.medications.asMap().entries.map((e) => _parseMedication(e.value, e.key)).toList()
        : <MedicationItem>[];
    final conditions = hasProfile
        ? profile.conditions.asMap().entries
            .map((e) => ConditionItem(id: 'cond-${e.key}', name: e.value.trim()))
            .toList()
        : <ConditionItem>[];
    final goals = hasProfile && (profile.primaryGoal?.trim().isNotEmpty ?? false)
        ? [GoalItem(id: 'primary', label: profile.primaryGoal!.trim())]
        : <GoalItem>[];

    final keyVitals = <Map<String, String>>[];
    if (profile?.bloodType != null && profile!.bloodType!.isNotEmpty) {
      keyVitals.add({
        'key': 'blood_type',
        'label': 'Blood type',
        'value': profile.bloodType!,
        'unit': '',
      });
    }

    return HealthOverview(
      hasProfile: hasProfile,
      hasAnalytics: false,
      profile: profile,
      medications: medications,
      conditions: conditions,
      goals: goals,
      keyVitals: keyVitals,
    );
  }

  static MedicationItem _parseMedication(String entry, int index) {
    final text = entry.trim();
    final match = RegExp(
      r'^(.*?)[\s,]+(\d[\d.]*\s?(?:mg|mcg|g|ml|iu|units?))\b.*$',
      caseSensitive: false,
    ).firstMatch(text);
    final name = match != null ? match.group(1)!.trim() : text;
    final dose = match?.group(2)?.trim() ?? '';
    final (scheduleLabel, times) = _parseSchedule(text.toLowerCase());
    return MedicationItem(
      id: 'med-$index',
      name: name.isNotEmpty ? name : 'Medication',
      dose: dose,
      schedule: scheduleLabel,
      times: times,
    );
  }

  /// Derives a cadence label and concrete 24h dose times from free-text such
  /// as "Metformin 500mg twice daily" or "Lisinopril 10mg at 8am".
  /// Pure + deterministic so it can be unit-tested.
  static (String, List<String>) _parseSchedule(String lower) {
    // 1) Explicit clock times — require a colon or am/pm so we never mistake
    //    a dose like "500 mg" for a time.
    final timeRe = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b');
    final explicit = <String>{};
    for (final m in timeRe.allMatches(lower)) {
      final hasMeridiem = m.group(3) != null;
      final hasColon = m.group(2) != null;
      if (!hasMeridiem && !hasColon) continue;
      var h = int.parse(m.group(1)!);
      final min = m.group(2) != null ? int.parse(m.group(2)!) : 0;
      final mer = m.group(3);
      if (mer == 'pm' && h < 12) h += 12;
      if (mer == 'am' && h == 12) h = 0;
      if (h > 23 || min > 59) continue;
      explicit.add(
        '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
      );
    }
    if (explicit.isNotEmpty) {
      final times = explicit.toList()..sort();
      return ('Daily at ${times.map(_prettyTime).join(', ')}', times);
    }

    // 2) Frequency keywords (English + common Rx shorthand).
    bool has(String pattern) => RegExp(pattern).hasMatch(lower);
    if (has(r'\b(qid|four times|4x|4 times)\b') || lower.contains('every 6 hour')) {
      return ('Four times daily', const ['08:00', '12:00', '16:00', '20:00']);
    }
    if (has(r'\b(tid|three times|3x|3 times|thrice)\b') ||
        lower.contains('every 8 hour')) {
      return ('Three times daily', const ['08:00', '14:00', '20:00']);
    }
    if (has(r'\b(bid|twice|2x|2 times|two times)\b') ||
        lower.contains('every 12 hour')) {
      return ('Twice daily', const ['09:00', '21:00']);
    }
    if (has(r'\b(bedtime|nightly|at night|evening|hs)\b')) {
      return ('Every evening', const ['21:00']);
    }
    if (has(r'\b(morning|every morning)\b')) {
      return ('Every morning', const ['08:00']);
    }
    if (has(r'\b(once|daily|qd|od|every day|per day|day)\b')) {
      return ('Once daily', const ['09:00']);
    }
    return ('As needed', const <String>[]);
  }

  static String _prettyTime(String hhmm) {
    final parts = hhmm.split(':');
    var h = int.parse(parts[0]);
    final m = parts[1];
    final mer = h >= 12 ? 'PM' : 'AM';
    if (h == 0) {
      h = 12;
    } else if (h > 12) {
      h -= 12;
    }
    return m == '00' ? '$h $mer' : '$h:$m $mer';
  }
}

List<HealthProfile> normalizeProfiles(dynamic raw) {
  if (raw is List) {
    return raw.whereType<Map<String, dynamic>>().map(HealthProfile.fromJson).toList();
  }
  if (raw is Map && raw['profiles'] is List) {
    return (raw['profiles'] as List)
        .whereType<Map<String, dynamic>>()
        .map(HealthProfile.fromJson)
        .toList();
  }
  return [];
}

String riskTone(String? level) {
  final l = (level ?? '').toLowerCase();
  if (['high', 'critical', 'severe'].contains(l)) return 'critical';
  if (['medium', 'moderate', 'elevated', 'caution'].contains(l)) return 'caution';
  return 'neutral';
}

String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
