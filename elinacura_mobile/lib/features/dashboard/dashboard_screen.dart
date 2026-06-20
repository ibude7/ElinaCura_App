import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
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
          if (!data.hasProfile) return _DashboardOnboarding(onContinue: () => context.push('/profile'));
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
    final ec = EcColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: EcTokens.radiusGlass,
            child: Column(
              children: [
                Icon(Icons.health_and_safety_rounded, size: 64, color: ec.accentBrand),
                const SizedBox(height: 24),
                Text(
                  'Set up your health profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add your conditions and medications to get personalized insights.',
                  style: TextStyle(color: ec.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          EcGlassButton(label: 'Complete profile', onPressed: onContinue),
        ],
      ),
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
        _HeroSection(greeting: '${greetingForHour(hour)}, $name', pillCount: data.medications.length)
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        _GlanceStrip(medCount: data.medications.length, conditionCount: data.conditions.length)
            .animate()
            .fadeIn(delay: 80.ms, duration: 280.ms)
            .slideY(begin: 0.06, end: 0),
        const SizedBox(height: 20),
        EcGlassEntrance(index: 2, child: const EcSectionTitle(title: 'Quick actions')),
        EcGlassEntrance(index: 3, child: _QuickActions()),
        const SizedBox(height: 20),
        if (data.medications.isNotEmpty)
          EcGlassEntrance(index: 4, child: _MedicationsCard(medications: data.medications)),
        if (data.conditions.isNotEmpty) ...[
          const SizedBox(height: 16),
          EcGlassEntrance(index: 5, child: _ConditionsCard(conditions: data.conditions)),
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
  const _HeroSection({required this.greeting, required this.pillCount});

  final String greeting;
  final int pillCount;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ec.accentBrand.withValues(alpha: 0.25),
                      ec.accentBrand.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: ec.accentBrand.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.wb_sunny_rounded, color: ec.accentBrand, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(color: ec.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '$pillCount medications today',
            style: TextStyle(color: ec.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
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
        Expanded(child: EcCard(child: EcStat(label: 'Meds', value: '$medCount'))),
        const SizedBox(width: 10),
        Expanded(child: EcCard(child: EcStat(label: 'Conditions', value: '$conditionCount'))),
        const SizedBox(width: 10),
        Expanded(child: EcCard(child: EcStat(label: 'Alerts', value: '0'))),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        EcGlassChip(icon: Icons.document_scanner_rounded, label: 'Scan', onTap: () => context.push('/ocr')),
        EcGlassChip(icon: Icons.alarm_rounded, label: 'Reminder', onTap: () => context.push('/reminders')),
        EcGlassChip(icon: Icons.monitor_heart_rounded, label: 'Vitals', onTap: () => context.push('/health')),
        EcGlassChip(
          icon: Icons.emergency_rounded,
          label: 'Emergency',
          tint: ec.textCritical,
          onTap: () => context.push('/emergency'),
        ),
      ],
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
          ...medications.take(5).map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ec.accentMintFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.medication_rounded, size: 20, color: ec.accentMintText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (m.dose.isNotEmpty)
                            Text(m.dose, style: TextStyle(color: ec.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
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
