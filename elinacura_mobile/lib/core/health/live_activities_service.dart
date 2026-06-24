import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/models.dart';
import '../auth/auth_providers.dart';
import '../notifications/notification_service.dart';

/// Live Activities / Dynamic Island dose countdown (Rec #42).
class LiveActivitiesService {
  LiveActivitiesService(this._notifications);

  final NotificationService _notifications;

  Future<void> showNextDoseCountdown({
    required String medName,
    required String timeLabel,
    required Duration until,
  }) async {
    // Uses local notification as cross-platform fallback until iOS Live Activities
    // native bridge is integrated.
    await _notifications.scheduleOneShot(
      id: 9001,
      title: 'Next dose: $medName',
      body: 'Due at $timeLabel',
      after: until,
    );
  }

  Future<void> clear() => _notifications.cancel(9001);
}

final liveActivitiesServiceProvider = Provider<LiveActivitiesService>(
  (ref) => LiveActivitiesService(ref.watch(notificationServiceProvider)),
);

/// Schedules lock-screen countdown for the next scheduled dose.
final nextDoseLiveActivityProvider = FutureProvider<void>((ref) async {
  final overview = ref.watch(healthOverviewProvider).valueOrNull;
  if (overview == null || overview.medications.isEmpty) return;

  MedicationItem? nextMed;
  String? nextTime;
  for (final m in overview.medications) {
    for (final t in m.times) {
      nextMed ??= m;
      nextTime ??= t;
    }
  }
  if (nextMed == null || nextTime == null) return;

  final parts = nextTime.split(':');
  if (parts.length < 2) return;
  final h = int.tryParse(parts[0]) ?? 0;
  final min = int.tryParse(parts[1]) ?? 0;
  final now = DateTime.now();
  var due = DateTime(now.year, now.month, now.day, h, min);
  if (due.isBefore(now)) due = due.add(const Duration(days: 1));

  await ref.read(liveActivitiesServiceProvider).showNextDoseCountdown(
        medName: nextMed.name,
        timeLabel: nextTime,
        until: due.difference(now),
      );
});
