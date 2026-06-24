import '../../core/health/dose_log.dart';
import '../../shared/models/models.dart';

/// Elina Rhythm Score — proprietary daily care readiness (0–100).
class RhythmScore {
  const RhythmScore({
    required this.score,
    required this.grade,
    required this.breakdown,
  });

  final int score;
  final String grade;
  final List<RhythmScoreFactor> breakdown;
}

class RhythmScoreFactor {
  const RhythmScoreFactor({
    required this.label,
    required this.points,
    required this.maxPoints,
  });

  final String label;
  final int points;
  final int maxPoints;

  double get ratio => maxPoints == 0 ? 0 : points / maxPoints;
}

RhythmScore computeRhythmScore({
  required AdherenceData adherence,
  required HealthProfile? profile,
  int vitalsLoggedToday = 0,
  int safetyFlags = 0,
}) {
  var adherencePts = 0;
  if (adherence.hasSchedule) {
    adherencePts = (adherence.todayRatio * 40).round();
  }

  var profilePts = 0;
  if (profile != null) {
    final checks = [
      profile.medications.isNotEmpty,
      profile.conditions.isNotEmpty,
      profile.allergies.isNotEmpty,
      (profile.bloodType?.isNotEmpty ?? false),
      profile.emergencyContacts.isNotEmpty,
      (profile.primaryGoal?.isNotEmpty ?? false),
    ];
    profilePts = ((checks.where((c) => c).length / checks.length) * 25).round();
  }

  final vitalsPts = vitalsLoggedToday > 0 ? 20 : (vitalsLoggedToday == 0 ? 5 : 0);
  final safetyPts = safetyFlags == 0 ? 15 : (15 - safetyFlags * 5).clamp(0, 15);

  final total = (adherencePts + profilePts + vitalsPts + safetyPts).clamp(0, 100);
  final grade = switch (total) {
    >= 90 => 'A',
    >= 75 => 'B',
    >= 60 => 'C',
    >= 45 => 'D',
    _ => '—',
  };

  return RhythmScore(
    score: total,
    grade: grade,
    breakdown: [
      RhythmScoreFactor(label: 'Adherence', points: adherencePts, maxPoints: 40),
      RhythmScoreFactor(label: 'Profile', points: profilePts, maxPoints: 25),
      RhythmScoreFactor(label: 'Vitals', points: vitalsPts, maxPoints: 20),
      RhythmScoreFactor(label: 'Safety', points: safetyPts, maxPoints: 15),
    ],
  );
}
