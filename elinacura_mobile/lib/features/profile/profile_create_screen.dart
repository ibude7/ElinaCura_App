import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

/// Health profile creation — required before dashboard unlocks.
class ProfileCreateScreen extends ConsumerStatefulWidget {
  const ProfileCreateScreen({super.key});

  @override
  ConsumerState<ProfileCreateScreen> createState() => _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends ConsumerState<ProfileCreateScreen> {
  final _name = TextEditingController();
  final _goal = TextEditingController();
  final _bloodType = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _conditions = <String>[];
  final _medications = <String>[];
  final _allergies = <String>[];
  bool _consent = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _bloodType.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.profileCreateNameRequired);
      return;
    }
    if (!_consent) {
      setState(() => _error = l10n.profileCreateConsentRequired);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final user = ref.read(firebaseAuthProvider).currentUser;
    EmergencyContact? contact;
    if (_emergencyName.text.trim().isNotEmpty) {
      contact = EmergencyContact(
        name: _emergencyName.text.trim(),
        phone: _emergencyPhone.text.trim().isEmpty
            ? null
            : _emergencyPhone.text.trim(),
      );
    }

    final profile = await ref.read(healthOverviewProvider.notifier).createProfile(
          name: name,
          primaryGoal: _goal.text.trim(),
          bloodType: _bloodType.text.trim(),
          conditions: _conditions,
          medications: _medications,
          allergies: _allergies,
          emergencyContact: contact,
          email: user?.email,
        );

    if (!mounted) return;
    if (profile == null) {
      setState(() {
        _saving = false;
        _error = l10n.profileCreateFailed;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.profileCreateSuccess)),
    );
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ec = EcColors.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return EcGlassScaffold(
      appBar: EcAppBar(
        title: l10n.profileCreateHeading,
        showEmergency: false,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, top + 8, 20, 32),
        children: [
          Text(
            l10n.profileCreateLead,
            style: TextStyle(
              color: ec.textSecondary,
              height: 1.5,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: l10n.profileCreateBasicsTitle,
            subtitle: l10n.profileCreateBasicsSub,
            fillColor: EcTokens.washActivity,
            tint: EcTokens.categoryActivity,
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.profileCreateName,
                    hintText: l10n.profileCreateNamePlaceholder,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goal,
                  decoration: InputDecoration(
                    labelText: l10n.profileCreatePrimaryGoal,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bloodType,
                  decoration: InputDecoration(
                    labelText: l10n.profileCreateBloodType,
                    hintText: l10n.profileCreateBloodTypePlaceholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.profileCreateHealthTitle,
            subtitle: l10n.profileCreateHealthSub,
            fillColor: EcTokens.washHeart,
            tint: EcTokens.categoryHeart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TagEditor(
                  label: l10n.profileCreateConditions,
                  placeholder: l10n.profileCreateConditionsPlaceholder,
                  tags: _conditions,
                  onChanged: (v) => setState(() => _conditions..clear()..addAll(v)),
                ),
                const SizedBox(height: 14),
                _TagEditor(
                  label: l10n.profileCreateMedications,
                  placeholder: l10n.profileCreateMedicationsPlaceholder,
                  tags: _medications,
                  onChanged: (v) => setState(() => _medications..clear()..addAll(v)),
                ),
                const SizedBox(height: 14),
                _TagEditor(
                  label: l10n.profileCreateAllergies,
                  placeholder: l10n.profileCreateAllergiesPlaceholder,
                  tags: _allergies,
                  onChanged: (v) => setState(() => _allergies..clear()..addAll(v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.profileCreateEmergencyTitle,
            subtitle: l10n.profileCreateEmergencySub,
            fillColor: EcTokens.washCaution,
            tint: EcTokens.statusCaution,
            child: Column(
              children: [
                TextField(
                  controller: _emergencyName,
                  decoration: InputDecoration(
                    labelText: l10n.profileCreateEmergencyName,
                    hintText: l10n.profileCreateEmergencyNamePlaceholder,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emergencyPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.profileCreateEmergencyPhone,
                    hintText: l10n.profileCreateEmergencyPhonePlaceholder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          EcGlassSurface(
            variant: EcGlassVariant.subtle,
            borderRadius: EcTokens.radiusCard,
            categoryFill: EcTokens.washRecovery,
            tint: EcTokens.categoryRecovery,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: Text(
                l10n.profileCreateConsent,
                style: TextStyle(fontSize: 13.5, color: ec.textSecondary, height: 1.4),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: ec.textCritical, fontSize: 13.5),
            ),
          ],
          const SizedBox(height: 24),
          EcGlassButton(
            label: l10n.profileCreateSubmit,
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.fillColor,
    this.tint,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color? fillColor;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusGlass,
      categoryFill: fillColor,
      tint: tint,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: ec.textSecondary, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TagEditor extends StatefulWidget {
  const _TagEditor({
    required this.label,
    required this.placeholder,
    required this.tags,
    required this.onChanged,
  });

  final String label;
  final String placeholder;
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final _input = TextEditingController();

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (widget.tags.any((t) => t.toLowerCase() == value.toLowerCase())) return;
    widget.onChanged([...widget.tags, value]);
    _input.clear();
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.placeholder,
                  isDense: true,
                ),
                onSubmitted: _add,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => _add(_input.text),
              icon: const Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags
                .map(
                  (t) => InputChip(
                    label: Text(t),
                    onDeleted: () => _remove(t),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
