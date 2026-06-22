import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/ec_logo.dart';

// ════════════════════════════════════════════════════════════════════════
//  ElinaCura — Onboarding
//  A cinematic, editorial flow on a solid canvas. Each chapter is one
//  commanding, living health visual: a real-time ECG, activity rings, a
//  sleep hypnogram, a medication schedule, and an AI companion orb.
//  Driven by a single shared real-time clock so the whole thing breathes.
// ════════════════════════════════════════════════════════════════════════

class _Palette {
  const _Palette(this.dark);
  final bool dark;

  Color get bg => dark ? const Color(0xFF0A0B0F) : const Color(0xFFEDEAE2);
  Color get surface => dark ? const Color(0xFF14161C) : const Color(0xFFF7F5F0);
  Color get ink => dark ? const Color(0xFFF4F5F8) : const Color(0xFF14161C);
  Color get muted => dark ? const Color(0xFF8A90A0) : const Color(0xFF6C7178);
  Color get faint => dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07);
  Color get hairline => dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.10);
}

const _red = Color(0xFFFF4D45);
const _orange = Color(0xFFFF8A2B);
const _indigo = Color(0xFF6E6BFF);
const _green = Color(0xFF18C77E);
const _blue = Color(0xFF3E8BFF);
const _violet = Color(0xFF8B6FE8);

enum _Chapter { intro, vitals, fitness, sleep, meds, ai }

class _PageData {
  const _PageData({required this.kind, required this.eyebrow, required this.title, required this.subtitle, required this.cta, required this.accent});
  final _Chapter kind;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final Color accent;
}

const _pages = <_PageData>[
  _PageData(kind: _Chapter.intro, eyebrow: 'ELINACURA', title: 'The everything\nhealth app', subtitle: 'One intelligent companion for your whole body — vitals, movement, sleep and medication.', cta: 'Continue', accent: _violet),
  _PageData(kind: _Chapter.vitals, eyebrow: 'LIVE VITALS', title: 'Every heartbeat,\nunderstood', subtitle: 'Heart rate, oxygen and recovery, read in real time and explained in plain language.', cta: 'Continue', accent: _red),
  _PageData(kind: _Chapter.fitness, eyebrow: 'MOVEMENT', title: 'Progress you\ncan feel', subtitle: 'Close your rings, log every session, and watch your momentum compound.', cta: 'Continue', accent: _orange),
  _PageData(kind: _Chapter.sleep, eyebrow: 'SLEEP', title: 'Wake up\nknowing why', subtitle: 'Stages, efficiency and recovery, so every morning starts informed.', cta: 'Continue', accent: _indigo),
  _PageData(kind: _Chapter.meds, eyebrow: 'MEDICATION', title: 'Never miss\na dose', subtitle: 'Smart reminders, refill alerts and adherence you can actually keep.', cta: 'Continue', accent: _green),
  _PageData(kind: _Chapter.ai, eyebrow: 'AI COMPANION', title: 'Health that\nthinks ahead', subtitle: 'Everything you track, synthesized into clear guidance by a private intelligence.', cta: 'Create your account', accent: _blue),
];

// ════════════════════════════════════════════════════ Shared live clock ══
class _ClockScope extends InheritedWidget {
  const _ClockScope({required this.clock, required this.palette, required super.child});
  final ValueNotifier<double> clock;
  final _Palette palette;

  static ValueNotifier<double> clockOf(BuildContext c) => (c.getElementForInheritedWidgetOfExactType<_ClockScope>()!.widget as _ClockScope).clock;
  static _Palette paletteOf(BuildContext c) => (c.getElementForInheritedWidgetOfExactType<_ClockScope>()!.widget as _ClockScope).palette;

  @override
  bool updateShouldNotify(_ClockScope old) => old.clock != clock || old.palette.dark != palette.dark;
}

