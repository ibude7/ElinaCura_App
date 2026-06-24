import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/health/dose_log.dart';
import '../../core/health/care_rhythm.dart';
import '../../core/health/rhythm_score.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/ec_ambient_ai.dart';
import '../../core/theme/ec_motion.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';
import '../../shared/widgets/ec_obsidian_kit.dart';
import '../../core/theme/ec_type.dart';
import '../../core/design_system/ec_haptics.dart';
import '../medications/medication_proof.dart';
import 'dashboard_sections.dart';
import 'insights_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return overview.when(
      loading: () => const _DashboardSkeleton(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EcErrorState(
            message: formatApiError(e),
            onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
          ),
        ),
      ),
      data: (data) {
        if (!data.hasProfile) return _DashboardOnboarding();
        return _DashboardContent(data: data);
      },
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: const [
        EcSkeleton(height: 160, radius: 0),
        SizedBox(height: 24),
        EcSkeleton(height: 88, radius: 22),
        SizedBox(height: 16),
        EcSkeleton(height: 180, radius: 28),
        SizedBox(height: 16),
        EcSkeleton(height: 200, radius: 28),
      ],
    );
  }
}

class _DashboardOnboarding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final ec = EcColors.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: [
        _ClockSection(profile: null),
        const SizedBox(height: 28),
        EcGlassSurface(
          variant: EcGlassVariant.float,
          borderRadius: EcTokens.radiusHero,
          categoryFill: EcTokens.washActivity,
          tint: EcTokens.categoryActivity,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EcTokens.categoryActivityLight,
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: EcTokens.categoryActivity,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dashboardOnboardingTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dashboardOnboardingLead,
                style: TextStyle(
                  color: ec.textSecondary,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 22),
              EcGlassButton(
                label: l10n.dashboardOnboardingCta,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push('/profile/create'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  const _DashboardContent({required this.data});

  final HealthOverview data;

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final rhythmScore = ref.watch(dashboardRhythmScoreProvider);
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final adherence = computeAdherence(log, data.medications);
    final rhythm = buildCareRhythm(medications: data.medications, doseLog: log);
    final top = MediaQuery.paddingOf(context).top;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) {
          ref.read(dashboardScrollOffsetProvider.notifier).state =
              n.metrics.pixels;
        }
        return false;
      },
      child: ListView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(0, top, 0, kEcNavBottomPadding),
        children: [
          // ── Hero: greeting + full-width adherence arc + % ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _AdherenceHero(
              profile: data.profile,
              adherence: adherence,
              rhythmScore: rhythmScore,
              rhythm: rhythm,
            ),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 18),

          // ── Stats: two frosted pill chips ──
          EcMotionEntrance(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StatsChips(
                meds: data.medications.length,
                conditions: data.conditions.length,
              ),
            ),
          ),

          const SizedBox(height: 26),

          // ── Care Rhythm: horizontal frosted rail ──
          EcMotionEntrance(
            index: 2,
            child: _CareRhythmRail(medications: data.medications),
          ),

          const SizedBox(height: 22),

          EcMotionEntrance(
            index: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DashboardRhythmScoreCard(
                rhythmScore: rhythmScore,
                adherence: adherence,
              ),
            ),
          ),

          if (data.medications.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EcSectionTitle(
                title: "Today's medications",
                action: TextButton(
                  onPressed: () => context.push('/reminders'),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: EcTokens.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            EcMotionEntrance(
              index: 5,
              child: _MedRail(medications: data.medications),
            ),
          ],

          const SizedBox(height: 20),

          EcMotionEntrance(
            index: 6,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: DashboardVitalsDelta(),
            ),
          ),

          if (data.medications.isNotEmpty) ...[
            const SizedBox(height: 20),
            EcMotionEntrance(
              index: 7,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: InsightsSection(),
              ),
            ),
          ],

          const SizedBox(height: 20),

          EcMotionEntrance(
            index: 8,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: DashboardCareAiCard(),
            ),
          ),

          const SizedBox(height: 12),

          EcMotionEntrance(
            index: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EcAmbientAiCard.bpTrend(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Quick actions: floating glass dock ──
          EcMotionEntrance(
            index: 9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const _QuickDock(),
            ),
          ),

          if (data.conditions.isNotEmpty) ...[
            const SizedBox(height: 20),
            EcMotionEntrance(
              index: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ConditionsCard(conditions: data.conditions),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClockSection extends ConsumerWidget {
  const _ClockSection({required this.profile});

  final HealthProfile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    final name = profile?.name?.split(' ').first ?? 'there';
    final greeting = l10n.dashboardGreetingNamed(hour, name);
    final date = _formatDate(DateTime.now());
    final overview = ref.watch(healthOverviewProvider).valueOrNull;
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final rhythm = buildCareRhythm(
      medications: overview?.medications ?? const [],
      doseLog: log,
    );
    final rhythmScore = ref.watch(dashboardRhythmScoreProvider);
    final adherence = computeAdherence(log, overview?.medications ?? const []);
    final subline = careStatusSubline(
      rhythm: rhythm,
      adherence: adherence,
      rhythmScore: rhythmScore.score,
    );
    final scroll = ref.watch(dashboardScrollOffsetProvider);
    final scale = (1.0 - (scroll / 400).clamp(0.0, 0.15));

    return EcClockHero(
      greeting: greeting,
      date: date,
      subline: subline,
      scale: scale,
      onEmergency: () => context.push('/emergency'),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _MedRail extends StatelessWidget {
  const _MedRail({required this.medications});

  final List<MedicationItem> medications;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
        itemCount: medications.length.clamp(0, 8),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = medications[i];
          return EcMedPillCard(
            name: m.name,
            dose: m.dose.isNotEmpty ? m.dose : '—',
            timeLabel: m.nextDue.isNotEmpty
                ? m.nextDue
                : (m.schedule.isNotEmpty ? m.schedule : '—'),
            onTap: () => context.push('/reminders'),
          );
        },
      ),
    );
  }
}

class _QuickDock extends StatelessWidget {
  const _QuickDock();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l10n.dashboardQuickActionsTitle.toUpperCase(),
            style: EcType.sectionLabel(color: EcTokens.accentGold),
          ),
        ),
        EcFloatingDock(
          actions: [
            EcDockAction(
              icon: Icons.document_scanner_rounded,
              label: l10n.dashboardScanLabel,
              onTap: () => context.push('/ocr'),
            ),
            EcDockAction(
              icon: Icons.alarm_rounded,
              label: l10n.dashboardReminders,
              onTap: () => context.push('/reminders'),
            ),
            EcDockAction(
              icon: Icons.auto_awesome_rounded,
              label: 'Care AI',
              onTap: () => context.push('/chat'),
            ),
            EcDockAction(
              icon: Icons.more_horiz_rounded,
              label: l10n.dashboardMore,
              onTap: () => context.push('/more'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────── Today hero ──

String _todayLabel(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

class _AdherenceHero extends StatelessWidget {
  const _AdherenceHero({
    required this.profile,
    required this.adherence,
    required this.rhythmScore,
    required this.rhythm,
  });

  final HealthProfile? profile;
  final AdherenceData adherence;
  final RhythmScore rhythmScore;
  final List<CareRhythmItem> rhythm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ec = EcColors.of(context);
    final hour = DateTime.now().hour;
    final name = profile?.name?.split(' ').first ?? 'there';
    final greeting = l10n.dashboardGreetingNamed(hour, name);
    final percent = adherence.hasSchedule ? adherence.todayPercent : 0;
    final subline = adherence.hasSchedule
        ? careStatusSubline(
            rhythm: rhythm,
            adherence: adherence,
            rhythmScore: rhythmScore.score,
          )
        : 'No schedule yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 3),
                  Text(
                    _todayLabel(DateTime.now()),
                    style: EcType.mono(color: ec.textMuted, size: 11),
                  ),
                ],
              ),
            ),
            const _EmergencyDot(),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 84,
          child: EcAdherenceArc(
            progress: percent / 100,
            horizon: true,
            strokeWidth: 12,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$percent%', style: EcType.hero(color: EcTokens.accentGold, size: 64)),
            const SizedBox(width: 12),
            if (adherence.hasSchedule)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${adherence.todayTaken}/${adherence.todayScheduled}\ndoses today',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: ec.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subline,
          style: TextStyle(fontSize: 13, color: ec.textMuted, height: 1.4),
        ),
      ],
    );
  }
}

