import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/health/dose_log.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

/// Dashboard insights — real medication adherence derived from the local
/// dose log: a "today" ring plus a trailing 7-day trend. Hidden entirely
/// when the user has no scheduled medications (nothing real to show).
class InsightsSection extends ConsumerWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider).valueOrNull;
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final meds = overview?.medications ?? const [];
    final adherence = computeAdherence(log, meds);
    final ec = EcColors.of(context);

    if (!adherence.hasSchedule) return const SizedBox.shrink();

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EcSectionTitle(title: 'Adherence'),
          Row(
            children: [
              EcHealthRing(
                score: adherence.todayRatio,
                size: 92,
                label: 'Today',
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${adherence.todayTaken} of ${adherence.todayScheduled} '
                      'doses today',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last 7 days',
                      style: TextStyle(
                        color: ec.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 66,
                      child: _WeeklyAdherenceChart(
                        ratios: adherence.weekRatios,
                        barColor: ec.accentBrand,
                        trackColor: ec.textMuted.withValues(alpha: 0.14),
                        labelColor: ec.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyAdherenceChart extends StatelessWidget {
  const _WeeklyAdherenceChart({
    required this.ratios,
    required this.barColor,
    required this.trackColor,
    required this.labelColor,
  });

  final List<double> ratios;
  final Color barColor;
  final Color trackColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    String letterFor(int i) =>
        dayLetters[today.subtract(Duration(days: 6 - i)).weekday - 1];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: 1,
        minY: 0,
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i > 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    letterFor(i),
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: EcTokens.fontFamily,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < ratios.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: ratios[i] <= 0 ? 0.02 : ratios[i],
                  width: 9,
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 1,
                    color: trackColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