class _Live extends StatelessWidget {
  const _Live({required this.builder});
  final Widget Function(BuildContext context, double t) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(valueListenable: _ClockScope.clockOf(context), builder: (c, t, _) => builder(c, t));
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  static const _debugStart = int.fromEnvironment('OB_PAGE');
  final _pageController = PageController(initialPage: _debugStart);
  final _page = ValueNotifier<double>(_debugStart.toDouble());
  final _clock = ValueNotifier<double>(0);
  late final Ticker _ticker;
  int _index = _debugStart;
  int get _count => _pages.length;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() => _page.value = _pageController.page ?? _index.toDouble());
    _ticker = createTicker((e) => _clock.value = e.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pageController.dispose();
    _page.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _count - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(duration: const Duration(milliseconds: 560), curve: Curves.easeOutCubic);
    } else {
      HapticFeedback.mediumImpact();
      context.go('/auth');
    }
  }

  void _skip() {
    HapticFeedback.selectionClick();
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette(Theme.of(context).brightness == Brightness.dark);
    return _ClockScope(
      clock: _clock,
      palette: palette,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: IgnorePointer(child: _Grain())),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(page: _page, count: _count, onSkip: _skip, showSkip: _index < _count - 1),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _count,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        setState(() => _index = i);
                      },
                      itemBuilder: (context, i) => _ChapterView(page: _page, index: i, data: _pages[i]),
                    ),
                  ),
                  _BottomChrome(page: _page, count: _count, label: _pages[_index].cta, accent: _pages[_index].accent, onPrimary: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── Grain ──
class _Grain extends StatelessWidget {
  const _Grain();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return RepaintBoundary(child: CustomPaint(painter: _GrainPainter(dark: p.dark)));
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final n = (size.width * size.height / 900).clamp(400, 4000).toInt();
    final paint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: dark ? 0.022 : 0.02);
    final pts = <Offset>[for (var i = 0; i < n; i++) Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height)];
    canvas.drawPoints(PointMode.points, pts, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.dark != dark;
}

