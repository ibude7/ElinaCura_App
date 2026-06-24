import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/health/care_rhythm.dart';
import '../../core/health/dose_log.dart';
import '../../core/health/rhythm_score.dart';
import '../../core/health/vitals_store.dart';
import '../../core/theme/ec_motion.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_widgets.dart';
import '../medications/medication_proof.dart';

/// Today command-center sections — extracted for maintainability.
class DashboardGlanceSection extends ConsumerWidget {
  const DashboardGlanceSection({
    super.key,
    required this.data,
    required this.rhythmScore,
    required this.adherence,
  });

  final HealthOverview data;
  final RhythmScore rhythmScore;
  final AdherenceData adherence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EcGlanceStrip(
      items: [
        EcGlanceItem(
          label: 'Rhythm',
          value: '${rhythmScore.score}',
          icon: Icons.insights_rounded,
          color: EcTokens.categoryRecovery,
          fillColor: EcTokens.washRecovery,
          onTap: () => context.push('/digest'),
        ),
        EcGlanceItem(
          label: 'Adherence',
          value: adherence.hasSchedule ? '${adherence.todayPercent}%' : '—',
          icon: Icons.task_alt_rounded,
          color: EcTokens.categoryNutrition,
          fillColor: EcTokens.washNutrition,
          onTap: () => context.push('/reminders'),
        ),
        EcGlanceItem(
          label: 'Meds',
          value: '${data.medications.length}',
          icon: Icons.medication_rounded,
          color: EcTokens.categoryBreathing,
          fillColor: EcTokens.washBreathing,
          onTap: () => context.push('/reminders'),
        ),
        EcGlanceItem(
          label: 'Care AI',
          value: 'Ask',
          icon: Icons.auto_awesome_rounded,
          color: EcTokens.categorySleep,
          fillColor: EcTokens.washSleep,
          onTap: () => context.push('/chat'),
        ),
      ],
    );
  }
}

class DashboardRhythmScoreCard extends StatelessWidget {
  const DashboardRhythmScoreCard({
    super.key,
    required this.rhythmScore,
    required this.adherence,
  });

  final RhythmScore rhythmScore;
  final AdherenceData adherence;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      categoryFill: EcTokens.washRecovery,
      tint: EcTokens.categoryRecovery,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          EcRingProgress(
            value: rhythmScore.score / 100,
            label: 'Rhythm',
            size: 100,
            color: EcTokens.categoryRecovery,
            trackColor: EcTokens.categoryRecoveryLight,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elina Rhythm Score',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Grade ${rhythmScore.grade} · '
                  '${adherence.hasSchedule ? '${adherence.todayTaken}/${adherence.todayScheduled} doses today' : 'Set up medications'}',
                  style: TextStyle(
                    color: EcColors.of(context).textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ...rhythmScore.breakdown.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: EcColors.of(context).textMuted,
                            ),
                          ),
                        ),
                        Text(
                          '${f.points}/${f.maxPoints}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardLiveRhythm extends ConsumerWidget {
  const DashboardLiveRhythm({
    super.key,
    required this.medications,
  });

  final List<MedicationItem> medications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final items = buildCareRhythm(medications: medications, doseLog: log);
    final ec = EcColors.of(context);

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      categoryFill: EcTokens.washNutrition,
      tint: EcTokens.categoryNutrition,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LIVE CARE RHYTHM',
                style: TextStyle(
                  color: ec.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              EcPill(
                label: '${items.where((i) => i.done).length}/${items.length}',
                tone: EcPillTone.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            return EcTimelineNode(
              time: item.time,
              label: item.label,
              done: item.done,
              isLast: item == items.last,
              onTap: item.slotKey != null
                  ? () async {
                      await HapticFeedback.lightImpact();
                      if (!context.mounted) return;
                      await markDoseWithOptionalProof(
                        context: context,
                        ref: ref,
                        slotKey: item.slotKey!,
                        medName: item.label.split(' · ').first,
                        timeLabel: item.time,
                      );
                    }
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class DashboardCareAiCard extends StatelessWidget {
  const DashboardCareAiCard({super.key});

  @override
  Widget build(BuildContext context) {
    return EcPageHero(
      eyebrow: 'Care AI',
      title: 'Your co-pilot',
      subtitle: 'Ask about medications, meals, travel, or your weekly rhythm.',
      icon: Icons.auto_awesome_rounded,
      accent: EcAccent.lavender,
      trailing: IconButton.filled(
        onPressed: () => context.push('/chat'),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
    );
  }
}

class DashboardVitalsDelta extends ConsumerWidget {
  const DashboardVitalsDelta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitals = ref.watch(vitalsProvider).valueOrNull ?? const {};
    if (vitals.isEmpty) {
      return EcGlassListTile(
        icon: Icons.monitor_heart_outlined,
        title: 'Log vitals',
        subtitle: 'Track blood pressure, heart rate, and more',
        onTap: () => context.push('/health'),
      );
    }

    final latest = vitals.entries.take(3).toList();
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusCard,
      categoryFill: EcTokens.washHeart,
      tint: EcTokens.categoryHeart,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcSectionTitle(
            title: 'Vitals today',
            action: TextButton(
              onPressed: () => context.push('/health'),
              child: const Text('See all'),
            ),
          ),
          ...latest.map((e) {
            final type = e.key;
            final reading = e.value.isNotEmpty ? e.value.last : null;
            if (reading == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(type.icon, size: 18, color: type.color),
                  const SizedBox(width: 10),
                  Expanded(child: Text(type.label)),
                  Text(
                    '${reading.value} ${type.unit}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DashboardSectionNav extends StatelessWidget {
  const DashboardSectionNav({
    super.key,
    required this.controller,
  });

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final chips = ['Rhythm', 'Meds', 'Insights', 'Care AI'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return ActionChip(
            label: Text(chips[i]),
            onPressed: () {
              controller.animateTo(
                200.0 * (i + 1),
                duration: EcMotion.base,
                curve: EcMotion.emphasized,
              );
            },
          );
        },
      ),
    );
  }
}

/// Computes dashboard rhythm score from live providers.
final dashboardRhythmScoreProvider = Provider<RhythmScore>((ref) {
  final overview = ref.watch(healthOverviewProvider).valueOrNull;
  final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
  final meds = overview?.medications ?? const [];
  final adherence = computeAdherence(log, meds);
  final vitals = ref.watch(vitalsProvider).valueOrNull ?? const {};
  return computeRhythmScore(
    adherence: adherence,
    profile: overview?.profile,
    vitalsLoggedToday: vitals.length,
  );
});
