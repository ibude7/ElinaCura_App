import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_logo.dart';

// ════════════════════════════════════════════════════════════════════════
//  ElinaCura — Onboarding
//  A living brushed-silver canvas, editorial titling, and a dense bento of
//  premium frosted-glass health widgets that assemble as you swipe.
//  Colour lives inside the widgets; the canvas stays neutral.
// ════════════════════════════════════════════════════════════════════════

const _coral = Color(0xFFFF6F61);
const _blue = Color(0xFF4B7BFF);
const _green = Color(0xFF34C759);
const _orange = Color(0xFFFF8A3D);
const _violet = Color(0xFF8B6FE8);
const _amber = Color(0xFFFFB23E);
const _cyan = Color(0xFF22C7D6);

enum _PageKind { intro, wellness, fitness, sleep, meds, finale }

class _OnbPage {
  const _OnbPage({
    required this.kind,
    required this.eyebrow,
    required this.title,
    this.subtitle = '',
    required this.cta,
    required this.accent,
  });

  final _PageKind kind;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String cta;
  final Color accent;
}

const _pages = <_OnbPage>[
  _OnbPage(
    kind: _PageKind.intro,
    eyebrow: 'ELINACURA',
    title: 'The everything\nhealth app',
    cta: 'Continue',
    accent: _violet,
  ),
  _OnbPage(
    kind: _PageKind.wellness,
    eyebrow: 'WELLNESS',
    title: 'Wellness',
    subtitle: 'Understand the impact of your habits and lifestyle on your health.',
    cta: 'Continue',
    accent: _coral,
  ),
  _OnbPage(
    kind: _PageKind.fitness,
    eyebrow: 'FITNESS',
    title: 'Fitness',
    subtitle: 'Build, track, and maintain your strength and endurance.',
    cta: 'Continue',
    accent: _orange,
  ),
  _OnbPage(
    kind: _PageKind.sleep,
    eyebrow: 'SLEEP',
    title: 'Sleep',
    subtitle: 'Discover your sleep patterns to achieve consistent, restorative rest.',
    cta: 'Continue',
    accent: _violet,
  ),
  _OnbPage(
    kind: _PageKind.meds,
    eyebrow: 'MEDICATION',
    title: 'Medication',
    subtitle: 'Stay on top of every dose with smart reminders and refill alerts.',
    cta: 'Continue',
    accent: _blue,
  ),
  _OnbPage(
    kind: _PageKind.finale,
    eyebrow: "YOU'RE READY",
    title: "You're all set",
    subtitle:
        'Create your free account to bring it all together — private, encrypted, and yours.',
    cta: 'Get started',
    accent: _violet,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _debugStart = int.fromEnvironment('OB_PAGE');

  final _pageController = PageController(initialPage: _debugStart);
  final _page = ValueNotifier<double>(_debugStart.toDouble());
  int _index = _debugStart;

  int get _count => _pages.length;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      _page.value = _pageController.page ?? _index.toDouble();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _count - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: EcTokens.motionSlow,
        curve: Curves.easeOutCubic,
      );
    } else {
      HapticFeedback.mediumImpact();
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SilverBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _count,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _index = i);
                    },
                    itemBuilder: (context, i) =>
                        _OnbPageView(page: _page, index: i, count: _count, data: _pages[i]),
                  ),
                ),
                _BottomChrome(
                  page: _page,
                  count: _count,
                  label: _pages[_index].cta,
                  onPrimary: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════ Background ══
class _SilverBackground extends StatefulWidget {
  const _SilverBackground();

  @override
  State<_SilverBackground> createState() => _SilverBackgroundState();
}

class _SilverBackgroundState extends State<_SilverBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF1B1E25), Color(0xFF15171C), Color(0xFF0D0E12)]
              : const [Color(0xFFB7BDC8), Color(0xFFC9CED6), Color(0xFFE9EBEF)],
        ),
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _SilverPainter(t: _c.value, isDark: isDark),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SilverPainter extends CustomPainter {
  const _SilverPainter({required this.t, required this.isDark});
  final double t;
  final bool isDark;

  void _glow(Canvas c, Size s, Offset center, double r, Color color) {
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final phase = t * 2 * math.pi;

    // Drifting metallic highlight (top) and shadow pool (bottom).
    _glow(
      canvas,
      size,
      Offset(w * (0.30 + 0.18 * math.sin(phase)), h * (0.14 + 0.05 * math.cos(phase))),
      w * 0.9,
      Colors.white.withValues(alpha: isDark ? 0.05 : 0.42),
    );
    _glow(
      canvas,
      size,
      Offset(w * (0.78 + 0.12 * math.cos(phase * 0.8)), h * (0.82 + 0.04 * math.sin(phase))),
      w * 0.8,
      (isDark ? Colors.black : const Color(0xFF8A91A0))
          .withValues(alpha: isDark ? 0.34 : 0.22),
    );
    _glow(
      canvas,
      size,
      Offset(w * (0.12 + 0.06 * math.sin(phase * 1.2)), h * 0.5),
      w * 0.55,
      Colors.white.withValues(alpha: isDark ? 0.03 : 0.22),
    );

    // Soft diagonal sheen band.
    final bandCenter = (0.2 + 0.6 * ((t + 0.5) % 1.0)) * h;
    final band = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: isDark ? 0.03 : 0.14),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, bandCenter - h * 0.25, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, bandCenter - h * 0.25, w, h * 0.5), band);
  }

  @override
  bool shouldRepaint(covariant _SilverPainter old) => old.t != t || old.isDark != isDark;
}