// ──────────────────────────────────────────────────────────── Top bar ──
class _TopBar extends StatelessWidget {
  const _TopBar({required this.page, required this.count, required this.onSkip, required this.showSkip});
  final ValueNotifier<double> page;
  final int count;
  final VoidCallback onSkip;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 14, 6),
      child: Row(children: [
        Opacity(opacity: p.dark ? 0.95 : 0.9, child: const EcLogo(size: 24)),
        const SizedBox(width: 9),
        Text('ElinaCura', style: TextStyle(color: p.ink, fontWeight: FontWeight.w800, fontSize: 15.5, letterSpacing: -0.3)),
        const Spacer(),
        ValueListenableBuilder<double>(
          valueListenable: page,
          builder: (c, v, _) => Text('${(v.round() + 1).toString().padLeft(2, '0')} / ${count.toString().padLeft(2, '0')}', style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 1, fontFeatures: const [FontFeature.tabularFigures()])),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: showSkip ? 1 : 0,
          child: TextButton(
            onPressed: showSkip ? onSkip : null,
            style: TextButton.styleFrom(foregroundColor: p.muted, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 36)),
            child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────── Chapter view ──
class _ChapterView extends StatelessWidget {
  const _ChapterView({required this.page, required this.index, required this.data});
  final ValueNotifier<double> page;
  final int index;
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return AnimatedBuilder(
      animation: page,
      builder: (context, _) {
        final delta = page.value - index;
        final focus = (1 - delta.abs()).clamp(0.0, 1.0);
        final eased = Curves.easeOut.transform(focus);
        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 4, 26, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _HeroGlow(color: data.accent, opacity: eased),
                    Opacity(
                      opacity: eased,
                      child: Transform.translate(
                        offset: Offset(delta * -36, 0),
                        child: Transform.scale(
                          scale: 0.92 + 0.08 * eased,
                          child: Center(child: _Hero(kind: data.kind, accent: data.accent)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _revealText(focus, delta, 0, Row(children: [
                Container(width: 18, height: 2, color: data.accent),
                const SizedBox(width: 9),
                Text(data.eyebrow, style: TextStyle(color: data.accent, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.6)),
              ])),
              const SizedBox(height: 14),
              _revealText(focus, delta, 1, Text(data.title, style: TextStyle(color: p.ink, fontSize: 40, height: 1.02, fontWeight: FontWeight.w800, letterSpacing: -1.6))),
              const SizedBox(height: 12),
              _revealText(focus, delta, 2, Text(data.subtitle, style: TextStyle(color: p.muted, fontSize: 15.5, height: 1.42, fontWeight: FontWeight.w500))),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _revealText(double focus, double delta, int order, Widget child) {
    final start = order * 0.1;
    final t = ((focus - start) / (1 - start)).clamp(0.0, 1.0);
    final e = Curves.easeOutCubic.transform(t);
    return Opacity(opacity: e, child: Transform.translate(offset: Offset(0, (1 - e) * 22), child: child));
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.kind, required this.accent});
  final _Chapter kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hero = switch (kind) {
      _Chapter.intro => const _IntroHero(),
      _Chapter.vitals => const _VitalsHero(),
      _Chapter.fitness => const _FitnessHero(),
      _Chapter.sleep => const _SleepHero(),
      _Chapter.meds => const _MedsHero(),
      _Chapter.ai => const _AiHero(),
    };
    return FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: 360, height: 400, child: hero));
  }
}

/// Localized accent light behind the hero — lets each chapter's colour bathe
/// the screen without ever touching the solid background.
class _HeroGlow extends StatelessWidget {
  const _HeroGlow({required this.color, required this.opacity});
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return IgnorePointer(
      child: _Live(builder: (c, t) {
        final breathe = 0.9 + 0.1 * math.sin(t * 0.7);
        final a = ((p.dark ? 0.22 : 0.13) * opacity * breathe).clamp(0.0, 1.0);
        return Center(
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withValues(alpha: a), color.withValues(alpha: 0)]),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════ Intro ══
class _IntroHero extends StatelessWidget {
  const _IntroHero();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // streaming signal line crossing the brand
          SizedBox(
            width: 360,
            height: 120,
            child: _Live(builder: (c, t) => CustomPaint(painter: _EcgPainter(phase: t * 1.1, color: _violet, dark: p.dark, grid: false, glow: true))),
          ),
          const _PulseRing(delayMs: 0, color: _violet),
          const _PulseRing(delayMs: 1500, color: _violet),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.surface,
              border: Border.all(color: p.hairline, width: 1.5),
              boxShadow: [BoxShadow(color: _violet.withValues(alpha: p.dark ? 0.3 : 0.18), blurRadius: 40, spreadRadius: -6)],
            ),
            alignment: Alignment.center,
            child: const EcLogo(size: 84),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.035, duration: 3400.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.delayMs, required this.color});
  final int delayMs;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5)),
    ).animate(onPlay: (c) => c.repeat()).scaleXY(begin: 0.85, end: 2.2, duration: 3200.ms, delay: delayMs.ms, curve: Curves.easeOut).fadeOut(duration: 3200.ms, delay: delayMs.ms, curve: Curves.easeOut);
  }
}

