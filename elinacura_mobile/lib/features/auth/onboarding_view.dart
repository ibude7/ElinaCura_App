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
const _rose = Color(0xFFFF6F91);
const _teal = Color(0xFF12C2C8);

String _fmt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

enum _Chapter { intro, vitals, fitness, sleep, meds, nutrition, care, ai }

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
  _PageData(kind: _Chapter.intro, eyebrow: 'ELINACURA', title: 'Your health, protected\nby *intention.*', subtitle: 'Medication-aware grocery planning, AI nutrition guidance, emergency medical ID, and caregiver sharing — built around your conditions, not around averages.', cta: 'Continue', accent: _violet),
  _PageData(kind: _Chapter.vitals, eyebrow: 'LIVE VITALS', title: 'Every heartbeat', subtitle: 'Heart rate, oxygen and recovery, read in real time and explained in plain language.', cta: 'Continue', accent: _red),
  _PageData(kind: _Chapter.fitness, eyebrow: 'MOVEMENT', title: 'Feel your progress', subtitle: 'Close your rings, log every session, and watch your momentum compound.', cta: 'Continue', accent: _orange),
  _PageData(kind: _Chapter.sleep, eyebrow: 'SLEEP', title: 'Wake up restored', subtitle: 'Stages, efficiency and recovery, so every morning starts informed.', cta: 'Continue', accent: _indigo),
  _PageData(kind: _Chapter.meds, eyebrow: 'MEDICATION', title: 'Never miss a dose', subtitle: 'Smart reminders, refill alerts and adherence you can actually keep.', cta: 'Continue', accent: _green),
  _PageData(kind: _Chapter.nutrition, eyebrow: 'NUTRITION', title: 'Eat with guidance', subtitle: 'Medication-aware grocery planning and AI nutrition guidance, tuned to your body and your meds.', cta: 'Continue', accent: _teal),
  _PageData(kind: _Chapter.care, eyebrow: 'CARE CIRCLE', title: 'Care stays close', subtitle: 'Share the right updates with family and clinicians, and reach help the moment it matters.', cta: 'Continue', accent: _rose),
  _PageData(kind: _Chapter.ai, eyebrow: 'AI COMPANION', title: 'One step ahead', subtitle: 'Everything you track, synthesized into clear guidance by a private intelligence.', cta: 'Create your account', accent: _blue),
];

