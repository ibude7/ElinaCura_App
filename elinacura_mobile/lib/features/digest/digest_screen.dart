import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/engagement_repository.dart';
import '../../core/design_system/ec_copy.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_outcome_hero.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_widgets.dart';

class DigestScreen extends ConsumerStatefulWidget {
  const DigestScreen({super.key});

  @override
  ConsumerState<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends ConsumerState<DigestScreen> {
  WeeklyDigest? _digest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileId = activeProfileId(ref);
    setState(() => _loading = true);
    if (profileId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final digest =
          await ref.read(engagementRepositoryProvider).getCurrentDigest(profileId);
      if (mounted) {
        setState(() {
          _digest = digest;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Weekly digest'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _digest == null
              ? EcEmptyState(
                  icon: Icons.newspaper_rounded,
                  title: 'No weekly digest yet',
                  message: EcCopy.emptyDigest,
                  action: FilledButton(
                    onPressed: () => context.push('/reminders'),
                    child: const Text('Start tracking'),
                  ),
                )
              : ListView(
                  padding: kEcGlassListPadding,
                  children: [
                    EcOutcomeHero(
                      eyebrow: 'Weekly outcome',
                      title: _digest!.periodLabel,
                      subtitle: _digest!.summary.isEmpty
                          ? 'Your weekly health rhythm at a glance.'
                          : _digest!.summary,
                      icon: Icons.insights_rounded,
                      accent: EcAccent.sky,
                      trailing: EcPill(
                        label: 'Score ${_digest!.score}',
                        tone: _digest!.score >= 70
                            ? EcPillTone.positive
                            : EcPillTone.caution,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_digest!.highlights.isNotEmpty) ...[
                      EcSectionTitle(title: 'Highlights'),
                      const SizedBox(height: 8),
                      ..._digest!.highlights.map(
                        (h) => EcGlassListTile(
                          icon: Icons.trending_up_rounded,
                          title: h,
                        ),
                      ),
                    ],
                    if (_digest!.attention.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      EcSectionTitle(title: 'Needs attention'),
                      const SizedBox(height: 8),
                      ..._digest!.attention.map(
                        (a) => EcGlassListTile(
                          icon: Icons.flag_rounded,
                          title: a,
                          iconColor: EcColors.of(context).accentAmberText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Share.share(_digest!.summary),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share digest'),
                    ),
                  ],
                ),
    );
  }
}