// ═══════════════════════════════════════════════════════════ Vitals ══
class _VitalsHero extends StatelessWidget {
  const _VitalsHero();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Live(builder: (c, t) {
          final bpm = (72 + 2.6 * math.sin(t * 0.9) + 1.2 * math.sin(t * 2.3)).round();
          return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(Icons.favorite_rounded, color: _red, size: 30).animate(onPlay: (a) => a.repeat()).scaleXY(begin: 1, end: 1.18, duration: 160.ms, curve: Curves.easeOut).then().scaleXY(begin: 1.18, end: 1, duration: 260.ms).then().scaleXY(begin: 1, end: 1, duration: 700.ms),
            const SizedBox(width: 14),
            Text('$bpm', style: TextStyle(color: p.ink, fontSize: 92, height: 0.9, fontWeight: FontWeight.w800, letterSpacing: -4, fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const _LiveTag(color: _red),
                const SizedBox(height: 2),
                Text('BPM', style: TextStyle(color: p.muted, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ]),
            ),
          ]);
        }),
        const SizedBox(height: 10),
        SizedBox(width: 360, height: 150, child: _Live(builder: (c, t) => CustomPaint(painter: _EcgPainter(phase: t * 1.2, color: _red, dark: p.dark, grid: true, glow: true)))),
        const SizedBox(height: 22),
        Row(children: [
          const _BigStat(label: 'BLOOD O₂', base: 98, jitter: 1, unit: '%', color: _red, speed: 0.8),
          _divider(p),
          const _BigStat(label: 'HRV', base: 64, jitter: 4, unit: ' ms', color: _red, speed: 0.5),
          _divider(p),
          _BigStatStatic(label: 'RECOVERY', value: 'High', p: p),
        ]),
      ],
    );
  }

  Widget _divider(_Palette p) => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 16), color: p.hairline);
}

class _LiveTag extends StatelessWidget {
  const _LiveTag({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1, duration: 720.ms),
      const SizedBox(width: 5),
      Text('LIVE', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
    ]);
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.base, required this.jitter, required this.unit, required this.color, required this.speed});
  final String label;
  final int base;
  final int jitter;
  final String unit;
  final Color color;
  final double speed;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        _Live(builder: (c, t) {
          final v = base + (jitter * math.sin(t * speed)).round();
          return Text('$v$unit', style: TextStyle(color: p.ink, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, fontFeatures: const [FontFeature.tabularFigures()]));
        }),
      ]),
    );
  }
}

class _BigStatStatic extends StatelessWidget {
  const _BigStatStatic({required this.label, required this.value, required this.p});
  final String label;
  final String value;
  final _Palette p;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: p.ink, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════ Fitness ══
class _FitnessHero extends StatelessWidget {
  const _FitnessHero();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 234,
          height: 234,
          child: _Live(builder: (c, t) {
            final breathe = 1 + 0.015 * math.sin(t * 1.4);
            return Transform.scale(
              scale: breathe,
              child: CustomPaint(
                painter: _RingsPainter(values: const [0.86, 0.72, 1.0], colors: const [_red, _green, _blue], dark: p.dark),
                child: Center(
                  child: _Live(builder: (c, t) {
                    final kcal = 412 + (t * 0.8).floor();
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$kcal', style: TextStyle(color: p.ink, fontSize: 40, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.5, fontFeatures: const [FontFeature.tabularFigures()])),
                      Text('KCAL', style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    ]);
                  }),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 26),
        Row(children: [
          _ringLegend(p, _red, 'Move', '420'),
          _ringLegend(p, _green, 'Exercise', '38m'),
          _ringLegend(p, _blue, 'Stand', '12h'),
        ]),
      ],
    );
  }

  Widget _ringLegend(_Palette p, Color color, String label, String value) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w700))]),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: p.ink, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════ Sleep ══
class _SleepHero extends StatelessWidget {
  const _SleepHero();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('7', style: TextStyle(color: p.ink, fontSize: 88, height: 0.9, fontWeight: FontWeight.w800, letterSpacing: -4)),
                Padding(padding: const EdgeInsets.only(top: 16, left: 2), child: Text('h', style: TextStyle(color: p.muted, fontSize: 30, fontWeight: FontWeight.w700))),
                const SizedBox(width: 10),
                Text('32', style: TextStyle(color: p.ink, fontSize: 88, height: 0.9, fontWeight: FontWeight.w800, letterSpacing: -4)),
                Padding(padding: const EdgeInsets.only(top: 16, left: 2), child: Text('m', style: TextStyle(color: p.muted, fontSize: 30, fontWeight: FontWeight.w700))),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _Live(builder: (c, t) => Transform.scale(scale: 1 + 0.07 * math.sin(t * 0.7), child: Icon(Icons.nightlight_round, color: _indigo, size: 40))),
          ),
        ]),
        const SizedBox(height: 18),
        SizedBox(width: 360, height: 132, child: _Live(builder: (c, t) => CustomPaint(painter: _HypnogramPainter(head: (t * 0.06) % 1.0, color: _indigo, dark: p.dark)))),
        const SizedBox(height: 18),
        Row(children: [
          _sleepStat(p, 'DEEP', '1h 21m'),
          _divider(p),
          _sleepStat(p, 'REM', '1h 05m'),
          _divider(p),
          _sleepStat(p, 'EFFICIENCY', '92%'),
        ]),
      ],
    );
  }

  Widget _divider(_Palette p) => Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 16), color: p.hairline);

  Widget _sleepStat(_Palette p, String label, String value) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════ Meds ══
