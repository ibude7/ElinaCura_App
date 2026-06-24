import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/data/engagement_repository.dart';
import '../../core/data/local_prefs.dart';
import '../../core/design_system/ec_copy.dart';
import '../../core/design_system/ec_haptics.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_outcome_hero.dart';
import '../../shared/widgets/ec_page_kit.dart';
import '../../shared/widgets/ec_voice_waveform.dart';
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
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _processing = false;
  bool _persistConsent = false;
  bool _sttReady = false;
  double _soundLevel = 0.5;
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
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() => _sttReady = ok);
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
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

  Future<void> _toggleListen() async {
    if (_processing) return;
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    if (!_sttReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition unavailable on this device')),
      );
      return;
    }
    unawaited(EcHaptics.lightTap());
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        _controller.text = r.recognizedWords;
        if (r.finalResult) {
          unawaited(_resolve(r.recognizedWords));
        }
      },
      onSoundLevelChange: (l) {
        if (mounted) setState(() => _soundLevel = ((l + 50) / 50).clamp(0.1, 1.0));
      },
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
    await _speech.stop();

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
        if (result.intent == 'log_medication') {
          if (mounted) unawaited(context.push('/reminders'));
        } else if (result.intent == 'weekly_digest') {
          if (mounted) unawaited(context.push('/digest'));
        }
      } catch (_) {}
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    unawaited(EcHaptics.doseConfirmed());
    setState(() {
      _turns = [..._turns, _VoiceTurn(question: text, answer: answer, intent: intent)];
      _processing = false;
      _controller.clear();
    });
    await _persist();
  }

  String _demoReply(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('med')) {
      return 'Opening reminders so you can confirm your dose.';
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
          EcOutcomeHero(
            eyebrow: 'Hands-free',
            title: 'Voice care OS',
            subtitle: 'Speak naturally to log doses, ask questions, or get guidance.',
            icon: Icons.mic_rounded,
            accent: EcAccent.brand,
          ),
          const SizedBox(height: 16),
          EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: 28,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                EcVoiceWaveform(active: _listening, level: _soundLevel),
                const SizedBox(height: 12),
                Text(
                  _processing
                      ? 'Processing…'
                      : _listening
                          ? 'Listening…'
                          : _sttReady
                              ? 'Tap the mic and speak'
                              : 'Type a transcript below',
                  style: TextStyle(color: ec.textSecondary),
                ),
                const SizedBox(height: 16),
                IconButton.filled(
                  onPressed: _processing ? null : _toggleListen,
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
            EcEmptyState(
              icon: Icons.record_voice_over_outlined,
              title: 'No voice turns yet',
              message: EcCopy.noMeds,
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