// ────────────────────────────────────────────────────────── Page view ──
class _OnbPageView extends StatelessWidget {
  const _OnbPageView({
    required this.page,
    required this.index,
    required this.count,
    required this.data,
  });

  final ValueNotifier<double> page;
  final int index;
  final int count;
  final _OnbPage data;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: page,
      builder: (context, _) {
        final delta = page.value - index;
        final focus = (1 - delta.abs()).clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(focus.clamp(0.0, 1.0)),
          child: data.kind == _PageKind.intro
              ? _IntroContent(delta: delta, focus: focus)
              : _FeaturePage(data: data, index: index, count: count, delta: delta, focus: focus),
        );
      },
    );
  }
}

/// Staggered reveal + horizontal parallax for a layer.
Widget _reveal(double focus, double delta, int order, double parallax, Widget child) {
  final start = order * 0.08;
  final t = ((focus - start) / (1 - start)).clamp(0.0, 1.0);
  final e = Curves.easeOutCubic.transform(t);
  return Opacity(
    opacity: e,
    child: Transform.translate(
      offset: Offset(delta * -parallax, (1 - e) * 26),
      child: child,
    ),
  );
}

Widget _layer(double delta, double factor, Widget child) =>
    Transform.translate(offset: Offset(delta * factor, 0), child: child);