/// Builds title spans, rendering any text wrapped in *asterisks* as an
/// emphasised italic. Geist ships no italic face, so the emphasis is skewed
/// for a genuine slant rather than relying on a (missing) italic font.
List<InlineSpan> _titleSpans(String title, TextStyle style) {
  final parts = title.split('*');
  final spans = <InlineSpan>[];
  for (var i = 0; i < parts.length; i++) {
    final s = parts[i];
    if (s.isEmpty) continue;
    if (i.isOdd) {
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Transform(
          transform: Matrix4.skewX(-0.2),
          alignment: Alignment.bottomLeft,
          child: Text(s, style: style.copyWith(fontStyle: FontStyle.italic)),
        ),
      ));
    } else {
      spans.add(TextSpan(text: s, style: style));
    }
  }
  return spans;
}

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
                  clipBehavior: Clip.none,
                  children: [
                    _HeroGlow(color: data.accent, opacity: eased),
                    // Hero is confined to a centred band so the floating cards
                    // sit in the clear top/bottom strips and never cover it.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: eased,
                          child: Transform.translate(
                            offset: Offset(delta * -28, 0),
                            child: FractionallySizedBox(
                              alignment: Alignment.center,
                              heightFactor: 0.56,
                              child: Transform.scale(
                                scale: 0.96 + 0.04 * eased,
                                child: Center(child: _Hero(kind: data.kind, accent: data.accent)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ..._floatingFor(data.kind, delta, eased),
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
              _revealText(focus, delta, 1, _title(p, data.title)),
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

  /// Title renderer: short phrases scale down to a single bold line (no awkward
  /// word breaks); a title carrying an explicit line break is a longer
  /// statement that wraps, sized to fit its width. Emphasis via *asterisks*.
  Widget _title(_Palette p, String title) {
    final multiline = title.contains('\n');
    final style = TextStyle(
      color: p.ink,
      fontSize: multiline ? 40 : 40,
      height: multiline ? 1.08 : 1.0,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.6,
    );
    final text = Text.rich(
      TextSpan(children: _titleSpans(title, style)),
      maxLines: multiline ? 3 : 1,
      softWrap: multiline,
      textAlign: TextAlign.left,
    );
    if (multiline) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(width: 340, child: text),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: text),
    );
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
      _Chapter.nutrition => const _NutritionHero(),
      _Chapter.care => const _CareHero(),
      _Chapter.ai => const _AiHero(),
    };
    return FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: 360, child: hero));
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

// ════════════════════════════════════ Floating 3D liquid-glass bento ══
/// A frosted glass pane that floats and tilts in 3D with a light-catch that
/// shifts as it tilts. The blurred body is built once; only the transform and
/// the specular highlight update each frame (so the backdrop blur isn't
/// re-rendered every tick).
class _FloatingGlass extends StatelessWidget {
  const _FloatingGlass({required this.child, required this.seed, this.delta = 0, this.parallax = 0});
  final Widget child;
  final double seed;
  final double delta;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    final radius = BorderRadius.circular(18);
    // Same transparency as the logo's liquid-glass disc, so every pane reads
    // as truly see-through frosted glass over the living background.
    final fill = p.dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.38);
    final border = p.dark ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.85);

    // Built once (not per frame) so the BackdropFilter blur isn't recomputed.
    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.dark ? 0.5 : 0.22), blurRadius: 28, spreadRadius: -8, offset: const Offset(0, 18))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(borderRadius: radius, color: fill, border: Border.all(color: border, width: 1.2)),
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        ),
      ),
    );

    return _Live(builder: (c, t) {
      final ph = t * 0.9 + seed;
      final bob = math.sin(ph) * 6;
      final tiltX = math.sin(ph * 0.8 + 1) * 0.07;
      final tiltY = math.cos(ph * 0.7) * 0.09;
      final m = Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateX(tiltX)
        ..rotateY(tiltY);
      final hx = (-tiltY * 6).clamp(-1.0, 1.0);
      final hy = (-tiltX * 6).clamp(-1.0, 1.0);
      return Transform.translate(
        offset: Offset(delta * parallax, bob),
        child: Transform(
          alignment: Alignment.center,
          transform: m,
          child: Stack(
            children: [
              body,
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(hx, hy),
                          radius: 0.9,
                          colors: [Colors.white.withValues(alpha: p.dark ? 0.16 : 0.5), Colors.white.withValues(alpha: 0)],
                          stops: const [0.0, 0.72],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ══════════════════════════════ Compact, detailed bento tiles ══
// Each tile is intentionally small yet information-dense — a header, a value
// and a live visual — so the floating glass panes read like the app's real
// cards. They live in the top/bottom strips so they never cover the hero.

TextStyle _tileLabel(_Palette p) => TextStyle(color: p.muted, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.9);
TextStyle _tileValue(_Palette p, {double size = 19}) => TextStyle(color: p.ink, fontSize: size, height: 1.0, fontWeight: FontWeight.w800, letterSpacing: -0.6, fontFeatures: const [FontFeature.tabularFigures()]);

Widget _tileHead(_Palette p, IconData icon, Color color, String label, {Widget? trailing}) {
  return Row(children: [
    Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(7)),
      child: Icon(icon, color: color, size: 12.5),
    ),
    const SizedBox(width: 7),
    Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _tileLabel(p))),
    ?trailing,
  ]);
}

/// Line-chart tile with a live value pill riding on the trace (glucose-style).
class _TileChart extends StatelessWidget {
  const _TileChart({required this.icon, required this.label, required this.color, required this.live, this.width = 134});
  final IconData icon;
  final String label;
  final Color color;
  final String Function(double t) live;
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tileHead(p, icon, color, label),
        const SizedBox(height: 10),
        SizedBox(
          height: 30,
          width: double.infinity,
          child: Stack(children: [
            Positioned.fill(child: _Live(builder: (c, t) => CustomPaint(painter: _GradientLinePainter(t: t, colors: [color])))),
            Positioned(
              left: 0,
              bottom: 0,
              child: _Live(builder: (c, t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: -1)]),
                    child: Text(live(t), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: -0.2, fontFeatures: [FontFeature.tabularFigures()])),
                  )),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Progress-ring tile with a centred icon and a value beside it.
class _TileRing extends StatelessWidget {
  const _TileRing({required this.icon, required this.label, required this.value, required this.frac, required this.color, this.width = 130});
  final IconData icon;
  final String label;
  final String value;
  final double frac;
  final Color color;
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Row(children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(
            painter: _RingPainter(value: frac, color: color, stroke: 5, track: p.faint),
            child: Center(child: Icon(icon, color: color, size: 15)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _tileLabel(p)),
            const SizedBox(height: 3),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: _tileValue(p, size: 18))),
          ]),
        ),
      ]),
    );
  }
}

