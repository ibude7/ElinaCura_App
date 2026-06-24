import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/data/local_prefs.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

const _reportSections = [
  ('vitals', 'Vitals & trends'),
  ('medications', 'Medications'),
  ('conditions', 'Conditions'),
  ('adherence', 'Adherence'),
  ('appointments', 'Appointments'),
  ('notes', 'Clinical notes'),
];

const _ranges = {
  '7d': 'Last 7 days',
  '30d': 'Last 30 days',
  '90d': 'Last 90 days',
};

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  Map<String, bool> _sections = {
    for (final s in _reportSections) s.$1: s.$1 != 'appointments' && s.$1 != 'notes',
  };
  String _range = '30d';
  late final TextEditingController _recipientController;
  late final TextEditingController _coverController;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController();
    _coverController = TextEditingController();
    _loadPrefs();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _coverController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final saved = await LocalPrefs.readBoolMap('ec.report.sections');
    final range = await LocalPrefs.readString('ec.report.range');
    final recipient = await LocalPrefs.readString('ec.report.recipient');
    final note = await LocalPrefs.readString('ec.report.cover');
    final overview = ref.read(healthOverviewProvider).valueOrNull;
    if (!mounted) return;
    setState(() {
      if (saved.isNotEmpty) _sections = saved;
      if (range != null) _range = range;
      _recipientController.text = recipient ?? overview?.profile?.name ?? '';
      _coverController.text = note ?? '';
    });
  }

  Future<void> _persistSections() async {
    await LocalPrefs.writeBoolMap('ec.report.sections', _sections);
  }

  String _buildSummary() {
    final included = _reportSections.where((s) => _sections[s.$1] == true).map((s) => s.$2);
    final recipient = _recipientController.text.trim().isEmpty
        ? 'Your clinician'
        : _recipientController.text.trim();
    final buffer = StringBuffer()
      ..writeln('ElinaCura health report for $recipient')
      ..writeln('Range: ${_ranges[_range] ?? _range}')
      ..writeln('Sections: ${included.join(', ')}');
    final note = _coverController.text.trim();
    if (note.isNotEmpty) {
      buffer.writeln('\nNote:\n$note');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(healthOverviewProvider);
    final included = _sections.values.where((v) => v).length;
    final readiness = _reportSections.isEmpty
        ? 0
        : ((included / _reportSections.length) * 100).round();

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Health report'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcGlassEntrance(
            index: 0,
            child: EcEngagementHero(
              title: 'Share with your provider',
              subtitle:
                  'Assemble a concise report from your tracked vitals, medications, and adherence.',
              icon: Icons.description_rounded,
              trailing: EcPill(
                label: '$readiness% ready',
                tone: readiness >= 80 ? EcPillTone.positive : EcPillTone.info,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              EcStatChip(label: 'Sections', value: '$included', tone: EcPillTone.info),
              const SizedBox(width: 8),
              EcStatChip(
                label: 'Profile',
                value: overview.valueOrNull?.hasProfile == true ? 'Linked' : 'Setup',
                tone: overview.valueOrNull?.hasProfile == true
                    ? EcPillTone.positive
                    : EcPillTone.caution,
              ),
            ],
          ),
          const SizedBox(height: 20),
          EcSectionTitle(title: 'Time range'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _ranges.entries
                .map(
                  (e) => ChoiceChip(
                    label: Text(e.value),
                    selected: _range == e.key,
                    onSelected: (_) async {
                      setState(() => _range = e.key);
                      await LocalPrefs.writeString('ec.report.range', e.key);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          EcSectionTitle(title: 'Recipient'),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Clinician or caregiver name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            controller: _recipientController,
            onChanged: (v) => LocalPrefs.writeString('ec.report.recipient', v),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Cover note (optional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            maxLines: 3,
            controller: _coverController,
            onChanged: (v) {
              final trimmed = v.length > 280 ? v.substring(0, 280) : v;
              if (trimmed != v) {
                _coverController.value = TextEditingValue(
                  text: trimmed,
                  selection: TextSelection.collapsed(offset: trimmed.length),
                );
              }
              LocalPrefs.writeString('ec.report.cover', trimmed);
            },
          ),
          const SizedBox(height: 20),
          EcSectionTitle(title: 'Include sections'),
          const SizedBox(height: 8),
          ..._reportSections.map(
            (s) => EcGlassEntrance(
              index: 1,
              child: EcGlassListTile(
                icon: Icons.checklist_rounded,
                title: s.$2,
                trailing: Switch.adaptive(
                  value: _sections[s.$1] ?? false,
                  onChanged: (v) async {
                    setState(() => _sections = {..._sections, s.$1: v});
                    await _persistSections();
                  },
                ),
                onTap: () async {
                  setState(() => _sections = {..._sections, s.$1: !(_sections[s.$1] ?? false)});
                  await _persistSections();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          EcShareActions(text: _buildSummary()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
