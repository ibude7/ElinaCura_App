import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/engagement_repository.dart';
import '../../core/data/local_prefs.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/widgets/ec_engagement.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class _VoiceTurn {
  const _VoiceTurn({required this.question, required this.answer, this.intent});

  final String question;
  final String answer;
  final String? intent;
}

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final _controller = TextEditingController();
  bool _listening = false;
  bool _processing = false;
  bool _persistConsent = false;
  List<_VoiceTurn> _turns = [];

  static const _commands = [
    'Log my morning medication',
    'What should I eat for lunch?',
    'Remind me about my evening dose',
    'How am I doing this week?',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await LocalPrefs.readList('ec.voice.turns');
    final consent = await LocalPrefs.readString('ec.voice.consent');
    if (!mounted) return;
    setState(() {
      _turns = saved
          .map(
            (e) => _VoiceTurn(
              question: e['q'] as String? ?? '',
              answer: e['a'] as String? ?? '',
              intent: e['intent'] as String?,
            ),
          )
          .toList();
      _persistConsent = consent == 'true';
    });
  }

  Future<void> _persist() async {
    await LocalPrefs.writeList(
      'ec.voice.turns',
      _turns
          .map(
            (t) => {
              'q': t.question,
              'a': t.answer,
              if (t.intent != null) 'intent': t.intent,
            },
          )
          .toList(),
    );
  }

  Future<void> _resolve(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty || _processing) return;
    final profileId = activeProfileId(ref);

    setState(() {
      _processing = true;
      _listening = false;
    });

    String answer = _demoReply(text);
    String? intent;

    if (profileId != null) {
      try {
        final result = await ref.read(engagementRepositoryProvider).resolveVoiceIntent(
              profileId: profileId,
              transcript: text,
              persistConsent: _persistConsent,
            );
        answer = result.displayReply;
        intent = result.intent;
      } catch (_) {}
    }

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _turns = [..._turns, _VoiceTurn(question: text, answer: answer, intent: intent)];
      _processing = false;
    });
    await _persist();
  }

  String _demoReply(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('med')) {
      return 'I can help log medications. Open Reminders to confirm your schedule.';
    }
    if (lower.contains('eat') || lower.contains('meal')) {
      return 'Based on your profile, aim for balanced protein and low sodium today.';
    }
    return 'I heard you. Try asking about medications, meals, or your weekly digest.';
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);

    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Voice assistant'),
      body: ListView(
        padding: kEcGlassListPadding,
        children: [
          EcEngagementHero(
            title: 'Hands-free care',
            subtitle: 'Speak naturally to log doses, ask questions, or get guidance.',
            icon: Icons.mic_rounded,
            accent: ec.accentBrand,
          ),
          const SizedBox(height: 16),
          EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: 28,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_listening ? ec.accentBrand : ec.textMuted)
                        .withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 36,
                    color: _listening ? ec.accentBrand : ec.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _processing
                      ? 'Processing…'
                      : _listening
                          ? 'Listening…'
                          : 'Tap to simulate voice input',
                  style: TextStyle(color: ec.textSecondary),
                ),
                const SizedBox(height: 16),
                IconButton.filled(
                  onPressed: _processing
                      ? null
                      : () => setState(() => _listening = !_listening),
                  icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Type or paste a voice transcript…',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: _processing ? null : () => _resolve(_controller.text),
              ),
            ),
            onSubmitted: _processing ? null : _resolve,
          ),
          SwitchListTile(
            title: const Text('Save transcripts'),
            subtitle: const Text('Opt in to persist voice logs for quality tuning'),
            value: _persistConsent,
            onChanged: (v) async {
              setState(() => _persistConsent = v);
              await LocalPrefs.writeString('ec.voice.consent', v.toString());
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commands
                .map(
                  (c) => ActionChip(
                    label: Text(c),
                    onPressed: _processing ? null : () => _resolve(c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          EcSectionTitle(title: 'Transcript'),
          const SizedBox(height: 8),
          if (_turns.isEmpty)
            const EcEmptyState(
              icon: Icons.record_voice_over_outlined,
              title: 'No voice turns yet',
              message: 'Try a quick command above.',
            )
          else
            ..._turns.map(
              (turn) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: EcCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You', style: TextStyle(fontWeight: FontWeight.w700, color: ec.textMuted)),
                      Text(turn.question),
                      const SizedBox(height: 10),
                      Text('ElinaCura', style: TextStyle(fontWeight: FontWeight.w700, color: ec.accentBrand)),
                      Text(turn.answer),
                      if (turn.intent != null) ...[
                        const SizedBox(height: 8),
                        EcPill(label: turn.intent!, tone: EcPillTone.info),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
