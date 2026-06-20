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
      r'^(.*?)[\s,]+(\d[\d.]*\s?(?:mg|mcg|g|ml|iu|units?)\b.*)$',
      caseSensitive: false,
    ).firstMatch(text);
    final name = match != null ? match.group(1)!.trim() : text;
    final dose = match?.group(2)?.trim() ?? '';
    return MedicationItem(
      id: 'med-$index',
      name: name.isNotEmpty ? name : 'Medication',
      dose: dose,
    );
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
