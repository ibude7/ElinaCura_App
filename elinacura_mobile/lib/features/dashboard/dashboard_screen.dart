import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/health/dose_log.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/health_overview_builder.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_sparkline.dart';
import '../../shared/widgets/ec_widgets.dart';
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

// ─────────────────────────────────────────────────────── Skeleton ──

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

// ─────────────────────────────────────────────────── No profile ──

class _DashboardOnboarding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final ec = EcColors.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, kEcNavBottomPadding),
      children: [
        _ClockSection(profile: null),
        const SizedBox(height: 28),
        EcGlassSurface(
          variant: EcGlassVariant.elevated,
          borderRadius: EcTokens.radiusGlass,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentBrand.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: ec.accentBrand,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Build your care profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add medications, conditions, allergies, and care preferences to unlock personalized daily intelligence.',
                style: TextStyle(
                  color: ec.textSecondary,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 22),
              EcGlassButton(
                label: 'Complete profile',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── Main content ──

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});

  final HealthOverview data;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(0, top, 0, kEcNavBottomPadding),
      children: [
        // ── Clock hero
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _ClockSection(profile: data.profile),
        ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 20),

        // ── Activity ring + stats (Google Health Today card)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ActivityRow(data: data),
        ).animate().fadeIn(delay: 60.ms, duration: 260.ms),

        const SizedBox(height: 20),

        // ── Medications rail
        if (data.medications.isNotEmpty) ...[
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
          _MedRail(medications: data.medications)
              .animate().fadeIn(delay: 100.ms, duration: 260.ms),
          const SizedBox(height: 20),
        ],

        // ── Care rhythm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _CareRhythm(medCount: data.medications.length),
        ).animate().fadeIn(delay: 140.ms, duration: 260.ms),

        // ── Real adherence chart
        if (data.medications.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const InsightsSection(),
          ).animate().fadeIn(delay: 160.ms, duration: 260.ms),
        ],

        const SizedBox(height: 20),

        // ── Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _QuickActions(),
        ).animate().fadeIn(delay: 180.ms, duration: 260.ms),

        // ── Conditions
        if (data.conditions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ConditionsCard(conditions: data.conditions),
          ).animate().fadeIn(delay: 200.ms, duration: 260.ms),
        ],
      ],
    );
  }
}

// ──────────────────────── Activity ring + stats row ──

class _ActivityRow extends ConsumerWidget {
  const _ActivityRow({required this.data});
  final HealthOverview data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final adherence = computeAdherence(log, data.medications);
    final ec = EcColors.of(context);

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          EcActivityRing(
            value: adherence.hasSchedule ? adherence.todayRatio : 0,
            label: adherence.hasSchedule ? 'Adherence' : 'Today',
            subLabel: adherence.hasSchedule
                ? '${adherence.todayTaken}/${adherence.todayScheduled} doses'
                : 'No schedule yet',
            color: EcTokens.categoryActivity,
            size: 110,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  icon: Icons.medication_rounded,
                  color: EcTokens.categoryNutrition,
                  label: 'Medications',
                  value: '${data.medications.length}',
                ),
                const SizedBox(height: 12),
                _StatRow(
                  icon: Icons.monitor_heart_rounded,
                  color: EcTokens.categoryHeart,
                  label: 'Conditions',
                  value: '${data.conditions.length}',
                ),
                const SizedBox(height: 12),
                _StatRow(
                  icon: Icons.task_alt_rounded,
                  color: adherence.todayRatio >= 0.8
                      ? EcTokens.statusPositive
                      : adherence.todayRatio >= 0.5
                          ? EcTokens.statusCaution
                          : ec.textMuted,
                  label: 'Adherence',
                  value: adherence.hasSchedule
                      ? '${adherence.todayPercent}%'
                      : '—',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: ec.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            fontFamily: EcTokens.fontFamily,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────── Clock section ──

class _ClockSection extends StatelessWidget {
  const _ClockSection({required this.profile});

  final HealthProfile? profile;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final name = profile?.name?.split(' ').first ?? 'there';
    final greeting = '${greetingForHour(hour)}, $name.';
    final date = _formatDate(DateTime.now());

    return EcClockHero(
      greeting: greeting,
      date: date,
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

// ─────────────────────────────────────────────────── Stat strip ──

// ─────────────────────────────────────────────────── Med rail ──

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

// ─────────────────────────────────────────────────── Care rhythm ──

class _CareRhythm extends StatelessWidget {
  const _CareRhythm({required this.medCount});

  final int medCount;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CARE RHYTHM',
                style: TextStyle(
                  color: ec.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontFamily: EcTokens.fontFamily,
                ),
              ),
              const Spacer(),
              EcPill(
                label: medCount == 0 ? 'Set up' : 'Today',
                tone: EcPillTone.info,
              ),
            ],
          ),
          const SizedBox(height: 18),
          EcTimelineNode(
            time: '08:00',
            label: medCount == 0
                ? 'Add your first medication'
                : 'Morning medications',
            done: medCount > 0,
          ),
          EcTimelineNode(
            time: '14:00',
            label: 'Scan new product labels',
            done: false,
          ),
          EcTimelineNode(
            time: '21:00',
            label: 'Evening check-in',
            done: false,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────── Quick actions ──

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EcSectionTitle(title: 'Quick actions'),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.document_scanner_rounded,
                label: 'Scan label',
                onTap: () => context.push('/ocr'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.alarm_rounded,
                label: 'Reminders',
                onTap: () => context.push('/reminders'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                icon: Icons.more_horiz_rounded,
                label: 'More',
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

// ─────────────────────────────────────────────────── Conditions ──

class _ConditionsCard extends StatelessWidget {
  const _ConditionsCard({required this.conditions});

  final List<ConditionItem> conditions;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcSectionTitle(title: 'Conditions'),
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