class _MedsHero extends StatelessWidget {
  const _MedsHero();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          SizedBox(width: 96, height: 96, child: CustomPaint(painter: _RingPainter(value: 0.98, color: _green, stroke: 9, track: p.faint), child: Center(child: Text('98%', style: TextStyle(color: p.ink, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.5))))),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('On-time this week', style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [const _LiveTag(color: _green), const SizedBox(width: 8), Text('Next in', style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w600))]),
              _Live(builder: (c, t) {
                final r = (16338 - t).floor().clamp(0, 1 << 31);
                final h = r ~/ 3600, m = (r % 3600) ~/ 60, s = r % 60;
                return Text('$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}', style: TextStyle(color: p.ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()]));
              }),
            ]),
          ),
        ]),
        const SizedBox(height: 22),
        _dose(p, 'Metformin', '500 mg · 8:00 AM', _violet, true),
        _doseDivider(p),
        _dose(p, 'Vitamin D', '1000 IU · 9:00 AM', _orange, true),
        _doseDivider(p),
        _dose(p, 'Omega-3', '1 softgel · 1:00 PM', _blue, false),
      ],
    );
  }

  Widget _doseDivider(_Palette p) => Container(height: 1, color: p.hairline, margin: const EdgeInsets.symmetric(vertical: 12));

  Widget _dose(_Palette p, String name, String detail, Color color, bool done) {
    return Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11)), child: Icon(Icons.medication_rounded, color: color, size: 18)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: TextStyle(color: p.ink, fontSize: 15.5, fontWeight: FontWeight.w700)),
          Text(detail, style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w500)),
        ]),
      ),
      Container(
        width: 26, height: 26,
        decoration: BoxDecoration(shape: BoxShape.circle, color: done ? _green : Colors.transparent, border: Border.all(color: done ? _green : p.muted.withValues(alpha: 0.5), width: 2)),
        child: Icon(Icons.check_rounded, size: 15, color: done ? Colors.white : Colors.transparent),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════ AI ══
class _AiHero extends StatelessWidget {
  const _AiHero();
  static const _domains = <(IconData, Color)>[
    (Icons.favorite_rounded, _red),
    (Icons.directions_run_rounded, _orange),
    (Icons.nightlight_round, _indigo),
    (Icons.medication_rounded, _green),
  ];

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    final dots = [for (final e in _domains) _DomainDot(icon: e.$1, color: e.$2, surface: p.surface, hairline: p.hairline)];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: _Live(builder: (c, t) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(size: const Size(300, 300), painter: _OrbPainter(t: t, color: _blue, dark: p.dark)),
                  for (var i = 0; i < dots.length; i++)
                    Transform.translate(
                      offset: Offset.fromDirection(-math.pi / 2 + i * (2 * math.pi / dots.length) + t * 0.25, 124),
                      child: dots[i],
                    ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_blue, _blue.withValues(alpha: 0.0)], stops: const [0.2, 1.0])),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surface,
                      border: Border.all(color: _blue.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: -2)],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.auto_awesome_rounded, color: _blue, size: 28),
                  ).animate(onPlay: (a) => a.repeat(reverse: true)).scaleXY(begin: 1, end: 1.08, duration: 1800.ms, curve: Curves.easeInOut),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          const _AiInsight(),
        ],
      ),
    );
  }
}

