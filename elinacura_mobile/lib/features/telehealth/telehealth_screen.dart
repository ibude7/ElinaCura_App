import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/engagement_repository.dart';
import '../../core/data/local_prefs.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

const _prepItems = [
  'Test camera and microphone',
  'Find a quiet, well-lit space',
  'Have medication list ready',
  'Note top 3 questions for clinician',
];

const _readinessChecks = [
  ('device', 'Device check passed'),
  ('connection', 'Stable connection'),
  ('privacy', 'Privacy mode on'),
];

class TelehealthScreen extends ConsumerStatefulWidget {
  const TelehealthScreen({super.key});

  @override
  ConsumerState<TelehealthScreen> createState() => _TelehealthScreenState();
}

class _TelehealthScreenState extends ConsumerState<TelehealthScreen> {
  Map<String, bool> _prepDone = {};
  Map<String, bool> _checks = {};
  List<TelehealthPartner> _partners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prep = await LocalPrefs.readBoolMap('ec.telehealth.prep');
    final checks = await LocalPrefs.readBoolMap('ec.telehealth.checks');
    try {
      final partners = await ref.read(engagementRepositoryProvider).getTelehealthPartners();
      if (mounted) {
        setState(() {
          _prepDone = prep;
          _checks = checks;
          _partners = partners;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _prepDone = prep;
          _checks = checks;
          _loading = false;
        });
      }
    }
  }

  Future<void> _togglePrep(int index) async {
    final key = 'p$index';
    setState(() => _prepDone = {..._prepDone, key: !(_prepDone[key] ?? false)});
    await LocalPrefs.writeBoolMap('ec.telehealth.prep', _prepDone);
  }

  Future<void> _runCheck(String key) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    setState(() => _checks = {..._checks, key: true});
    await LocalPrefs.writeBoolMap('ec.telehealth.checks', _checks);
  }

  int get _readiness {
    final prepTotal = _prepItems.length + _readinessChecks.length;
    final prepDone = _prepDone.values.where((v) => v).length +
        _checks.values.where((v) => v).length;
    return prepTotal == 0 ? 0 : ((prepDone / prepTotal) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Telehealth'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: kEcGlassListPadding,
              children: [
                EcEngagementHero(
                  title: 'Visit handoff',
                  subtitle: 'Prepare for your virtual appointment and share the right context.',
                  icon: Icons.video_call_rounded,
                  trailing: EcPill(
                    label: '$_readiness% ready',
                    tone: _readiness >= 100 ? EcPillTone.positive : EcPillTone.caution,
                  ),
                ),
                const SizedBox(height: 16),
                EcSectionTitle(title: 'Prep checklist'),
                const SizedBox(height: 8),
                ...List.generate(
                  _prepItems.length,
                  (i) => EcChecklistTile(
                    title: _prepItems[i],
                    done: _prepDone['p$i'] == true,
                    onChanged: (_) => _togglePrep(i),
                  ),
                ),
                const SizedBox(height: 20),
                EcSectionTitle(title: 'Readiness checks'),
                const SizedBox(height: 8),
                ..._readinessChecks.map(
                  (check) => EcGlassListTile(
                    icon: _checks[check.$1] == true
                        ? Icons.check_circle_rounded
                        : Icons.play_circle_outline_rounded,
                    title: check.$2,
                    onTap: _checks[check.$1] == true ? null : () => _runCheck(check.$1),
                  ),
                ),
                if (_partners.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  EcSectionTitle(title: 'Partners'),
                  const SizedBox(height: 8),
                  ..._partners.map(
                    (p) => EcGlassListTile(
                      icon: Icons.local_hospital_rounded,
                      title: p.name,
                      subtitle: p.description,
                      onTap: p.url == null
                          ? null
                          : () => launchUrl(Uri.parse(p.url!), mode: LaunchMode.externalApplication),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                EcShareActions(
                  text: [
                    'Telehealth handoff',
                    'Readiness: $_readiness%',
                    ..._prepItems.asMap().entries.where((e) => _prepDone['p${e.key}'] == true).map((e) => '✓ ${e.value}'),
                  ].join('\n'),
                ),
              ],
            ),
    );
  }
}
