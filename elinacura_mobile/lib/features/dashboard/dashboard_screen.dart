import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/health_overview_builder.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return EcTabPage(
      title: 'Home',
      body: overview.when(
        loading: () => const _DashboardSkeleton(),
        error: (e, _) => EcErrorState(
          message: formatApiError(e),
          onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
        ),
        data: (data) {
          if (!data.hasProfile) {
            return _DashboardOnboarding(
              onContinue: () => context.push('/profile'),
            );
          }
          if (!data.hasAnalytics) return _DashboardWelcome(data: data);
          return _DashboardFull(data: data);
        },
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: kEcGlassTabPadding,
      children: const [
        EcSkeleton(height: 140, radius: 28),
        SizedBox(height: 16),
        EcSkeleton(height: 88, radius: 28),
        SizedBox(height: 16),
        EcSkeleton(height: 220, radius: 28),
      ],
    );
  }
}

class _DashboardOnboarding extends StatelessWidget {
  const _DashboardOnboarding({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return EcEmptyState(
      icon: Icons.health_and_safety_rounded,
      title: 'Create your care profile',
      message:
          'Add medications, conditions, allergies, and care preferences so ElinaCura can personalize your daily safety view.',
      action: EcGlassButton(label: 'Complete profile', onPressed: onContinue),
    );
  }
}

class _DashboardWelcome extends StatelessWidget {
  const _DashboardWelcome({required this.data});

  final HealthOverview data;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final name = data.profile?.name ?? 'there';
    return ListView(
      padding: kEcGlassTabPadding,
      children: [
        _HeroSection(
              greeting: '${greetingForHour(hour)}, $name',
              pillCount: data.medications.length,
              conditionCount: data.conditions.length,
            )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        _GlanceStrip(
              medCount: data.medications.length,
              conditionCount: data.conditions.length,
            )
            .animate()
            .fadeIn(delay: 80.ms, duration: 280.ms)
            .slideY(begin: 0.06, end: 0),
        const SizedBox(height: 20),
        EcGlassEntrance(
          index: 2,
          child: _CareRhythmCard(medCount: data.medications.length),
        ),
        const SizedBox(height: 20),
        EcGlassEntrance(
          index: 3,
          child: const EcSectionTitle(title: 'Quick actions'),
        ),
        EcGlassEntrance(index: 4, child: _QuickActions()),
        const SizedBox(height: 20),
        if (data.medications.isNotEmpty)
          EcGlassEntrance(
            index: 5,
            child: _MedicationsCard(medications: data.medications),
          ),
        if (data.conditions.isNotEmpty) ...[
          const SizedBox(height: 16),
          EcGlassEntrance(
            index: 6,
            child: _ConditionsCard(conditions: data.conditions),
          ),
        ],
      ],
    );
  }
}

class _DashboardFull extends StatelessWidget {
  const _DashboardFull({required this.data});

  final HealthOverview data;

  @override
  Widget build(BuildContext context) => _DashboardWelcome(data: data);
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.greeting,
    required this.pillCount,
    required this.conditionCount,
  });

  final String greeting;
  final int pillCount;
  final int conditionCount;

  @override
  Widget build(BuildContext context) {
    return EcScreenHero(
      eyebrow: _formatDate(DateTime.now()),
      title: greeting,
      subtitle:
          '$pillCount medications and $conditionCount conditions are organized in today\'s care view.',
      icon: Icons.spa_rounded,
      trailing: EcPill(label: 'Today', tone: EcPillTone.positive),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _CareRhythmCard extends StatelessWidget {
  const _CareRhythmCard({required this.medCount});

  final int medCount;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcCard(
      elevated: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: ec.accentBrand.withValues(alpha: 0.14),
                ),
                child: Icon(
                  Icons.event_note_rounded,
                  color: ec.accentBrand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Today\'s care rhythm',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              EcPill(
                label: medCount == 0 ? 'Set up' : '$medCount meds',
                tone: EcPillTone.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RhythmStep(
            time: 'Morning',
            label: medCount == 0
                ? 'Add your first medication'
                : 'Review medications',
            done: medCount > 0,
          ),
          const SizedBox(height: 10),
          const _RhythmStep(
            time: 'Afternoon',
            label: 'Scan labels before new purchases',
            done: false,
          ),
          const SizedBox(height: 10),
          const _RhythmStep(
            time: 'Evening',
            label: 'Log a quick wellness note',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _RhythmStep extends StatelessWidget {
  const _RhythmStep({
    required this.time,
    required this.label,
    required this.done,
  });

  final String time;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Row(
      children: [
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: done ? ec.accentMintText : ec.textMuted,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            time,
            style: TextStyle(
              color: ec.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _GlanceStrip extends StatelessWidget {
  const _GlanceStrip({required this.medCount, required this.conditionCount});

  final int medCount;
  final int conditionCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EcMetricTile(
            label: 'Meds',
            value: '$medCount',
            icon: Icons.medication_rounded,
            tone: EcPillTone.positive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: EcMetricTile(
            label: 'Conditions',
            value: '$conditionCount',
            icon: Icons.monitor_heart_rounded,
            tone: EcPillTone.info,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: EcMetricTile(
            label: 'Alerts',
            value: '0',
            icon: Icons.shield_rounded,
            tone: EcPillTone.positive,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.75,
      children: [
        _ActionCard(
          icon: Icons.document_scanner_rounded,
          label: 'Scan label',
          onTap: () => context.push('/ocr'),
        ),
        _ActionCard(
          icon: Icons.alarm_rounded,
          label: 'Reminder',
          onTap: () => context.push('/reminders'),
        ),
        _ActionCard(
          icon: Icons.monitor_heart_rounded,
          label: 'Log vitals',
          onTap: () => context.push('/health'),
        ),
        _ActionCard(
          icon: Icons.emergency_rounded,
          label: 'Emergency',
          tint: ec.textCritical,
          onTap: () => context.push('/emergency'),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final color = tint ?? ec.accentBrand;
    return EcCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationsCard extends StatelessWidget {
  const _MedicationsCard({required this.medications});

  final List<MedicationItem> medications;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EcSectionTitle(title: 'Medications'),
          ...medications
              .take(5)
              .map(
                (m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ec.accentMintFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          size: 20,
                          color: ec.accentMintText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (m.dose.isNotEmpty)
                              Text(
                                m.dose,
                                style: TextStyle(
                                  color: ec.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
    return EcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EcSectionTitle(title: 'Conditions'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions.map((c) => EcPill(label: c.name)).toList(),
          ),
        ],
      ),
    );
  }
}