class _AiInsight extends StatelessWidget {
  const _AiInsight();
  static const _items = [
    'Analyzing recovery…',
    'Sleep debt: low',
    'Hydration on track',
    'HRV trending up',
    'Primed for a hard day',
  ];

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return _Live(builder: (c, t) {
      final i = (t / 2.6).floor() % _items.length;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(anim), child: child),
        ),
        child: Container(
          key: ValueKey(i),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: p.hairline)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Text(_items[i], style: TextStyle(color: p.ink, fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
            ],
          ),
        ),
      );
    });
  }
}

class _DomainDot extends StatelessWidget {
  const _DomainDot({required this.icon, required this.color, required this.surface, required this.hairline});
  final IconData icon;
  final Color color;
  final Color surface;
  final Color hairline;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(shape: BoxShape.circle, color: surface, border: Border.all(color: hairline, width: 1)),
      child: Icon(icon, color: color, size: 20),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.9, end: 1.08, duration: 2200.ms, curve: Curves.easeInOut);
  }
}

// ──────────────────────────────────────────────────────── Bottom chrome ──
class _BottomChrome extends StatefulWidget {
  const _BottomChrome({required this.page, required this.count, required this.label, required this.accent, required this.onPrimary});
  final ValueNotifier<double> page;
  final int count;
  final String label;
  final Color accent;
  final VoidCallback onPrimary;

  @override
  State<_BottomChrome> createState() => _BottomChromeState();
}

class _BottomChromeState extends State<_BottomChrome> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    final btnColor = p.dark ? Colors.white : const Color(0xFF14161C);
    final btnText = p.dark ? const Color(0xFF0A0B0F) : Colors.white;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 6, 26, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Progress(page: widget.page, count: widget.count, accent: widget.accent),
          const SizedBox(height: 18),
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onPrimary,
            child: AnimatedScale(
              scale: _pressed ? 0.975 : 1,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.dark ? 0.3 : 0.18), blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 12))],
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(widget.label, key: ValueKey(widget.label), style: TextStyle(color: btnText, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, color: btnText, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.page, required this.count, required this.accent});
  final ValueNotifier<double> page;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return ValueListenableBuilder<double>(
      valueListenable: page,
      builder: (context, v, _) {
        final segs = <Widget>[];
        for (var i = 0; i < count; i++) {
          if (i > 0) segs.add(const SizedBox(width: 6));
          final frac = (v + 1 - i).clamp(0.0, 1.0);
          segs.add(Expanded(
            child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: Color.lerp(p.faint, accent, frac),
              ),
            ),
          ));
        }
        return Row(children: segs);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════ Painters ══
class _EcgPainter extends CustomPainter {
  const _EcgPainter({required this.phase, required this.color, required this.dark, this.grid = false, this.glow = false});
  final double phase;
  final Color color;
  final bool dark;
  final bool grid;
  final bool glow;

