import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/health/dose_log.dart';
import '../../core/health/care_rhythm.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/ec_ambient_ai.dart';
import '../../core/theme/ec_motion.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _ClockSection(profile: data.profile),
        ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 16),

        EcMotionEntrance(
          index: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DashboardGlanceSection(
              data: data,
              rhythmScore: rhythmScore,
              adherence: adherence,
            ),
          ),
        ),

        const SizedBox(height: 12),

        EcMotionEntrance(
          index: 2,
          child: DashboardSectionNav(controller: _scroll),
        ),

        const SizedBox(height: 16),

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

        const SizedBox(height: 20),

        EcMotionEntrance(
          index: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DashboardLiveRhythm(medications: data.medications),
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
                    color: EcTokens.categoryNutrition,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const DashboardVitalsDelta(),
          ),
        ),

        if (data.medications.isNotEmpty) ...[
          const SizedBox(height: 20),
          EcMotionEntrance(
            index: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const InsightsSection(),
            ),
          ),
        ],

        const SizedBox(height: 20),

        EcMotionEntrance(
          index: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const DashboardCareAiCard(),
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

        const SizedBox(height: 12),

        EcMotionEntrance(
          index: 9,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: EcAskElinaChip(
                contextHint: 'Help me plan today based on my rhythm score.',
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        EcMotionEntrance(
          index: 9,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _QuickActions(),
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

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EcSectionTitle(title: l10n.dashboardQuickActionsTitle),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.document_scanner_rounded,
                label: l10n.dashboardScanLabel,
                onTap: () => context.push('/ocr'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.alarm_rounded,
                label: l10n.dashboardReminders,
                onTap: () => context.push('/reminders'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.more_horiz_rounded,
                label: l10n.dashboardMore,
                onTap: () => context.push('/more'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = EcColors.of(context).accentBrand;

    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
