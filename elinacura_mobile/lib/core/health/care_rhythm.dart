import '../../core/health/dose_log.dart';
import '../../shared/models/models.dart';

/// One item on the live care rhythm timeline for Today.
class CareRhythmItem {
  const CareRhythmItem({
    required this.time,
    required this.label,
    required this.done,
    this.slotKey,
    this.icon = 'medication',
  });

  final String time;
  final String label;
  final bool done;
  final String? slotKey;
  final String icon;
}

/// Builds today's care rhythm from medication schedules and the dose log.
List<CareRhythmItem> buildCareRhythm({
  required List<MedicationItem> medications,
  required Map<String, Set<String>> doseLog,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final todayKey = dayKey(today);
  final taken = doseLog[todayKey] ?? const <String>{};

  final scheduled = <CareRhythmItem>[];
  for (final med in medications) {
    if (med.times.isEmpty) {
      scheduled.add(
        CareRhythmItem(
          time: '—',
          label: med.name,
          done: false,
          icon: 'medication',
        ),
      );
      continue;
    }
    for (final t in med.times) {
      final slot = doseSlotKey(med.id, t);
      scheduled.add(
        CareRhythmItem(
          time: t,
          label: '${med.name}${med.dose.isNotEmpty ? ' · ${med.dose}' : ''}',
          done: taken.contains(slot),
          slotKey: slot,
          icon: 'medication',
        ),
      );
    }
  }

  scheduled.sort((a, b) => a.time.compareTo(b.time));

  if (scheduled.isEmpty) {
    return const [
      CareRhythmItem(
        time: '08:00',
        label: 'Add your first medication',
        done: false,
        icon: 'setup',
      ),
      CareRhythmItem(
        time: '14:00',
        label: 'Log vitals check-in',
        done: false,
        icon: 'vitals',
      ),
      CareRhythmItem(
        time: '21:00',
        label: 'Evening care review',
        done: false,
        icon: 'review',
      ),
    ];
  }

  // Pad with care checkpoints if sparse.
  final extras = <CareRhythmItem>[
    CareRhythmItem(
      time: '12:00',
      label: 'Midday vitals check',
      done: false,
      icon: 'vitals',
    ),
    CareRhythmItem(
      time: '21:00',
      label: 'Evening care review',
      done: false,
      icon: 'review',
    ),
  ];

  final merged = [...scheduled];
  for (final e in extras) {
    if (!merged.any((m) => m.time == e.time)) merged.add(e);
  }
  merged.sort((a, b) => a.time.compareTo(b.time));
  return merged.take(6).toList();
}

String? nextRhythmLabel(List<CareRhythmItem> items) {
  for (final item in items) {
    if (!item.done) return item.label;
  }
  return null;
}

String careStatusSubline({
  required List<CareRhythmItem> rhythm,
  required AdherenceData adherence,
  required int rhythmScore,
}) {
  final next = nextRhythmLabel(rhythm);
  if (next != null) {
    return 'Next: $next · Rhythm $rhythmScore';
  }
  if (adherence.hasSchedule) {
    return '${adherence.todayPercent}% adherence today · Rhythm $rhythmScore';
  }
  return 'Complete your profile to unlock live care rhythm';
}