class _EmergencyDot extends StatelessWidget {
  const _EmergencyDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency',
      child: GestureDetector(
        onTap: () {
          EcHaptics.safetyFlag();
          context.push('/emergency');
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EcTokens.statusCritical.withValues(alpha: 0.14),
            border: Border.all(
              color: EcTokens.statusCritical.withValues(alpha: 0.32),
              width: 0.8,
            ),
          ),
          child: const Icon(
            Icons.sos_rounded,
            color: EcTokens.statusCritical,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── Care rhythm rail ──

class _CareRhythmRail extends ConsumerStatefulWidget {
  const _CareRhythmRail({required this.medications});

  final List<MedicationItem> medications;

  @override
  ConsumerState<_CareRhythmRail> createState() => _CareRhythmRailState();
}

class _CareRhythmRailState extends ConsumerState<_CareRhythmRail> {
  final _ctrl = ScrollController();
  static const double _extent = 172; // 160 card + 12 gap

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final items = buildCareRhythm(medications: widget.medications, doseLog: log);
    final doneCount = items.where((i) => i.done).length;
    final currentIndex = items.indexWhere((i) => !i.done);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'CARE RHYTHM',
                style: EcType.sectionLabel(color: EcTokens.accentGold),
              ),
              const Spacer(),
              Text(
                '$doneCount/${items.length}',
                style: EcType.mono(color: ec.textSecondary, size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView.separated(
            controller: _ctrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              final card = _RhythmCard(
                item: item,
                isCurrent: i == currentIndex,
                onTap: item.slotKey != null
                    ? () async {
                        await EcHaptics.lightTap();
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
              // Subtle vertical parallax as the rail scrolls (±6dp).
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  final offset = _ctrl.hasClients ? _ctrl.position.pixels : 0.0;
                  final rel = (offset / _extent) - i;
                  final dy = 6 * math.sin(rel);
                  return Transform.translate(offset: Offset(0, dy), child: child);
                },
                child: card,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({
    required this.item,
    required this.isCurrent,
    this.onTap,
  });

  final CareRhythmItem item;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? EcTokens.textPrimaryDark : EcTokens.textPrimaryLight;

    Widget card = SizedBox(
      width: 160,
      height: 90,
      child: EcGlassSurface(
        onTap: onTap,
        variant: isCurrent ? EcGlassVariant.float : EcGlassVariant.regular,
        borderRadius: 18,
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item.time.toUpperCase(),
                  style: EcType.timeLabel(color: EcTokens.accentGold),
                ),
                const Spacer(),
                if (item.done)
                  const Icon(Icons.check_circle_rounded,
                      color: EcTokens.accentJade, size: 15),
              ],
            ),
            const Spacer(),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.15,
                letterSpacing: -0.2,
                color: item.done ? EcColors.of(context).textMuted : primary,
                decoration:
                    item.done ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: EcColors.of(context).textMuted,
              ),
            ),
          ],
        ),
      ),
    );

    if (isCurrent) {
      card = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: EcTokens.accentGold.withValues(alpha: 0.55),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: EcTokens.accentGold.withValues(alpha: 0.18),
              blurRadius: 22,
              spreadRadius: -4,
            ),
          ],
        ),
        child: card,
      );
      card = Transform.scale(scale: 1.05, child: card);
    }

    return card;
  }
}

class _StatsChips extends StatelessWidget {
  const _StatsChips({required this.meds, required this.conditions});

  final int meds;
  final int conditions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EcFrostedChip(
          emoji: '💊',
          label: '$meds ${meds == 1 ? 'med' : 'meds'}',
          onTap: () => context.push('/reminders'),
        ),
        const SizedBox(width: 10),
        EcFrostedChip(
          emoji: '🩺',
          label: '$conditions ${conditions == 1 ? 'condition' : 'conditions'}',
          onTap: () => context.push('/profile'),
        ),
      ],
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard({required this.conditions});

  final List<ConditionItem> conditions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcSectionTitle(title: l10n.dashboardConditionsTitle),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions
                .map((c) => EcPill(label: c.name, tone: EcPillTone.info))
                .toList(),
          ),
        ],
      ),
    );
  }
}