// ───────────────────────────────────────────────────────────── Intro ──
class _IntroContent extends StatelessWidget {
  const _IntroContent({required this.delta, required this.focus});
  final double delta;
  final double focus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : const Color(0xFF5E646E);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 330,
          height: 640,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _reveal(
                focus,
                delta,
                0,
                10,
                SizedBox(
                  width: 320,
                  height: 284,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const _PulseRing(delayMs: 0),
                      const _PulseRing(delayMs: 1400),
                      _layer(delta, 8, const _LogoOrb()),
                      Positioned(top: 12, left: 4, child: _layer(delta, 60, const _FloatChip(icon: Icons.favorite_rounded, label: '72 BPM', color: _coral))),
                      Positioned(top: 64, right: -2, child: _layer(delta, 84, const _FloatChip(icon: Icons.nightlight_round, label: 'Sleep 94', color: _violet))),
                      Positioned(bottom: 58, left: -6, child: _layer(delta, 76, const _FloatChip(icon: Icons.directions_walk_rounded, label: '8,210 steps', color: _green))),
                      Positioned(bottom: 6, right: 8, child: _layer(delta, 56, const _FloatChip(icon: Icons.bolt_rounded, label: '420 kcal', color: _orange))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _reveal(
                focus,
                delta,
                1,
                22,
                Text(
                  'The everything\nhealth app',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1.3, color: ink),
                ),
              ),
              const SizedBox(height: 12),
              _reveal(
                focus,
                delta,
                2,
                34,
                SizedBox(
                  width: 300,
                  child: Text(
                    'Vitals, movement, sleep and medication — together in one calm, intelligent space.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7078)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoOrb extends StatelessWidget {
  const _LogoOrb();

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 999,
      padding: const EdgeInsets.all(34),
      child: const SizedBox(width: 92, height: 92, child: Center(child: EcLogo(size: 90))),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          begin: 1,
          end: 1.04,
          duration: 3600.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.delayMs});
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.6),
          width: 1.5,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(begin: 0.7, end: 1.7, duration: 3000.ms, delay: delayMs.ms, curve: Curves.easeOut)
        .fadeOut(duration: 3000.ms, delay: delayMs.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────── Feature ──
class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.data,
    required this.index,
    required this.count,
    required this.delta,
    required this.focus,
  });

  final _OnbPage data;
  final int index;
  final int count;
  final double delta;
  final double focus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFFF6F8FB);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.64) : const Color(0xFF555B65);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reveal(
            focus,
            delta,
            0,
            16,
            Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: data.accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  data.eyebrow,
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF676D77),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(index + 1).toString().padLeft(2, '0')} / ${count.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF7C828C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _reveal(
            focus,
            delta,
            1,
            22,
            Text(
              data.title,
              style: TextStyle(
                fontSize: 44,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.6,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _reveal(
            focus,
            delta,
            2,
            32,
            Text(
              data.subtitle,
              style: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w500, color: subColor),
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 342,
                  child: _Bento(kind: data.kind, delta: delta, focus: focus),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bento extends StatelessWidget {
  const _Bento({required this.kind, required this.delta, required this.focus});
  final _PageKind kind;
  final double delta;
  final double focus;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _PageKind.wellness => _WellnessBento(delta: delta, focus: focus),
      _PageKind.fitness => _FitnessBento(delta: delta, focus: focus),
      _PageKind.sleep => _SleepBento(delta: delta, focus: focus),
      _PageKind.meds => _MedsBento(delta: delta, focus: focus),
      _PageKind.finale => _FinaleBento(delta: delta, focus: focus),
      _PageKind.intro => const SizedBox.shrink(),
    };
  }
}

// ═══════════════════════════════════════════════════════════ Glass ══
class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(16), this.radius = 26});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF2A2F3A)).withValues(alpha: isDark ? 0.38 : 0.16),
            blurRadius: 30,
            spreadRadius: -12,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.04)]
                    : [Colors.white.withValues(alpha: 0.82), Colors.white.withValues(alpha: 0.58)],
              ),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.9),
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

Color _ink(BuildContext c) => Theme.of(c).colorScheme.onSurface;