/// Segmented-composition tile: a stacked bar + a tiny legend (sleep stages).
class _TileSeg extends StatelessWidget {
  const _TileSeg({required this.icon, required this.label, required this.color, required this.segments, this.width = 152});
  final IconData icon;
  final String label;
  final Color color;
  final List<(String, int, Color)> segments; // name, weight, colour
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tileHead(p, icon, color, label),
        const SizedBox(height: 11),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 7,
            child: Row(children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(flex: segments[i].$2, child: ColoredBox(color: segments[i].$3)),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 9),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: segments[i].$3, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(segments[i].$1, style: TextStyle(color: p.muted, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Heart-rate pill flanked by little equaliser bars (workout-style).
class _TilePulse extends StatelessWidget {
  const _TilePulse({required this.color, required this.live, this.width = 150});
  final Color color;
  final String Function(double t) live;
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tileHead(p, Icons.favorite_rounded, color, 'HEART RATE'),
        const SizedBox(height: 10),
        Row(children: [
          SizedBox(width: 14, height: 26, child: _Live(builder: (c, t) => CustomPaint(painter: _BarsPainter(t: t, color: color.withValues(alpha: 0.45), track: Colors.transparent, count: 2)))),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 30,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: -2)]),
              alignment: Alignment.center,
              child: _Live(builder: (c, t) => Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(live(t), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.2, fontFeatures: [FontFeature.tabularFigures()])),
                  ])),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(width: 14, height: 26, child: _Live(builder: (c, t) => CustomPaint(painter: _BarsPainter(t: t + 1.6, color: color.withValues(alpha: 0.45), track: Colors.transparent, count: 2)))),
        ]),
      ]),
    );
  }
}

/// Status tile: an icon box, a title + subtitle, and a small status badge.
class _TileStatus extends StatelessWidget {
  const _TileStatus({required this.icon, required this.color, required this.title, required this.sub, this.badge, this.badgeIcon = Icons.check_circle_rounded, this.width = 156});
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final String? badge;
  final IconData badgeIcon;
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.ink, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(badgeIcon, color: color, size: 11),
                  const SizedBox(width: 4),
                  Text(badge!, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// A live value over a rainbow gradient meter with a travelling knob.
class _TileMeter extends StatelessWidget {
  const _TileMeter({required this.icon, required this.label, required this.color, required this.live, this.width = 146});
  final IconData icon;
  final String label;
  final Color color;
  final String Function(double t) live;
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tileHead(p, icon, color, label, trailing: _Live(builder: (c, t) => Text(live(t), style: _tileValue(p, size: 13)))),
        const SizedBox(height: 11),
        SizedBox(height: 12, width: double.infinity, child: _Live(builder: (c, t) => CustomPaint(painter: _MeterPainter(t: t)))),
      ]),
    );
  }
}

/// Streak tile: a value and a row of progress dots.
class _TileDots extends StatelessWidget {
  const _TileDots({required this.icon, required this.label, required this.value, required this.color, this.count = 7, this.filled = 6, this.width = 132});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int count;
  final int filled;
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tileHead(p, icon, color, label, trailing: Text(value, style: _tileValue(p, size: 13))),
        const SizedBox(height: 12),
        SizedBox(height: 14, width: double.infinity, child: _Live(builder: (c, t) => CustomPaint(painter: _DotsPainter(t: t, color: color, track: p.faint, count: count, filled: filled)))),
      ]),
    );
  }
}

/// Bars tile: a live value and a scrolling bar chart (steps / refills).
class _TileBars extends StatelessWidget {
  const _TileBars({required this.icon, required this.label, required this.color, required this.live, this.width = 134});
  final IconData icon;
  final String label;
  final Color color;
  final String Function(double t) live;
  final double width;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _tileHead(p, icon, color, label, trailing: _Live(builder: (c, t) => Text(live(t), style: _tileValue(p, size: 13)))),
        const SizedBox(height: 11),
        SizedBox(height: 22, width: double.infinity, child: _Live(builder: (c, t) => CustomPaint(painter: _BarsPainter(t: t, color: color, track: p.faint, count: 9)))),
      ]),
    );
  }
}

