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
//  Brushed-silver canvas + solid Continue pill + frosted glass cards + bold
//  top-aligned title/subtitle. The page content uses the hero widgets
//  (vitals card, activity rings, sleep stages, today's plan) with parallax
//  depth and floating accent chips. Colour lives inside the widgets.
// ════════════════════════════════════════════════════════════════════════

// Accent palette — used inside the glass widgets only.
const _coral = Color(0xFFFF6F61);
const _blue = Color(0xFF4B7BFF);
const _green = Color(0xFF34C759);
const _orange = Color(0xFFFF8A3D);
const _violet = Color(0xFF8B6FE8);
const _amber = Color(0xFFFFB23E);

enum _PageKind { intro, wellness, fitness, sleep, meds, finale }

class _OnbPage {
  const _OnbPage({
    required this.kind,
    required this.title,
    this.subtitle = '',
    required this.cta,
  });

  final _PageKind kind;
  final String title;
  final String subtitle;
  final String cta;
}

const _pages = <_OnbPage>[
  _OnbPage(
    kind: _PageKind.intro,
    title: 'The everything\nhealth app',
    cta: 'Continue',
  ),
  _OnbPage(
    kind: _PageKind.wellness,
    title: 'Wellness',
    subtitle: 'Understand the impact of your habits and lifestyle on your health',
    cta: 'Continue',
  ),
  _OnbPage(
    kind: _PageKind.fitness,
    title: 'Fitness',
    subtitle: 'Build, track, and maintain your strength and endurance',
    cta: 'Continue',
  ),
  _OnbPage(
    kind: _PageKind.sleep,
    title: 'Sleep',
    subtitle: 'Discover your sleep patterns to achieve consistent rest',
    cta: 'Continue',
  ),
  _OnbPage(
    kind: _PageKind.meds,
    title: 'Medication',
    subtitle: 'Stay on top of every dose with smart reminders and refill alerts',
    cta: 'Continue',
  ),
  _OnbPage(
    kind: _PageKind.finale,
    title: "You're all set",
    subtitle:
        'Create your free account to bring it all together — your data stays private, encrypted, and yours.',
    cta: 'Get started',
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
                        _OnbPageView(page: _page, index: i, data: _pages[i]),
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

// ───────────────────────────────────────────────────────── Background ──
class _SilverBackground extends StatelessWidget {
  const _SilverBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF181B21), Color(0xFF15171C), Color(0xFF0E0F13)]
              : const [Color(0xFFAEB5C0), Color(0xFFC6CBD3), Color(0xFFE7E9EE)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: _Blob(
              size: 360,
              color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.5),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _Blob(
              size: 320,
              color: (isDark ? Colors.black : const Color(0xFF8C93A0))
                  .withValues(alpha: isDark ? 0.30 : 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────── Page view ──
class _OnbPageView extends StatelessWidget {
  const _OnbPageView({required this.page, required this.index, required this.data});

  final ValueNotifier<double> page;
  final int index;
  final _OnbPage data;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: page,
      builder: (context, _) {
        final delta = page.value - index;
        final focus = (1 - delta.abs()).clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(focus),
          child: data.kind == _PageKind.intro
              ? _IntroContent(delta: delta)
              : _FeatureContent(data: data, delta: delta),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────── Intro ──
class _IntroContent extends StatelessWidget {
  const _IntroContent({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : const Color(0xFF6E747E);
    return Transform.translate(
      offset: Offset(delta * -30, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.06 : 0.55),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Opacity(opacity: isDark ? 0.92 : 0.85, child: const EcLogo(size: 96)),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.04, duration: 3600.ms, curve: Curves.easeInOut),
            const SizedBox(height: 28),
            Text(
              'The everything\nhealth app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────── Feature ──
class _FeatureContent extends StatelessWidget {
  const _FeatureContent({required this.data, required this.delta});
  final _OnbPage data;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFFF4F6F9);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.66)
        : const Color(0xFF565C66);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: Offset(delta * -22, 0),
            child: Text(
              data.title,
              style: TextStyle(
                fontSize: 46,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
                color: titleColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Transform.translate(
            offset: Offset(delta * -36, 0),
            child: Text(
              data.subtitle,
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 340,
                  height: 360,
                  child: _Hero(kind: data.kind, delta: delta),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms);
  }
}

// ═══════════════════════════════════════════════════════════ Glass ══
/// Frosted neutral glass card — white in light, dark glass in dark, with a
/// soft drop shadow so it floats on the silver canvas.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });

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
            color: (isDark ? Colors.black : const Color(0xFF2A2F3A))
                .withValues(alpha: isDark ? 0.34 : 0.14),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: br,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.66),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.85),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

Color _ink(BuildContext c) => Theme.of(c).colorScheme.onSurface;

/// Parallax helper — translates a layer based on swipe [delta].
Widget _layer(double delta, double factor, Widget child) =>
    Transform.translate(offset: Offset(delta * factor, 0), child: child);

// ═══════════════════════════════════════════════════════════ Heroes ══
class _Hero extends StatelessWidget {
  const _Hero({required this.kind, required this.delta});
  final _PageKind kind;
  final double delta;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _PageKind.wellness => _VitalsHero(delta: delta),
      _PageKind.fitness => _FitnessHero(delta: delta),
      _PageKind.sleep => _SleepHero(delta: delta),
      _PageKind.meds => _MedsHero(delta: delta),
      _PageKind.finale => _FinaleHero(delta: delta),
      _PageKind.intro => const SizedBox.shrink(),
    };
  }
}

// ── Wellness / vitals ───────────────────────────────────────────────────
class _VitalsHero extends StatelessWidget {
  const _VitalsHero({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _layer(
          delta,
          20,
          _Glass(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: SizedBox(
              width: 300,
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
                            Text('Heart rate',
                                style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('72',
                                      style: TextStyle(color: _ink(context), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                                  const SizedBox(width: 4),
                                  Text('BPM',
                                      style: TextStyle(color: ec.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 58,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SparkPainter(
                        values: const [58, 64, 60, 72, 67, 80, 74, 88, 79, 72],
                        color: _coral,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      _MiniStat(label: 'SpO₂', value: '98%', color: _blue),
                      SizedBox(width: 12),
                      _MiniStat(label: 'HRV', value: '64 ms', color: _green),
                      SizedBox(width: 12),
                      _MiniStat(label: 'Recovery', value: 'High', color: _violet),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 18,
          right: 4,
          child: _layer(
            delta,
            72,
            const _RingChip(value: 0.94, sub: '94', label: 'Sleep', color: _violet),
          ),
        ),
      ],
    );
  }
}

// ── Fitness ─────────────────────────────────────────────────────────────
class _FitnessHero extends StatelessWidget {
  const _FitnessHero({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _layer(
          delta,
          18,
          _Glass(
            radius: 28,
            padding: const EdgeInsets.all(22),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 102,
                        height: 102,
                        child: CustomPaint(
                          painter: _ActivityRingsPainter(
                            values: [0.86, 0.72, 1.0],
                            colors: [_coral, _green, _blue],
                          ),
                          child: const Center(
                            child: Icon(Icons.bolt_rounded, color: _orange, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RingLegend(color: _coral, label: 'Move', value: '420 kcal'),
                            SizedBox(height: 12),
                            _RingLegend(color: _green, label: 'Exercise', value: '38 min'),
                            SizedBox(height: 12),
                            _RingLegend(color: _blue, label: 'Stand', value: '12 hrs'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 60,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        const heights = [0.5, 0.8, 0.45, 0.95, 0.7, 1.0, 0.6];
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 32 * heights[i],
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Color(0xFFFF9D72), _coral],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(days[i],
                                    style: TextStyle(color: ec.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 6,
          child: _layer(
            delta,
            76,
            const _FloatChip(
              icon: Icons.local_fire_department_rounded,
              label: '12-day streak',
              color: _orange,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sleep ───────────────────────────────────────────────────────────────
class _SleepHero extends StatelessWidget {
  const _SleepHero({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _layer(
          delta,
          20,
          _Glass(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _IconBadge(icon: Icons.nightlight_round, color: _violet),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time asleep',
                                style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('7h 32m',
                                  style: TextStyle(color: _ink(context), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(height: 54, child: _SleepStages()),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      _MiniStat(label: 'Deep', value: '1h 21m', color: _violet),
                      SizedBox(width: 12),
                      _MiniStat(label: 'REM', value: '1h 05m', color: _blue),
                      SizedBox(width: 12),
                      _MiniStat(label: 'Efficiency', value: '92%', color: _green),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 18,
          right: 4,
          child: _layer(
            delta,
            72,
            const _RingChip(value: 0.92, sub: '92', label: 'Sleep', color: _violet),
          ),
        ),
      ],
    );
  }
}

class _SleepStages extends StatelessWidget {
  const _SleepStages();

  @override
  Widget build(BuildContext context) {
    const heights = [0.35, 0.55, 0.3, 0.7, 1.0, 0.6, 0.85, 0.45, 0.65, 0.4];
    const deep = [false, true, false, true, true, false, true, false, true, false];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(heights.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: FractionallySizedBox(
              heightFactor: heights[i],
              child: Container(
                decoration: BoxDecoration(
                  color: deep[i] ? _violet : _violet.withValues(alpha: 0.35),
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

// ── Medication ──────────────────────────────────────────────────────────
class _MedsHero extends StatelessWidget {
  const _MedsHero({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Center(
      child: _layer(
        delta,
        18,
        _Glass(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today's plan",
                              style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('2 of 3 taken',
                              style: TextStyle(color: _ink(context), fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CustomPaint(
                        painter: _RingPainter(value: 0.98, color: _green, stroke: 5),
                        child: Center(
                          child: Text('98',
                              style: TextStyle(color: _ink(context), fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _MedRow(name: 'Metformin', dose: '500 mg • 8:00 AM', color: _violet, done: true),
                const SizedBox(height: 10),
                const _MedRow(name: 'Vitamin D', dose: '1000 IU • 9:00 AM', color: _amber, done: true),
                const SizedBox(height: 10),
                const _MedRow(name: 'Omega-3', dose: '1 softgel • 1:00 PM', color: _blue, done: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Finale (orbiting logo constellation) ────────────────────────────────
class _FinaleHero extends StatelessWidget {
  const _FinaleHero({required this.delta});
  final double delta;

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
    return Center(
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
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.06 : 0.45),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < _icons.length; i++)
              _layer(
                delta,
                18 + (i.isEven ? 26 : 44),
                Transform.translate(
                  offset: Offset.fromDirection(
                    -math.pi / 2 + i * (2 * math.pi / _icons.length),
                    116,
                  ),
                  child: _FeatureDot(
                    icon: _icons[i].$1,
                    color: _icons[i].$2,
                    delayMs: 150 + i * 110,
                  ),
                ),
              ),
            _layer(
              delta,
              12,
              _Glass(
                radius: 999,
                padding: const EdgeInsets.all(26),
                child: const SizedBox(
                  width: 86,
                  height: 86,
                  child: Center(child: EcLogo(size: 84)),
                ),
              ),
            ),
          ],
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
          end: 1.06,
          duration: 2600.ms,
          delay: delayMs.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ════════════════════════════════════════════════════════ Components ══
class _FloatChip extends StatelessWidget {
  const _FloatChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(color: _ink(context), fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
          begin: -5,
          end: 5,
          duration: 2900.ms,
          curve: Curves.easeInOut,
        );
  }
}

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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ec.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _ink(context), fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
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
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ec.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 6),
        Text(value,
            style: TextStyle(color: _ink(context), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      ],
    );
  }
}

class _RingChip extends StatelessWidget {
  const _RingChip({required this.value, required this.sub, required this.label, required this.color});
  final double value;
  final String sub;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return _Glass(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CustomPaint(
              painter: _RingPainter(value: value, color: color, stroke: 5),
              child: Center(
                child: Text(sub,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _ink(context))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: ec.textMuted, fontSize: 10.5, fontWeight: FontWeight.w700)),
              Text('score',
                  style: TextStyle(color: _ink(context), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ],
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
          begin: -6,
          end: 6,
          duration: 3200.ms,
          curve: Curves.easeInOut,
        );
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
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(Icons.medication_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(color: _ink(context), fontSize: 14.5, fontWeight: FontWeight.w700)),
              Text(dose,
                  style: TextStyle(color: ec.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? _green : Colors.transparent,
            border: Border.all(
              color: done ? _green : ec.textMuted.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Icon(Icons.check_rounded, size: 14, color: done ? Colors.white : Colors.transparent),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────── Bottom chrome ──
class _BottomChrome extends StatefulWidget {
  const _BottomChrome({
    required this.page,
    required this.count,
    required this.label,
    required this.onPrimary,
  });

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
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dots(page: widget.page, count: widget.count),
          const SizedBox(height: 18),
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
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.22),
                      blurRadius: 22,
                      spreadRadius: -6,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: EcTokens.motionFast,
                  child: Text(
                    widget.label,
                    key: ValueKey(widget.label),
                    style: TextStyle(
                      color: btnText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
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

class _Dots extends StatelessWidget {
  const _Dots({required this.page, required this.count});
  final ValueNotifier<double> page;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = isDark ? Colors.white : const Color(0xFF4A4F58);
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
              width: 7 + 11 * a,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Color.lerp(idle, active, a),
                borderRadius: BorderRadius.circular(4),
              ),
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
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      value.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
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
    const stroke = 12.0;
    const gap = 5.0;
    final center = size.center(Offset.zero);
    final maxR = (size.shortestSide - stroke) / 2;
    for (var i = 0; i < values.length; i++) {
      final r = maxR - i * (stroke + gap);
      if (r <= 0) continue;
      final color = colors[i % colors.length];
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color.withValues(alpha: 0.16),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        values[i].clamp(0.0, 1.0) * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter old) =>
      old.values != values || old.colors != colors;
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
    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.drawCircle(pts.last, 5, Paint()..color = color);
    canvas.drawCircle(pts.last, 2.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}
