import 'package:flutter_test/flutter_test.dart';
import 'package:elinacura_mobile/shared/models/models.dart';
import 'package:elinacura_mobile/shared/utils/health_overview_builder.dart';

void main() {
  group('HealthOverviewBuilder', () {
    test('returns hasProfile false for null profile', () {
      final overview = HealthOverviewBuilder.build(null);
      expect(overview.hasProfile, isFalse);
      expect(overview.medications, isEmpty);
    });

    test('parses medications and conditions', () {
      final profile = HealthProfile(
        id: 'p1',
        name: 'Test User',
        medications: ['Lisinopril 10mg', 'Metformin'],
        conditions: ['Hypertension'],
        primaryGoal: 'Lower BP',
        bloodType: 'O+',
      );
      final overview = HealthOverviewBuilder.build(profile);
      expect(overview.hasProfile, isTrue);
      expect(overview.medications.length, 2);
      expect(overview.medications.first.name, 'Lisinopril');
      expect(overview.medications.first.dose, '10mg');
      expect(overview.conditions.first.name, 'Hypertension');
      expect(overview.goals.first.label, 'Lower BP');
      expect(overview.keyVitals.first['value'], 'O+');
    });
  });

  group('riskTone', () {
    test('maps critical levels', () {
      expect(riskTone('critical'), 'critical');
      expect(riskTone('high'), 'critical');
    });

    test('maps caution levels', () {
      expect(riskTone('medium'), 'caution');
      expect(riskTone('elevated'), 'caution');
    });

    test('defaults to neutral', () {
      expect(riskTone('low'), 'neutral');
      expect(riskTone(null), 'neutral');
    });
  });

  group('greetingForHour', () {
    test('returns time-appropriate greeting', () {
      expect(greetingForHour(8), 'Good morning');
      expect(greetingForHour(14), 'Good afternoon');
      expect(greetingForHour(20), 'Good evening');
    });
  });
}