// ── Painters used by the tiles ──
class _GradientLinePainter extends CustomPainter {
  _GradientLinePainter({required this.t, required this.colors});
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[];
    for (double x = 0; x <= size.width; x += 2) {
      final u = x / size.width;
      final base = 0.66 - 0.34 * u; // gently rising to the right
      final wob = 0.07 * math.sin(u * 6.3 + t * 1.2) + 0.045 * math.sin(u * 12 - t * 0.8);
      final y = (base + wob).clamp(0.08, 0.95) * size.height;
      pts.add(Offset(x, y));
    }
    if (pts.length < 2) return;
    final path = Path()..addPolygon(pts, false);
    final area = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    final c0 = colors.first;
    canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c0.withValues(alpha: 0.22), c0.withValues(alpha: 0)]).createShader(Offset.zero & size));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (colors.length > 1) {
      stroke.shader = LinearGradient(colors: colors).createShader(Offset.zero & size);
    } else {
      stroke.color = c0;
    }
    canvas.drawPath(path, stroke);
    final tip = pts.last;
    canvas.drawCircle(tip, 3.4, Paint()..color = Colors.white);
    canvas.drawCircle(tip, 3.4, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = colors.last);
  }

  @override
  bool shouldRepaint(covariant _GradientLinePainter old) => old.t != t || old.colors != colors;
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const h = 5.0;
    final y = size.height / 2 - h / 2;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(0, y, size.width, h), const Radius.circular(h / 2));
    canvas.drawRRect(rect, Paint()..shader = const LinearGradient(colors: [_green, _orange, _red, _violet, _blue]).createShader(Offset.zero & size));
    final pos = (0.5 + 0.42 * math.sin(t * 0.7)) * size.width;
    final c = Offset(pos.clamp(7.0, size.width - 7), size.height / 2);
    canvas.drawCircle(c, 6, Paint()..color = Colors.white);
    canvas.drawCircle(c, 6, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black.withValues(alpha: 0.12));
    canvas.drawCircle(c, 2.4, Paint()..color = _orange);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) => old.t != t;
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.t, required this.color, required this.track, required this.count});
  final double t;
  final Color color;
  final Color track;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 4.0;
    final bw = (size.width - gap * (count - 1)) / count;
    if (bw <= 0) return;
    for (var i = 0; i < count; i++) {
      final phase = t * 1.5 - i * 0.55;
      final hh = (0.28 + 0.72 * (0.5 + 0.5 * math.sin(phase))) * size.height;
      final x = i * (bw + gap);
      final active = i >= count - 2;
      if (track.a > 0) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, bw, size.height), const Radius.circular(2)), Paint()..color = track);
      }
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - hh, bw, hh), const Radius.circular(2)), Paint()..color = active ? color : color.withValues(alpha: 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => old.t != t || old.color != color || old.track != track || old.count != count;
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.t, required this.color, required this.track, required this.count, required this.filled});
  final double t;
  final Color color;
  final Color track;
  final int count;
  final int filled;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final step = size.width / count;
    final r = math.min(size.height / 2 - 1, step / 2 - 2.5);
    if (r <= 0) return;
    final pulse = (t * 1.3) % count;
    for (var i = 0; i < count; i++) {
      final cx = step * i + step / 2;
      final on = i < filled;
      final glow = (1 - (pulse - i).abs()).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = on ? color.withValues(alpha: 0.9) : track);
      if (on && glow > 0) {
        canvas.drawCircle(Offset(cx, cy), r + 3 * glow, Paint()..color = color.withValues(alpha: 0.35 * glow));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.t != t || old.color != color || old.track != track || old.filled != filled;
}

Widget _fc({double? top, double? right, double? bottom, double? left, required double seed, required double delta, required double parallax, required double eased, required Widget child}) {
  final enter = Curves.easeOutBack.transform(eased.clamp(0.0, 1.0));
  return Positioned(
    top: top,
    right: right,
    bottom: bottom,
    left: left,
    child: Opacity(
      opacity: eased,
      child: Transform.scale(
        scale: 0.86 + 0.14 * enter,
        child: _FloatingGlass(seed: seed, delta: delta, parallax: parallax, child: child),
      ),
    ),
  );
}