// ═══════════════════════════════════════════════════════════ Wellness ══
class _WellnessBento extends StatelessWidget {
  const _WellnessBento({required this.delta, required this.focus});
  final double delta;
  final double focus;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _reveal(focus, delta, 3, 18, _Glass(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _IconBadge(icon: Icons.favorite_rounded, color: _coral),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Heart rate', style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          Text('72', style: TextStyle(color: _ink(context), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                          const SizedBox(width: 3),
                          Text('BPM', style: TextStyle(color: ec.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ],
                    ),
                  ),
                  const _TrendPill(label: 'Resting', color: _green),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(height: 46, width: double.infinity, child: CustomPaint(painter: _SparkPainter(values: const [58, 64, 60, 72, 67, 80, 74, 88, 79, 72], color: _coral))),
            ],
          ),
        )),
        const SizedBox(height: 12),
        _reveal(focus, delta, 4, 30, SizedBox(
          height: 150,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Expanded(flex: 6, child: _HydrationCard()),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: _RingStatCard(value: 0.94, score: '94', label: 'Sleep', sub: 'Restful', color: _violet)),
          ]),
        )),
        const SizedBox(height: 12),
        _reveal(focus, delta, 5, 42, const Row(children: [
          _MiniStat(label: 'SpO₂', value: '98%', color: _blue),
          SizedBox(width: 10),
          _MiniStat(label: 'HRV', value: '64 ms', color: _green),
          SizedBox(width: 10),
          _MiniStat(label: 'Stress', value: 'Low', color: _amber),
        ])),
      ],
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard();

  @override
  Widget build(BuildContext context) {
    return _Glass(
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavePainter(level: 0.6, color: _blue))),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text('1.4 / 2.4 L', style: TextStyle(color: const Color(0xFF31415E), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                const Text('Hydration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const Text('On pace today', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════ Fitness ══
class _FitnessBento extends StatelessWidget {
  const _FitnessBento({required this.delta, required this.focus});
  final double delta;
  final double focus;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _reveal(focus, delta, 3, 18, _Glass(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(
                painter: _ActivityRingsPainter(values: [0.86, 0.72, 1.0], colors: [_coral, _green, _blue]),
                child: const Center(child: Icon(Icons.bolt_rounded, color: _orange, size: 22)),
              ),
            ),
            const SizedBox(width: 18),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RingLegend(color: _coral, label: 'Move', value: '420 kcal'),
                  SizedBox(height: 11),
                  _RingLegend(color: _green, label: 'Exercise', value: '38 min'),
                  SizedBox(height: 11),
                  _RingLegend(color: _blue, label: 'Stand', value: '12 hrs'),
                ],
              ),
            ),
          ]),
        )),
        const SizedBox(height: 12),
        _reveal(focus, delta, 4, 30, SizedBox(
          height: 146,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(flex: 5, child: _StatCard(icon: Icons.favorite_rounded, color: _coral, label: 'Avg HR', value: '123', unit: 'BPM', footer: 'Cardio zone')),
            const SizedBox(width: 12),
            const Expanded(flex: 6, child: _WeeklyCard()),
          ]),
        )),
        const SizedBox(height: 12),
        _reveal(focus, delta, 5, 42, Row(children: [
          _MiniStat(label: 'Distance', value: '5.2 km', color: _blue),
          const SizedBox(width: 10),
          _MiniStat(label: 'Pace', value: "8'30\"", color: _violet),
          const SizedBox(width: 10),
          _MiniStat(label: 'Streak', value: '12 d', color: _orange),
        ])),
        // ignore: prefer_const_constructors
      ],
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return _Glass(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This week', style: TextStyle(color: ec.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          Text('4h 12m', style: TextStyle(color: _ink(context), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                const hs = [0.45, 0.7, 0.4, 0.9, 0.6, 1.0, 0.55];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: FractionallySizedBox(
                      heightFactor: hs[i],
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFFFFB38A), _orange]),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════ Sleep ══
class _SleepBento extends StatelessWidget {
  const _SleepBento({required this.delta, required this.focus});
  final double delta;
  final double focus;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _reveal(focus, delta, 3, 18, _Glass(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const _IconBadge(icon: Icons.nightlight_round, color: _violet),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time asleep', style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('7h 32m', style: TextStyle(color: _ink(context), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                    ],
                  ),
                ),
                const _TrendPill(label: 'Good', color: _green),
              ]),
              const SizedBox(height: 14),
              const SizedBox(height: 48, child: _SleepStages()),
            ],
          ),
        )),
        const SizedBox(height: 12),
        _reveal(focus, delta, 4, 30, SizedBox(
          height: 142,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _StatCard(icon: Icons.dark_mode_rounded, color: _violet, label: 'Deep', value: '1h 21m', footer: '18% of night')),
            const SizedBox(width: 12),
            Expanded(child: _RingStatCard(value: 0.92, score: '92', label: 'Sleep', sub: 'Score', color: _violet)),
          ]),
        )),
        const SizedBox(height: 12),
        _reveal(focus, delta, 5, 42, Row(children: [
          _MiniStat(label: 'REM', value: '1h 05m', color: _blue),
          const SizedBox(width: 10),
          _MiniStat(label: 'Efficiency', value: '92%', color: _green),
          const SizedBox(width: 10),
          _MiniStat(label: 'HR dip', value: '14%', color: _cyan),
        ])),
      ],
    );
  }
}

class _SleepStages extends StatelessWidget {
  const _SleepStages();

