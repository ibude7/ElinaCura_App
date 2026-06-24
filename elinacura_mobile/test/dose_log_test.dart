import 'package:flutter_test/flutter_test.dart';
import 'package:elinacura_mobile/core/health/dose_log.dart';
import 'package:elinacura_mobile/shared/models/models.dart';

void main() {
  final meds = [
    MedicationItem(id: 'm1', name: 'A', times: const ['09:00', '21:00']),
    MedicationItem(id: 'm2', name: 'B', times: const ['09:00']),
  ];

  group('computeAdherence', () {
    test('zero taken yields 0% with the correct scheduled count', () {
      final a = computeAdherence({}, meds, now: DateTime(2026, 6, 23));
      expect(a.todayScheduled, 3);
      expect(a.todayTaken, 0);
      expect(a.todayPercent, 0);
      expect(a.weekRatios.length, 7);
      expect(a.weekRatios.every((r) => r == 0), isTrue);
    });

    test('counts only slots that belong to the current medications', () {
      final now = DateTime(2026, 6, 23);
      final log = {
        dayKey(now): {
          doseSlotKey('m1', '09:00'),
          doseSlotKey('m2', '09:00'),
          'stale@00:00', // belongs to a removed med — must be ignored
        },
      };
      final a = computeAdherence(log, meds, now: now);
      expect(a.todayTaken, 2);
      expect(a.todayScheduled, 3);
      expect(a.weekRatios.last, closeTo(2 / 3, 0.001));
    });

    test('hasSchedule is false when no medication has fixed times', () {
      final a = computeAdherence({}, [MedicationItem(id: 'x', name: 'PRN')]);
      expect(a.hasSchedule, isFalse);
      expect(a.todayPercent, 0);
    });

    test('dayKey is zero-padded', () {
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('doseSlotKey combines id and time', () {
      expect(doseSlotKey('m1', '09:00'), 'm1@09:00');
    });
  });
}