List<Widget> _floatingFor(_Chapter kind, double delta, double eased) {
  if (eased < 0.04) return const <Widget>[];
  switch (kind) {
    case _Chapter.intro:
      return [
        _fc(top: 2, right: -6, seed: 0.0, delta: delta, parallax: 24, eased: eased, child: _TileChart(icon: Icons.favorite_rounded, label: 'HEART RATE', color: _red, width: 138, live: (t) => '${(72 + 3 * math.sin(t * 0.9)).round()} bpm')),
        _fc(bottom: 2, left: -6, seed: 2.3, delta: delta, parallax: 34, eased: eased, child: _TileBars(icon: Icons.directions_walk_rounded, label: 'STEPS TODAY', color: _green, width: 138, live: (t) => _fmt(8210 + (t * 0.8).floor()))),
      ];
    case _Chapter.vitals:
      return [
        _fc(top: 2, right: -6, seed: 0.7, delta: delta, parallax: 26, eased: eased, child: _TileChart(icon: Icons.bloodtype_rounded, label: 'BLOOD O₂', color: _blue, width: 132, live: (t) => '${98 + math.sin(t * 0.5).round()}%')),
        _fc(bottom: 2, left: -6, seed: 2.6, delta: delta, parallax: 36, eased: eased, child: const _TileRing(icon: Icons.monitor_heart_rounded, label: 'HRV', value: '64 ms', frac: 0.7, color: _red, width: 130)),
        _fc(bottom: 2, right: -6, seed: 1.5, delta: delta, parallax: 30, eased: eased, child: _TileChart(icon: Icons.air_rounded, label: 'RESP RATE', color: _green, width: 132, live: (t) => '${(14 + 2 * math.sin(t * 0.5)).round()}/min')),
      ];
    case _Chapter.fitness:
      return [
        _fc(top: 2, right: -6, seed: 1.1, delta: delta, parallax: 26, eased: eased, child: _TilePulse(color: _orange, width: 150, live: (t) => '${(132 + 6 * math.sin(t * 1.1)).round()} BPM')),
        _fc(bottom: 2, left: -6, seed: 3.0, delta: delta, parallax: 36, eased: eased, child: _TileMeter(icon: Icons.local_fire_department_rounded, label: 'ACTIVE ENERGY', color: _orange, width: 146, live: (t) => '${(540 + 30 * (0.5 + 0.5 * math.sin(t * 0.25))).round()} kcal')),
        _fc(bottom: 2, right: -6, seed: 1.8, delta: delta, parallax: 30, eased: eased, child: const _TileRing(icon: Icons.speed_rounded, label: 'VO₂ MAX', value: '48', frac: 0.62, color: _blue, width: 120)),
      ];
    case _Chapter.sleep:
      return [
        _fc(top: 2, right: -6, seed: 0.4, delta: delta, parallax: 26, eased: eased, child: const _TileSeg(icon: Icons.bedtime_rounded, label: 'SLEEP STAGES', color: _indigo, width: 152, segments: [('Deep', 26, _indigo), ('REM', 22, _violet), ('Light', 52, _blue)])),
        _fc(bottom: 2, left: -6, seed: 2.9, delta: delta, parallax: 36, eased: eased, child: const _TileRing(icon: Icons.bolt_rounded, label: 'EFFICIENCY', value: '92%', frac: 0.92, color: _green, width: 130)),
        _fc(bottom: 2, right: -6, seed: 1.4, delta: delta, parallax: 30, eased: eased, child: const _TileStatus(icon: Icons.nightlight_round, color: _indigo, title: 'Deep sleep', sub: '1h 21m', badge: 'OPTIMAL', width: 150)),
      ];
    case _Chapter.meds:
      return [
        _fc(top: 2, right: -6, seed: 0.9, delta: delta, parallax: 26, eased: eased, child: const _TileRing(icon: Icons.task_alt_rounded, label: 'ADHERENCE', value: '98%', frac: 0.98, color: _green, width: 132)),
        _fc(bottom: 2, left: -6, seed: 2.4, delta: delta, parallax: 36, eased: eased, child: const _TileStatus(icon: Icons.inventory_2_rounded, color: _blue, title: 'Vitamin D', sub: 'Refill in 3 days', badge: 'REORDER', width: 156)),
      ];
    case _Chapter.nutrition:
      return [
        _fc(top: 2, right: -6, seed: 0.6, delta: delta, parallax: 26, eased: eased, child: const _TileStatus(icon: Icons.shopping_basket_rounded, color: _teal, title: 'Oat milk', sub: 'Safe with your meds', badge: 'SAFE', badgeIcon: Icons.verified_rounded, width: 160)),
        _fc(bottom: 2, left: -6, seed: 2.5, delta: delta, parallax: 36, eased: eased, child: const _TileStatus(icon: Icons.auto_awesome_rounded, color: _violet, title: 'Add spinach', sub: 'Iron-rich for today', badge: 'AI PICK', badgeIcon: Icons.auto_awesome_rounded, width: 158)),
        _fc(bottom: 2, right: -6, seed: 1.4, delta: delta, parallax: 30, eased: eased, child: _TileChart(icon: Icons.water_drop_rounded, label: 'GLUCOSE', color: _orange, width: 132, live: (t) => '${(96 + 6 * math.sin(t * 0.5)).round()} mg/dL')),
      ];
    case _Chapter.care:
      return [
        _fc(top: 2, right: -6, seed: 0.6, delta: delta, parallax: 26, eased: eased, child: const _TileStatus(icon: Icons.event_available_rounded, color: _blue, title: 'Dr. Almeida', sub: 'Cardiology · Tue', badge: '10:30 AM', badgeIcon: Icons.schedule_rounded, width: 158)),
        _fc(bottom: 2, left: -6, seed: 2.5, delta: delta, parallax: 36, eased: eased, child: const _TileStatus(icon: Icons.emergency_rounded, color: _red, title: 'Emergency SOS', sub: 'Hold to alert circle', badge: 'ARMED', badgeIcon: Icons.shield_rounded, width: 158)),
      ];
    case _Chapter.ai:
      return [
        _fc(top: 2, right: -6, seed: 0.5, delta: delta, parallax: 26, eased: eased, child: const _TileStatus(icon: Icons.shield_rounded, color: _blue, title: 'Private AI', sub: 'Runs on-device', badge: 'SECURE', width: 156)),
        _fc(bottom: 2, left: -6, seed: 2.7, delta: delta, parallax: 36, eased: eased, child: const _TileDots(icon: Icons.hub_rounded, label: 'SIGNALS', value: '4 synced', color: _violet, count: 6, filled: 4, width: 132)),
      ];
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
          // brand mark on a frosted liquid-glass disc
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _violet.withValues(alpha: p.dark ? 0.3 : 0.18), blurRadius: 40, spreadRadius: -6)],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.38),
                    border: Border.all(color: p.dark ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.85), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // glassy specular sheen
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.5, -0.6),
                                radius: 0.95,
                                colors: [Colors.white.withValues(alpha: p.dark ? 0.16 : 0.5), Colors.white.withValues(alpha: 0)],
                                stops: const [0.0, 0.7],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const EcLogo(size: 84),
                    ],
                  ),
                ),
              ),
            ),
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
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 12),
        SizedBox(width: 360, height: 158, child: _Live(builder: (c, t) => CustomPaint(painter: _EcgPainter(phase: t * 1.2, color: _red, dark: p.dark, grid: true, glow: true)))),
      ],
    );
  }
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