  @override
  Widget build(BuildContext context) {
    const heights = [0.35, 0.55, 0.3, 0.7, 1.0, 0.6, 0.85, 0.45, 0.7, 0.4, 0.6, 0.3];
    const deep = [false, true, false, true, true, false, true, false, true, false, true, false];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(heights.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FractionallySizedBox(
              heightFactor: heights[i],
              child: Container(
                decoration: BoxDecoration(
                  color: deep[i] ? _violet : _violet.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ════════════════════════════════════════════════════════ Medication ══
class _MedsBento extends StatelessWidget {
  const _MedsBento({required this.delta, required this.focus});
  final double delta;
  final double focus;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _reveal(focus, delta, 3, 18, _Glass(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's plan", style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('2 of 3 taken', style: TextStyle(color: _ink(context), fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 44, height: 44,
                  child: CustomPaint(
                    painter: _RingPainter(value: 0.98, color: _green, stroke: 5),
                    child: Center(child: Text('98', style: TextStyle(color: _ink(context), fontSize: 12, fontWeight: FontWeight.w800))),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              const _MedRow(name: 'Metformin', dose: '500 mg • 8:00 AM', color: _violet, done: true),
              const SizedBox(height: 10),
              const _MedRow(name: 'Vitamin D', dose: '1000 IU • 9:00 AM', color: _amber, done: true),
              const SizedBox(height: 10),
              const _MedRow(name: 'Omega-3', dose: '1 softgel • 1:00 PM', color: _blue, done: false),
            ],
          ),
        )),
        const SizedBox(height: 12),
        _reveal(focus, delta, 4, 30, SizedBox(
          height: 138,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: _StatCard(icon: Icons.schedule_rounded, color: _blue, label: 'Next dose', value: '1:00', unit: 'PM', footer: 'Omega-3')),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(icon: Icons.event_repeat_rounded, color: _coral, label: 'Refill in', value: '5', unit: 'days', footer: 'Metformin')),
          ]),
        )),
      ],
    );
  }
}

// ── Finale (orbiting constellation) ─────────────────────────────────────
class _FinaleBento extends StatelessWidget {
  const _FinaleBento({required this.delta, required this.focus});
  final double delta;
  final double focus;

  static const _icons = <(IconData, Color)>[
    (Icons.favorite_rounded, _coral),
    (Icons.directions_run_rounded, _orange),
    (Icons.nightlight_round, _violet),
    (Icons.medication_rounded, _blue),
    (Icons.monitor_heart_rounded, _green),
    (Icons.bolt_rounded, _amber),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _reveal(
      focus,
      delta,
      3,
      14,
      Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white.withValues(alpha: isDark ? 0.06 : 0.45), Colors.white.withValues(alpha: 0)]),
                ),
              ),
              const _PulseRing(delayMs: 0),
              for (var i = 0; i < _icons.length; i++)
                _layer(
                  delta,
                  16 + (i.isEven ? 24 : 42),
                  Transform.translate(
                    offset: Offset.fromDirection(-math.pi / 2 + i * (2 * math.pi / _icons.length), 116),
                    child: _FeatureDot(icon: _icons[i].$1, color: _icons[i].$2, delayMs: 150 + i * 110),
                  ),
                ),
              _layer(delta, 10, const _LogoOrb()),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureDot extends StatelessWidget {
  const _FeatureDot({required this.icon, required this.color, required this.delayMs});
  final IconData icon;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 999,
      padding: const EdgeInsets.all(13),
      child: Icon(icon, color: color, size: 22),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
          begin: 0.92,
          end: 1.07,
          duration: 2600.ms,
          delay: delayMs.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ════════════════════════════════════════════════════════ Components ══
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: color, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.unit,
    this.footer,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? unit;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return _Glass(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 16),
            ),
            const Spacer(),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: TextStyle(color: ec.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600))),
          ]),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(value, style: TextStyle(color: _ink(context), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(unit!, style: TextStyle(color: ec.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
          if (footer != null)
            Text(footer!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ec.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RingStatCard extends StatelessWidget {
  const _RingStatCard({required this.value, required this.score, required this.label, required this.sub, required this.color});
  final double value;
  final String score;
  final String label;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return _Glass(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 62, height: 62,
            child: CustomPaint(
              painter: _RingPainter(value: value, color: color, stroke: 6),
              child: Center(child: Text(score, style: TextStyle(color: _ink(context), fontSize: 16, fontWeight: FontWeight.w800))),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: _ink(context), fontSize: 13.5, fontWeight: FontWeight.w700)),
          Text(sub, style: TextStyle(color: ec.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Expanded(
      child: _Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ec.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(color: _ink(context), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Row(children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600))),
      const SizedBox(width: 6),
      Text(value, style: TextStyle(color: _ink(context), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
    ]);
  }
}

class _MedRow extends StatelessWidget {
  const _MedRow({required this.name, required this.dose, required this.color, required this.done});
  final String name;
  final String dose;
  final Color color;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11)),
        child: Icon(Icons.medication_rounded, color: color, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(color: _ink(context), fontSize: 14, fontWeight: FontWeight.w700)),
            Text(dose, style: TextStyle(color: ec.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? _green : Colors.transparent,
          border: Border.all(color: done ? _green : ec.textMuted.withValues(alpha: 0.4), width: 2),
        ),
        child: Icon(Icons.check_rounded, size: 14, color: done ? Colors.white : Colors.transparent),
      ),
    ]);
  }
}

class _FloatChip extends StatelessWidget {
  const _FloatChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(color: _ink(context), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
      ]),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2900.ms, curve: Curves.easeInOut);
  }
}

