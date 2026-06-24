import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/data/engagement_repository.dart';
import '../../core/data/local_prefs.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

const _checklist = [
  ('pack', 'Pack medications in carry-on'),
  ('labels', 'Keep original prescription labels'),
  ('supply', 'Bring 3 extra days of supply'),
  ('letter', 'Carry clinician letter if needed'),
  ('timezone', 'Review timezone shift plan'),
  ('emergency', 'Save local pharmacy & hospital contacts'),
];

class TravelModeScreen extends ConsumerStatefulWidget {
  const TravelModeScreen({super.key});

  @override
  ConsumerState<TravelModeScreen> createState() => _TravelModeScreenState();
}

class _TravelModeScreenState extends ConsumerState<TravelModeScreen> {
  Map<String, bool> _done = {};
  Map<String, dynamic>? _plan;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await LocalPrefs.readBoolMap('ec.travel.checklist');
    if (mounted) setState(() => _done = saved);
    await _loadPlan();
  }

  Future<void> _loadPlan() async {
    final profileId = activeProfileId(ref);
    if (profileId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await ref.read(engagementRepositoryProvider).getTravelPlan(
            profileId: profileId,
            originTz: 'America/Toronto',
            destinationTz: 'America/New_York',
            days: 5,
          );
      if (mounted) {
        setState(() {
          _plan = plan;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = formatApiError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggle(String id) async {
    setState(() => _done = {..._done, id: !(_done[id] ?? false)});
    await LocalPrefs.writeBoolMap('ec.travel.checklist', _done);
  }

  @override
  Widget build(BuildContext context) {
    final completed = _checklist.where((c) => _done[c.$1] == true).length;
    final readiness = ((_checklist.isEmpty ? 0 : completed / _checklist.length) * 100).round();
    final offset = _plan?['offset_minutes']?.toString() ?? '—';

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Travel mode'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcEngagementHero(
            title: 'Trip preparation',
            subtitle: 'Medication supply, timezone shifts, and travel checklist.',
            icon: Icons.flight_takeoff_rounded,
            trailing: EcPill(
              label: '$readiness% ready',
              tone: readiness >= 100 ? EcPillTone.positive : EcPillTone.caution,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              EcStatChip(label: 'Checklist', value: '$completed/${_checklist.length}', tone: EcPillTone.info),
              const SizedBox(width: 8),
              EcStatChip(label: 'TZ shift', value: '$offset min', tone: EcPillTone.neutral),
            ],
          ),
          if (_loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            EcErrorState(message: _error!, onRetry: _loadPlan),
          ],
          if (_plan != null) ...[
            const SizedBox(height: 20),
            EcSectionTitle(title: 'Dose schedule shift'),
            const SizedBox(height: 8),
            EcCard(
              child: Text(
                'Advisory plan for ${_plan!['days'] ?? 5} days with max '
                '${_plan!['max_shift_hours_per_day'] ?? 2}h shift per day.',
                style: TextStyle(color: EcColors.of(context).textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 20),
          EcSectionTitle(title: 'Travel checklist'),
          const SizedBox(height: 8),
          ..._checklist.map(
            (item) => EcChecklistTile(
              title: item.$2,
              done: _done[item.$1] == true,
              onChanged: (_) => _toggle(item.$1),
            ),
          ),
          const SizedBox(height: 16),
          EcShareActions(
            text: _checklist
                .where((c) => _done[c.$1] != true)
                .map((c) => '• ${c.$2}')
                .join('\n'),
          ),
        ],
      ),
    );
  }
}