// ═══════════════════════════════════════════════════════════ Fitness ══
class _FitnessHero extends StatelessWidget {
  const _FitnessHero();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
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
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 20),
        SizedBox(width: 360, height: 140, child: _Live(builder: (c, t) => CustomPaint(painter: _HypnogramPainter(head: (t * 0.06) % 1.0, color: _indigo, dark: p.dark)))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════ Meds ══
enum _DoseState { taken, next, upcoming }

class _MedsHero extends StatelessWidget {
  const _MedsHero();

  static double _secsLeft(double t) => (9783 - t) % 10800; // counts down, wraps over a 3h cycle

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live next-dose capsule
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.hairline),
            boxShadow: [BoxShadow(color: _green.withValues(alpha: p.dark ? 0.16 : 0.10), blurRadius: 30, spreadRadius: -10, offset: const Offset(0, 12))],
          ),
          child: Row(children: [
            SizedBox(
              width: 76,
              height: 76,
              child: _Live(builder: (c, t) {
                final frac = (1 - _secsLeft(t) / 10800).clamp(0.02, 1.0);
                return CustomPaint(
                  painter: _RingPainter(value: frac, color: _green, stroke: 7, track: p.faint),
                  child: Center(child: Icon(Icons.medication_rounded, color: _green, size: 26)),
                );
              }),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  const _LiveTag(color: _green),
                  const SizedBox(width: 8),
                  Text('NEXT DOSE', style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                ]),
                const SizedBox(height: 8),
                Text('Metformin · 500 mg', style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                const SizedBox(height: 5),
                _Live(builder: (c, t) {
                  final r = _secsLeft(t).floor();
                  final h = r ~/ 3600, m = (r % 3600) ~/ 60, s = r % 60;
                  return Row(children: [
                    Icon(Icons.schedule_rounded, color: p.muted, size: 14),
                    const SizedBox(width: 5),
                    Text('in ${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])),
                  ]);
                }),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        _doseRow(p, '08:00', 'Metformin', '500 mg', _violet, _DoseState.taken, first: true),
        _doseRow(p, '13:00', 'Omega-3', '1 softgel', _blue, _DoseState.next),
        _doseRow(p, '21:00', 'Atorvastatin', '20 mg', _orange, _DoseState.upcoming, last: true),
      ],
    );
  }

  Widget _doseRow(_Palette p, String time, String name, String dose, Color color, _DoseState state, {bool first = false, bool last = false}) {
    final isNext = state == _DoseState.next;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Text(time, textAlign: TextAlign.right, style: TextStyle(color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 20,
          child: Column(children: [
            Expanded(child: Container(width: 2, color: first ? Colors.transparent : p.hairline)),
            _node(p, color, state),
            Expanded(child: Container(width: 2, color: last ? Colors.transparent : p.hairline)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isNext ? color.withValues(alpha: 0.10) : p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isNext ? color.withValues(alpha: 0.45) : p.hairline),
            ),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)), child: Icon(Icons.medication_rounded, color: color, size: 16)),
              const SizedBox(width: 11),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: p.ink, fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                  Text(dose, style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
              _statusChip(p, state),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _node(_Palette p, Color color, _DoseState state) {
    switch (state) {
      case _DoseState.taken:
        return Container(width: 18, height: 18, decoration: const BoxDecoration(shape: BoxShape.circle, color: _green), child: const Icon(Icons.check_rounded, size: 12, color: Colors.white));
      case _DoseState.next:
        return Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)]))
            .animate(onPlay: (a) => a.repeat(reverse: true))
            .scaleXY(begin: 1, end: 1.22, duration: 900.ms, curve: Curves.easeInOut);
      case _DoseState.upcoming:
        return Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.muted.withValues(alpha: 0.5), width: 2)));
    }
  }

  Widget _statusChip(_Palette p, _DoseState state) {
    final (c, label, ic) = switch (state) {
      _DoseState.taken => (_green, 'Taken', Icons.check_circle_rounded),
      _DoseState.next => (_orange, 'Due now', Icons.notifications_active_rounded),
      _DoseState.upcoming => (p.muted, 'Later', Icons.schedule_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, color: c, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700)),
      ]),
    );
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