// ──────────────────────────────────────────────────────── Bottom chrome ──
class _BottomChrome extends StatefulWidget {
  const _BottomChrome({required this.page, required this.count, required this.label, required this.onPrimary});
  final ValueNotifier<double> page;
  final int count;
  final String label;
  final VoidCallback onPrimary;

  @override
  State<_BottomChrome> createState() => _BottomChromeState();
}

class _BottomChromeState extends State<_BottomChrome> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColor = isDark ? Colors.white : const Color(0xFF1C1D21);
    final btnText = isDark ? const Color(0xFF15171C) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dots(page: widget.page, count: widget.count),
          const SizedBox(height: 16),
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onPrimary,
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1,
              duration: EcTokens.motionFast,
              curve: Curves.easeOut,
              child: Container(
                height: 58,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.24), blurRadius: 24, spreadRadius: -6, offset: const Offset(0, 12)),
                  ],
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: EcTokens.motionFast,
                  child: Text(
                    widget.label,
                    key: ValueKey(widget.label),
                    style: TextStyle(color: btnText, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2),
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

class _Dots extends StatelessWidget {
  const _Dots({required this.page, required this.count});
  final ValueNotifier<double> page;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = isDark ? Colors.white : const Color(0xFF3F444D);
    final idle = (isDark ? Colors.white : const Color(0xFF6B7079)).withValues(alpha: 0.3);
    return ValueListenableBuilder<double>(
      valueListenable: page,
      builder: (context, value, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final a = (1 - (value - i).abs()).clamp(0.0, 1.0);
            return AnimatedContainer(
              duration: EcTokens.motionFast,
              width: 7 + 12 * a,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: Color.lerp(idle, active, a), borderRadius: BorderRadius.circular(4)),
            );
          }),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════ Painters ══
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.color, this.stroke = 7});
  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide - stroke) / 2;
    canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = color.withValues(alpha: 0.18));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      value.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}

class _ActivityRingsPainter extends CustomPainter {
  const _ActivityRingsPainter({required this.values, required this.colors});
  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    const gap = 4.0;
    final center = size.center(Offset.zero);
    final maxR = (size.shortestSide - stroke) / 2;
    for (var i = 0; i < values.length; i++) {
      final r = maxR - i * (stroke + gap);
      if (r <= 0) continue;
      final color = colors[i % colors.length];
      canvas.drawCircle(center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = color.withValues(alpha: 0.16));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        values[i].clamp(0.0, 1.0) * 2 * math.pi,
        false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter old) => old.values != values || old.colors != colors;
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);
    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, size.height - ((values[i] - minV) / span) * (size.height - 10) - 5),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final mx = (prev.dx + cur.dx) / 2;
      path.cubicTo(mx, prev.dy, mx, cur.dy, cur.dx, cur.dy);
    }
    final area = Path.from(path)..lineTo(pts.last.dx, size.height)..lineTo(pts.first.dx, size.height)..close();
    canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)]).createShader(Offset.zero & size));
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = color);
    canvas.drawCircle(pts.last, 4.5, Paint()..color = color);
    canvas.drawCircle(pts.last, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.level, required this.color});
  final double level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * (1 - level);
    final path = Path()..moveTo(0, baseY);
    for (var x = 0.0; x <= size.width; x += 1) {
      path.lineTo(x, baseY + math.sin(x / size.width * 2 * math.pi + 0.6) * 5);
    }
    path..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(
      path,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withValues(alpha: 0.8)]).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.level != level || old.color != color;
}