  double _wave(double f) {
    double g(double c, double w, double a) {
      final d = f - c;
      return a * math.exp(-(d * d) / (2 * w * w));
    }
    return g(0.10, 0.020, 0.16) - g(0.205, 0.012, 0.26) + g(0.235, 0.010, 1.0) - g(0.27, 0.014, 0.34) + g(0.43, 0.052, 0.30);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (grid) {
      final gp = Paint()
        ..color = (dark ? Colors.white : Colors.black).withValues(alpha: dark ? 0.05 : 0.045)
        ..strokeWidth = 1;
      for (var i = 1; i < 4; i++) {
        final y = size.height * i / 4;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
      }
      // vertical monitor lines scrolling with the trace
      final vspace = size.width / 7;
      final off = (phase * vspace * 1.8) % vspace;
      for (var x = size.width - off; x >= 0; x -= vspace) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gp);
      }
    }
    const beats = 2.6;
    final mid = size.height * 0.6;
    final amp = size.height * 0.46;
    final pts = <Offset>[];
    for (double x = 0; x <= size.width; x += 1.4) {
      final f = (((x / size.width) * beats) + phase) % 1.0;
      pts.add(Offset(x, mid - _wave(f) * amp));
    }
    if (pts.length < 2) return;
    final path = Path()..addPolygon(pts, false);
    if (glow) {
      canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = color.withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    }
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = color);
    final tip = pts.last;
    canvas.drawCircle(tip, 8, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(tip, 3.2, Paint()..color = color);
    canvas.drawCircle(tip, 1.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter old) => old.phase != phase || old.color != color || old.dark != dark;
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({required this.values, required this.colors, required this.dark});
  final List<double> values;
  final List<Color> colors;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    const gap = 7.0;
    final center = size.center(Offset.zero);
    final maxR = (size.shortestSide - stroke) / 2;
    for (var i = 0; i < values.length; i++) {
      final r = maxR - i * (stroke + gap);
      if (r <= 0) continue;
      final color = colors[i % colors.length];
      canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = color.withValues(alpha: 0.16));
      final sweep = values[i].clamp(0.0, 1.0) * 2 * math.pi;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.values != values || old.colors != colors || old.dark != dark;
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.color, this.stroke = 8, required this.track});
  final double value;
  final Color color;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide - stroke) / 2;
    canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2, value.clamp(0.0, 1.0) * 2 * math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color || old.track != track;
}

class _HypnogramPainter extends CustomPainter {
  const _HypnogramPainter({required this.head, required this.color, required this.dark});
  final double head;
  final Color color;
  final bool dark;

  // Sleep stages over the night (0 = deep .. 1 = awake), as level fractions.
  static const _stages = [0.78, 0.55, 0.30, 0.30, 0.55, 0.80, 0.55, 0.30, 0.55, 0.78, 0.55, 0.78, 0.95];

  @override
  void paint(Canvas canvas, Size size) {
    final n = _stages.length;
    final stepW = size.width / n;
    final path = Path()..moveTo(0, size.height * (1 - _stages[0]));
    for (var i = 0; i < n; i++) {
      final y = size.height * (1 - _stages[i]);
      path.lineTo(i * stepW, y);
      path.lineTo((i + 1) * stepW, y);
    }
    final area = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.34), color.withValues(alpha: 0.04)]).createShader(Offset.zero & size));
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeJoin = StrokeJoin.round..color = color);

    // a soft "playback" marker traveling across the night
    final hx = head * size.width;
    canvas.drawLine(Offset(hx, 0), Offset(hx, size.height), Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 1.5);
    final idx = (head * n).floor().clamp(0, n - 1);
    final my = size.height * (1 - _stages[idx]);
    canvas.drawCircle(Offset(hx, my), 7, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(Offset(hx, my), 3.2, Paint()..color = color);
    canvas.drawCircle(Offset(hx, my), 1.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _HypnogramPainter old) => old.head != head || old.color != color || old.dark != dark;
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.t, required this.color, required this.dark});
  final double t;
  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = (dark ? Colors.white : Colors.black);
    // faint orbit guide
    canvas.drawCircle(center, 124, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = base.withValues(alpha: 0.06));
    // rotating arcs at several radii
    final radii = [98.0, 78.0, 58.0];
    final speeds = [0.5, -0.8, 1.2];
    final spans = [1.4, 1.0, 1.8];
    for (var i = 0; i < radii.length; i++) {
      final start = t * speeds[i] + i * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radii[i]),
        start,
        spans[i],
        false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round..color = color.withValues(alpha: 0.6 - i * 0.12),
      );
    }
    // sparkle ticks around the core
    final tick = Paint()..color = color.withValues(alpha: 0.5)..strokeWidth = 2..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = t * 0.4 + i * (2 * math.pi / 12);
      final r1 = 42.0 + 3 * math.sin(t * 2 + i);
      final r2 = r1 + 5;
      canvas.drawLine(center + Offset.fromDirection(a, r1), center + Offset.fromDirection(a, r2), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.t != t || old.color != color || old.dark != dark;
}