// ═══════════════════════════════════════════════════════════ Care ══
class _CareHero extends StatelessWidget {
  const _CareHero();
  // Caregivers in the circle — initials + their accent colour.
  static const _members = <(String, Color)>[
    ('JL', _blue),
    ('MA', _green),
    ('SK', _orange),
  ];

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
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
                  // network: connection lines from the user to each caregiver,
                  // with care/updates pulsing outward along them.
                  CustomPaint(size: const Size(300, 300), painter: _CareNetPainter(t: t, color: _rose, dark: p.dark, count: _members.length)),
                  for (var i = 0; i < _members.length; i++)
                    Transform.translate(
                      offset: Offset.fromDirection(-math.pi / 2 + i * (2 * math.pi / _members.length), 116),
                      child: _CareAvatar(initials: _members[i].$1, color: _members[i].$2),
                    ),
                  // soft halo + the user's heart at the centre
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_rose, _rose.withValues(alpha: 0.0)], stops: const [0.2, 1.0])),
                  ),
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surface,
                      border: Border.all(color: _rose.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [BoxShadow(color: _rose.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: -2)],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.volunteer_activism_rounded, color: _rose, size: 34),
                  ).animate(onPlay: (a) => a.repeat(reverse: true)).scaleXY(begin: 1, end: 1.06, duration: 2200.ms, curve: Curves.easeInOut),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: p.hairline)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.4, end: 1, duration: 900.ms),
                const SizedBox(width: 9),
                Text('3 caregivers connected', style: TextStyle(color: p.ink, fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareAvatar extends StatelessWidget {
  const _CareAvatar({required this.initials, required this.color});
  final String initials;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(color.withValues(alpha: 0.22), p.surface),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 14, spreadRadius: -4)],
      ),
      alignment: Alignment.center,
      child: Text(initials, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.92, end: 1.06, duration: 2400.ms, curve: Curves.easeInOut);
  }
}

class _CareNetPainter extends CustomPainter {
  const _CareNetPainter({required this.t, required this.color, required this.dark, required this.count});
  final double t;
  final Color color;
  final bool dark;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = dark ? Colors.white : Colors.black;
    const r = 116.0;
    // faint guide ring tying the circle together
    canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = base.withValues(alpha: 0.05));
    for (var i = 0; i < count; i++) {
      final a = -math.pi / 2 + i * (2 * math.pi / count);
      final end = center + Offset.fromDirection(a, r);
      canvas.drawLine(center, end, Paint()..strokeWidth = 1.5..color = color.withValues(alpha: 0.22));
      // two updates flowing outward along each line, fading at the ends
      for (var k = 0; k < 2; k++) {
        final f = (t * 0.5 + i / count + k * 0.5) % 1.0;
        final pt = Offset.lerp(center, end, f)!;
        final fade = (1 - (f - 0.5).abs() * 2).clamp(0.0, 1.0);
        canvas.drawCircle(pt, 3.0, Paint()..color = color.withValues(alpha: 0.7 * fade));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CareNetPainter old) => old.t != t || old.color != color || old.dark != dark || old.count != count;
}

// ═══════════════════════════════════════════════════════════ Nutrition ══
class _NutritionHero extends StatelessWidget {
  const _NutritionHero();
  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 222,
            height: 222,
            child: _Live(builder: (c, t) {
              final breathe = 1 + 0.012 * math.sin(t * 1.2);
              return Transform.scale(
                scale: breathe,
                child: CustomPaint(
                  painter: _MacroDonutPainter(t: t, values: const [50, 26, 24], colors: const [_teal, _violet, _orange], dark: p.dark),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Live(builder: (c, t) {
                          final kcal = 1840 + (6 * math.sin(t * 0.7)).round();
                          return Text(_fmt(kcal), style: TextStyle(color: p.ink, fontSize: 38, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.6, fontFeatures: const [FontFeature.tabularFigures()]));
                        }),
                        Text('KCAL · TODAY', style: TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _macroChip(p, _teal, 'Carbs', '50%'),
              const SizedBox(width: 16),
              _macroChip(p, _violet, 'Protein', '26%'),
              const SizedBox(width: 16),
              _macroChip(p, _orange, 'Fat', '24%'),
            ]),
          ),
          const SizedBox(height: 18),
          const _NutritionInsight(),
        ],
      ),
    );
  }

  Widget _macroChip(_Palette p, Color color, String label, String pct) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label ', style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(pct, style: TextStyle(color: p.ink, fontSize: 12, fontWeight: FontWeight.w800)),
    ]);
  }
}

class _NutritionInsight extends StatelessWidget {
  const _NutritionInsight();
  static const _items = [
    'Balanced plate today',
    'Low sodium — kind to your meds',
    'High in fiber',
    'Add iron-rich greens',
    'Great protein ratio',
  ];

  @override
  Widget build(BuildContext context) {
    final p = _ClockScope.paletteOf(context);
    return _Live(builder: (c, t) {
      final i = (t / 2.6).floor() % _items.length;
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedSwitcher(
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
                const Icon(Icons.auto_awesome_rounded, color: _teal, size: 15),
                const SizedBox(width: 8),
                Text(_items[i], style: TextStyle(color: p.ink, fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _MacroDonutPainter extends CustomPainter {
  const _MacroDonutPainter({required this.t, required this.values, required this.colors, required this.dark});
  final double t;
  final List<double> values;
  final List<Color> colors;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 24.0;
    final r = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    final base = dark ? Colors.white : Colors.black;
    canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = base.withValues(alpha: 0.06));
    final total = values.fold<double>(0, (a, b) => a + b);
    const gap = 0.10;
    var startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final frac = values[i] / total;
      final sweep = frac * 2 * math.pi - gap;
      canvas.drawArc(rect, startAngle + gap / 2, sweep, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = colors[i].withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawArc(rect, startAngle + gap / 2, sweep, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = colors[i]);
      startAngle += frac * 2 * math.pi;
    }
    // a bright "AI scan" highlight sweeping around the plate
    final sweepStart = (t * 0.9) % (2 * math.pi) - math.pi / 2;
    canvas.drawArc(rect, sweepStart, 0.45, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = Colors.white.withValues(alpha: dark ? 0.42 : 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter old) => old.t != t || old.values != values || old.colors != colors || old.dark != dark;
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
