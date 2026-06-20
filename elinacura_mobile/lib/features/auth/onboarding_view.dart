import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_logo.dart';

/// Metadata for each onboarding step — drives progress chrome and ambient tint.
class _SlideMeta {
  const _SlideMeta({
    required this.label,
    required this.accent,
    required this.icon,
  });

  final String label;
  final Color accent;
  final IconData icon;
}

const _slides = <_SlideMeta>[
  _SlideMeta(label: 'Welcome',     accent: EcTokens.accentBrand,     icon: Icons.spa_rounded),
  _SlideMeta(label: 'Our story',   accent: Color(0xFF1A3C34),        icon: Icons.auto_stories_rounded),
  _SlideMeta(label: 'Medications', accent: Color(0xFF10B981),        icon: Icons.medication_rounded),
  _SlideMeta(label: 'Vitals',      accent: Color(0xFFF43F5E),        icon: Icons.monitor_heart_rounded),
  _SlideMeta(label: 'Scan & care', accent: Color(0xFF3B82F6),        icon: Icons.document_scanner_rounded),
  _SlideMeta(label: 'Get started', accent: Color(0xFF8B5CF6),        icon: Icons.favorite_rounded),
];

typedef _Surf = ({Color top, Color bottom, Color border, Color shadow, Color innerHi});

_Surf _surf(BuildContext c) {
  final dark = Theme.of(c).brightness == Brightness.dark;
  return dark
      ? (
          top: const Color(0xFF1E2738),
          bottom: const Color(0xFF131B28),
          border: Colors.white.withValues(alpha: 0.10),
          shadow: Colors.black.withValues(alpha: 0.60),
          innerHi: Colors.white.withValues(alpha: 0.08),
        )
      : (
          top: Colors.white,
          bottom: const Color(0xFFF7F3EE),
          // Subtle 1px edge so cards read against the warm background.
          border: Colors.black.withValues(alpha: 0.07),
          shadow: Colors.black.withValues(alpha: 0.22),
          innerHi: Colors.white,
        );
}

/// Solid, softly-lit 3D card with layered shadows and a top sheen.
class _Card3D extends StatelessWidget {
  const _Card3D({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius = 26;

  @override
  Widget build(BuildContext context) {
    final s = _surf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.top, s.bottom],
            ),
        border: Border.all(color: borderColor ?? s.border, width: 1),
        boxShadow: [
          // Deep ambient shadow — the primary source of perceived elevation.
          BoxShadow(color: s.shadow, blurRadius: 32, spreadRadius: -5, offset: const Offset(0, 16)),
          // Mid-distance shadow for definition.
          BoxShadow(color: s.shadow.withValues(alpha: 0.55), blurRadius: 10, spreadRadius: -2, offset: const Offset(0, 4)),
          // Contact shadow — tight, crisp base.
          BoxShadow(color: s.shadow.withValues(alpha: 0.12), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: radius * 1.7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [s.innerHi, Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Circular progress ring with rounded cap and a gradient sweep.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.value, required this.color, required this.track, this.stroke = 9});

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (size.shortestSide - stroke) / 2;
    final tp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, r, tp);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color.withValues(alpha: 0.65), color],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      value.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// Smooth sparkline with optional area fill and an end marker.
class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.values, required this.color, this.dot = false});

  final List<double> values;
  final Color color;
  final bool dot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);
    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, size.height - ((values[i] - minV) / span) * (size.height - 8) - 4),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final midX = (prev.dx + cur.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }

    {
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
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    if (dot) {
      canvas.drawCircle(pts.last, 5.5, Paint()..color = color);
      canvas.drawCircle(pts.last, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _debugStart = int.fromEnvironment('OB_PAGE');
  final _pageController = PageController(initialPage: _debugStart);
  int _page = _debugStart;

  int get _count => _slides.length;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: EcTokens.motionBase,
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_page < _count - 1) {
      HapticFeedback.lightImpact();
      _goTo(_page + 1);
    } else {
      HapticFeedback.mediumImpact();
      context.go('/auth');
    }
  }

  void _back() {
    if (_page > 0) {
      HapticFeedback.selectionClick();
      _goTo(_page - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final meta = _slides[_page];
    final isLast = _page == _count - 1;
    final progress = (_page + 1) / _count;

    return EcGlassScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AmbientGlow(accent: meta.accent, page: _page),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: AnimatedOpacity(
                              duration: EcTokens.motionFast,
                              opacity: _page > 0 ? 1 : 0,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_back_rounded),
                                onPressed: _page > 0 ? _back : null,
                              ),
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: EcTokens.motionFast,
                              child: Text(
                                key: ValueKey(meta.label),
                                meta.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ec.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: TextButton(
                              onPressed: () => context.go('/auth'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  color: ec.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SegmentedProgress(
                        progress: progress,
                        accent: meta.accent,
                        page: _page,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _count,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _page = i);
                    },
                    itemBuilder: (context, i) => _slideAt(i, _slides[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _count,
                      (i) => GestureDetector(
                        onTap: () => _goTo(i),
                        child: AnimatedContainer(
                          duration: EcTokens.motionBase,
                          curve: Curves.easeOutCubic,
                          width: _page == i ? 28 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _page == i
                                ? _slides[i].accent
                                : ec.textMuted.withValues(alpha: 0.22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: _ObCta(
                    label: isLast ? 'Create your account' : 'Continue',
                    accent: meta.accent,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slideAt(int i, _SlideMeta meta) {
    switch (i) {
      case 0:  return _IntroSlide(meta: meta);
      case 1:  return _StorySlide(meta: meta);
      case 2:  return _MedsSlide(meta: meta);
      case 3:  return _VitalsSlide(meta: meta);
      case 4:  return _ScanSlide(meta: meta);
      default: return _CareSlide(meta: meta);
    }
  }
}

/// Full-bleed premium CTA — accent gradient with deep colour-matched glow shadow.
class _ObCta extends StatelessWidget {
  const _ObCta({required this.label, required this.accent, required this.onPressed});

  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: EcTokens.motionBase,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EcTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.44),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(EcTokens.radiusMd),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(accent, Colors.white, 0.15)!,
                  accent,
                  Color.lerp(accent, Colors.black, 0.08)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30), width: 1.2),
            ),
            child: SizedBox(
              height: 60,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Very subtle ambient glow — a faint top-right halo that shifts per step.
/// Kept intentionally dim so it tints without washing out the background.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.accent, required this.page});

  final Color accent;
  final int page;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.75, -0.80),
            radius: 0.85,
            colors: [
              accent.withValues(alpha: 0.10),
              accent.withValues(alpha: 0.03),
              Colors.transparent,
            ],
            stops: const [0.0, 0.50, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Segmented top progress bar — one segment per step, filled up to current page.
class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({
    required this.progress,
    required this.accent,
    required this.page,
  });

  final double progress;
  final Color accent;
  final int page;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(_slides.length, (i) {
            final filled = i <= page;
            return Expanded(
              child: AnimatedContainer(
                duration: EcTokens.motionBase,
                curve: Curves.easeOutCubic,
                height: 4,
                margin: EdgeInsets.only(right: i < _slides.length - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: filled
                      ? (i == page ? accent : accent.withValues(alpha: 0.55))
                      : ec.textMuted.withValues(alpha: 0.14),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${page + 1} of ${_slides.length}',
              style: TextStyle(
                color: ec.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared chrome for a feature slide: badge, title, subtitle, then a card mosaic.
class _FeatureSlide extends StatelessWidget {
  const _FeatureSlide({
    required this.meta,
    required this.title,
    required this.subtitle,
    required this.cards,
    this.highlights = const [],
  });

  final _SlideMeta meta;
  final String title;
  final String subtitle;
  final List<Widget> cards;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 4, 26, 8),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepBadge(meta: meta)
              .animate()
              .fadeIn(duration: 320.ms)
              .slideX(begin: -0.08, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: onSurface,
              fontSize: 28,
              height: 1.06,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
          )
              .animate()
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(color: ec.textSecondary, fontSize: 14, height: 1.45),
          ).animate().fadeIn(delay: 120.ms, duration: 420.ms),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < highlights.length; i++)
                  _HighlightPill(label: highlights[i], color: meta.accent, index: i),
              ],
            ),
          ],
          const SizedBox(height: 22),
          ...cards,
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.meta});

  final _SlideMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: meta.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: meta.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: 16, color: meta.accent),
          const SizedBox(width: 8),
          Text(
            meta.label.toUpperCase(),
            style: TextStyle(
              color: meta.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill({required this.label, required this.color, required this.index});

  final String label;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    )
        .animate()
        .fadeIn(delay: (180 + index * 70).ms, duration: 360.ms)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), delay: (180 + index * 70).ms);
  }
}

/// Staggered entrance for mosaic cards.
class _Enter extends StatelessWidget {
  const _Enter({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(delay: (200 + index * 90).ms, duration: 460.ms)
        .slideY(begin: 0.14, end: 0, delay: (200 + index * 90).ms, curve: Curves.easeOutCubic)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), delay: (200 + index * 90).ms);
  }
}

// ----------------------------------------------------------------------------
// Reusable card content pieces
// ----------------------------------------------------------------------------

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text, {this.icon, this.color});
  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color ?? ec.textMuted),
          const SizedBox(width: 6),
        ],
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: color ?? ec.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _StatBig extends StatelessWidget {
  const _StatBig({required this.value, required this.unit, this.color});
  final String value;
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final ec = EcColors.of(context);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: color ?? onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          TextSpan(
            text: ' $unit',
            style: TextStyle(
              color: ec.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 1 — Origin story
// ─────────────────────────────────────────────────────────────────────────────

class _StorySlide extends StatelessWidget {
  const _StorySlide({required this.meta});

  final _SlideMeta meta;

  static const _forestGreen = Color(0xFF1A3C34);

  static const _pillars = [
    (Icons.menu_book_rounded,       'Read every label'),
    (Icons.medication_rounded,      'Knew every pill'),
    (Icons.groups_rounded,          'Kept a care circle'),
    (Icons.favorite_rounded,        'Lived past 100'),
  ];

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chapter badge ────────────────────────────────────────────────
          _StepBadge(meta: meta)
              .animate()
              .fadeIn(duration: 320.ms)
              .slideX(begin: -0.08, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // ── Opening statement ────────────────────────────────────────────
          Text(
            'Elina lived to 102.',
            style: TextStyle(
              color: _forestGreen,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 10),
          Text(
            'The story\nbehind the app.',
            style: TextStyle(
              color: onSurface,
              fontSize: 36,
              height: 1.06,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
          )
              .animate()
              .fadeIn(duration: 380.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
          const SizedBox(height: 20),

          // ── Quote card ───────────────────────────────────────────────────
          _Enter(
            index: 0,
            child: _Card3D(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _forestGreen.withValues(alpha: isDark ? 0.85 : 1.0),
                  const Color(0xFF0F2620),
                ],
              ),
              borderColor: Colors.white.withValues(alpha: 0.10),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded, color: Colors.white.withValues(alpha: 0.40), size: 28),
                  const SizedBox(height: 10),
                  const Text(
                    'She had hypertension, diabetes, and arthritis. She managed them all — with a handwritten notebook, a magnifying glass for labels, and a phone list of everyone who cared about her.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Elina  ·  1922 – 2024',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Bridge paragraph ─────────────────────────────────────────────
          _Enter(
            index: 1,
            child: _Card3D(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 16, color: _forestGreen),
                      const SizedBox(width: 8),
                      Text(
                        'WHY WE BUILT THIS',
                        style: TextStyle(
                          color: _forestGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Most people with chronic conditions are doing what Elina did — manually. Juggling paper, guessing at labels, hoping nothing slips through.',
                    style: TextStyle(
                      color: ec.textSecondary,
                      fontSize: 14.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ElinaCura makes that care automatic, safe, and shared — so you can spend your energy on living.',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Elina's four habits ──────────────────────────────────────────
          _Enter(
            index: 2,
            child: _Card3D(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ELINA\'S FOUR HABITS',
                    style: TextStyle(
                      color: ec.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < _pillars.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _forestGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _forestGreen.withValues(alpha: 0.15)),
                          ),
                          child: Icon(_pillars[i].$1, size: 17, color: _forestGreen),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _pillars[i].$2,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide 0 — Welcome
// ─────────────────────────────────────────────────────────────────────────────

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({required this.meta});

  final _SlideMeta meta;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 660;
        final logoSize = compact ? 110.0 : 128.0;
        final glowSize = compact ? 200.0 : 228.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, compact ? 8 : 20, 28, 16),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - (compact ? 16 : 36)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo + reflection
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: glowSize,
                      height: glowSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            meta.accent.withValues(alpha: 0.20),
                            meta.accent.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.04, 1.04),
                          duration: 2800.ms,
                          curve: Curves.easeInOut,
                        ),
                    // Frosted liquid-glass medallion behind the mark.
                    ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: logoSize * 1.46,
                          height: logoSize * 1.46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.42),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.65),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: meta.accent.withValues(alpha: isDark ? 0.18 : 0.12),
                                blurRadius: 30,
                                spreadRadius: -6,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EcLogo(size: logoSize)
                            .animate()
                            .fadeIn(duration: 700.ms)
                            .scale(
                              begin: const Offset(0.82, 0.82),
                              end: const Offset(1, 1),
                              duration: 800.ms,
                              curve: Curves.easeOutBack,
                            ),
                        ClipRect(
                          child: SizedBox(
                            height: logoSize * 0.26,
                            child: ShaderMask(
                              shaderCallback: (r) => LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
                              ).createShader(r),
                              blendMode: BlendMode.dstIn,
                              child: OverflowBox(
                                maxHeight: logoSize,
                                alignment: Alignment.topCenter,
                                child: Transform(
                                  alignment: Alignment.topCenter,
                                  transform: Matrix4.diagonal3Values(1, -1, 1),
                                  child: EcLogo(size: logoSize),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: compact ? 28 : 36),

                // Hero headline
                Text(
                  'Live like\nElina.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: compact ? 42 : 50,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.6,
                    height: 1.02,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, delay: 200.ms),
                SizedBox(height: compact ? 14 : 18),

                // Mission copy
                Text(
                  'Personalized wellness safety\nfor people with chronic conditions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ec.textSecondary,
                    fontSize: compact ? 15.5 : 17,
                    height: 1.45,
                  ),
                ).animate().fadeIn(delay: 340.ms, duration: 500.ms),
                SizedBox(height: compact ? 8 : 12),

                // Tagline
                Text(
                  'Care that compounds, quietly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ec.textMuted,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 480.ms, duration: 500.ms),
                SizedBox(height: compact ? 28 : 40),

                // Swipe hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe_right_alt_rounded, size: 16, color: ec.textMuted.withValues(alpha: 0.45)),
                    const SizedBox(width: 6),
                    Text(
                      'Swipe to meet Elina',
                      style: TextStyle(
                        color: ec.textMuted.withValues(alpha: 0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 680.ms, duration: 600.ms),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------------
// Slide 1 — Medications
// ----------------------------------------------------------------------------

class _MedsSlide extends StatelessWidget {
  const _MedsSlide({required this.meta});

  final _SlideMeta meta;

  @override
  Widget build(BuildContext context) {
    return _FeatureSlide(
      meta: meta,
      title: 'Never miss\na dose',
      subtitle: 'Continuous cross-checking of your medications, allergies, and conditions. Get flagged before problems happen.',
      highlights: const ['Reminders', 'Adherence', 'Interactions'],
      cards: [
        SizedBox(
          height: 172,
          child: Row(
            children: [
              const Expanded(flex: 41, child: _Enter(index: 0, child: _AdherenceCard())),
              const SizedBox(width: 12),
              const Expanded(flex: 59, child: _Enter(index: 1, child: _TodayMedsCard())),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _Enter(index: 2, child: _ReminderCard()),
      ],
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  const _AdherenceCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _Card3D(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel('This week', icon: Icons.insights_rounded),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(92, 92),
                      painter: _RingPainter(
                        value: 0.94,
                        color: ec.accentBrand,
                        track: ec.textMuted.withValues(alpha: 0.18),
                        stroke: 9,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('94%',
                            style: TextStyle(
                                color: onSurface, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        Text('on track',
                            style: TextStyle(color: ec.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
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

class _TodayMedsCard extends StatelessWidget {
  const _TodayMedsCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return _Card3D(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _CardLabel('Today', icon: Icons.event_available_rounded),
          _MedRow(
            color: const Color(0xFF10B981),
            name: 'Vitamin D3',
            detail: '1 tablet · 8:00 AM',
            done: true,
          ),
          Divider(height: 1, color: ec.textMuted.withValues(alpha: 0.12)),
          _MedRow(
            color: ec.accentBrand,
            name: 'Lisinopril',
            detail: '10 mg · 1:00 PM',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  const _MedRow({required this.color, required this.name, required this.detail, required this.done});
  final Color color;
  final String name;
  final String detail;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(Icons.medication_rounded, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(color: onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(detail, style: TextStyle(color: ec.textMuted, fontSize: 10.5)),
            ],
          ),
        ),
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 20,
          color: done ? const Color(0xFF10B981) : ec.textMuted.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _Card3D(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ec.accentBrand.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_active_rounded, color: ec.accentBrand, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardLabel('Next reminder'),
                const SizedBox(height: 2),
                Text('Metformin · 500 mg',
                    style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          _Chip('6:30 PM', color: ec.accentBrand, icon: Icons.schedule_rounded),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Slide 2 — Vitals
// ----------------------------------------------------------------------------

class _VitalsSlide extends StatelessWidget {
  const _VitalsSlide({required this.meta});

  final _SlideMeta meta;

  @override
  Widget build(BuildContext context) {
    return _FeatureSlide(
      meta: meta,
      title: 'Know your\nnumbers',
      subtitle: 'Track the vitals that matter and watch your trends improve over time.',
      highlights: const ['Heart rate', 'Blood pressure', 'Glucose'],
      cards: [
        const SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(child: _Enter(index: 0, child: _HeartCard())),
              SizedBox(width: 12),
              Expanded(child: _Enter(index: 1, child: _BpCard())),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _Enter(index: 2, child: SizedBox(height: 158, child: _GlucoseCard())),
      ],
    );
  }
}

class _HeartCard extends StatelessWidget {
  const _HeartCard();

  @override
  Widget build(BuildContext context) {
    const rose = Color(0xFFF43F5E);
    return _Card3D(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _CardLabel('Heart rate', icon: Icons.favorite_rounded, color: rose),
          const _StatBig(value: '72', unit: 'bpm'),
          SizedBox(
            height: 30,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparkPainter(
                values: const [60, 64, 58, 70, 66, 74, 68, 72],
                color: rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BpCard extends StatelessWidget {
  const _BpCard();

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF8B5CF6);
    return _Card3D(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _CardLabel('Blood pressure', icon: Icons.monitor_heart_rounded, color: violet),
          _StatBig(value: '118/76', unit: 'mmHg'),
          _Chip('Optimal', color: Color(0xFF10B981), icon: Icons.check_rounded),
        ],
      ),
    );
  }
}

class _GlucoseCard extends StatelessWidget {
  const _GlucoseCard();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);
    return _Card3D(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _CardLabel('Glucose · today', icon: Icons.water_drop_rounded, color: green),
              Spacer(),
              _Chip('In range', color: green),
            ],
          ),
          const SizedBox(height: 10),
          const _StatBig(value: '5.4', unit: 'mmol/L', color: green),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: CustomPaint(
                  painter: _SparkPainter(
                    values: [5.0, 5.3, 6.1, 5.8, 5.2, 4.9, 5.4, 5.4],
                    color: green,
                    dot: true,
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

// ----------------------------------------------------------------------------
// Slide 3 — Scan & nutrition
// ----------------------------------------------------------------------------

class _ScanSlide extends StatelessWidget {
  const _ScanSlide({required this.meta});

  final _SlideMeta meta;

  @override
  Widget build(BuildContext context) {
    return _FeatureSlide(
      meta: meta,
      title: 'Scan.\nStay safe.',
      subtitle: 'Every meal, snack, and grocery product cross-checked against your diagnoses, medications, and allergies — automatically.',
      highlights: const ['Medications', 'Groceries', 'Interactions'],
      cards: [
        const _Enter(index: 0, child: _ScanCard()),
        const SizedBox(height: 12),
        const _Enter(index: 1, child: _GrocerySafetyCard()),
        const SizedBox(height: 12),
        const SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(flex: 56, child: _Enter(index: 2, child: _MacrosCard())),
              SizedBox(width: 12),
              Expanded(flex: 44, child: _Enter(index: 3, child: _CaloriesCard())),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _Enter(index: 4, child: _ScanTestimonialCard()),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.color});
  final Color color;
  final double len = 22;
  final double stroke = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    final w = size.width, h = size.height;
    // top-left
    canvas.drawLine(const Offset(0, 0).translate(0, len), const Offset(0, 0), p);
    canvas.drawLine(const Offset(0, 0), const Offset(0, 0).translate(len, 0), p);
    // top-right
    canvas.drawLine(Offset(w, 0), Offset(w - len, 0), p);
    canvas.drawLine(Offset(w, 0), Offset(w, len), p);
    // bottom-left
    canvas.drawLine(Offset(0, h), Offset(len, h), p);
    canvas.drawLine(Offset(0, h), Offset(0, h - len), p);
    // bottom-right
    canvas.drawLine(Offset(w, h), Offset(w - len, h), p);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), p);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) => old.color != color;
}

class _ScanCard extends StatelessWidget {
  const _ScanCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const green = Color(0xFF10B981);
    return _Card3D(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size(104, 104), painter: _BracketPainter(color: ec.accentBrand)),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ec.accentBrand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.medication_liquid_rounded, size: 34, color: ec.accentBrand),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardLabel('Identified', icon: Icons.check_circle_rounded, color: green),
                const SizedBox(height: 6),
                Text('Lisinopril',
                    style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                Text('10 mg tablet', style: TextStyle(color: ec.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
                _Chip('Added to today', color: ec.accentBrand, icon: Icons.add_task_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrocerySafetyCard extends StatelessWidget {
  const _GrocerySafetyCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const green = Color(0xFF10B981);
    const amber = Color(0xFFF59E0B);
    const forestGreen = Color(0xFF1A3C34);

    return _Card3D(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: forestGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: forestGreen.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_basket_rounded, size: 13, color: forestGreen),
                    const SizedBox(width: 5),
                    Text(
                      'GROCERY SAFETY',
                      style: TextStyle(
                        color: forestGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _Chip('Safe', color: green, icon: Icons.check_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: green.withValues(alpha: 0.18)),
                ),
                child: const Icon(Icons.storefront_rounded, size: 22, color: green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oat Milk — Unsweetened',
                        style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    Text('No interactions with your profile', style: TextStyle(color: ec.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: amber.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: amber.withValues(alpha: 0.18)),
                ),
                child: const Icon(Icons.warning_rounded, size: 22, color: amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grapefruit Juice',
                        style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    Text('Interacts with Lisinopril', style: TextStyle(color: amber, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              _Chip('Caution', color: amber),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanTestimonialCard extends StatelessWidget {
  const _ScanTestimonialCard();

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF1A3C34);
    return _Card3D(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          forestGreen.withValues(alpha: 0.92),
          forestGreen,
        ],
      ),
      borderColor: Colors.white.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: Colors.white.withValues(alpha: 0.50), size: 22),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'REAL USER',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'I finally feel confident grocery shopping alone. The barcode scanner catches things I\'d never notice on a label.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2D6A5A),
                ),
                alignment: Alignment.center,
                child: const Text('MR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text(
                'ElinaCura user · Type 2 diabetes',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  const _MacrosCard();

  @override
  Widget build(BuildContext context) {
    return _Card3D(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _CardLabel('Nutrition', icon: Icons.restaurant_rounded),
          _MacroBar(label: 'Carbs', value: 0.5, color: Color(0xFF3B82F6), amount: '120 g'),
          _MacroBar(label: 'Protein', value: 0.72, color: Color(0xFFC03F0C), amount: '88 g'),
          _MacroBar(label: 'Fat', value: 0.35, color: Color(0xFFF59E0B), amount: '40 g'),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({required this.label, required this.value, required this.color, required this.amount});
  final String label;
  final double value;
  final Color color;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: TextStyle(color: ec.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Container(height: 8, color: ec.textMuted.withValues(alpha: 0.15)),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        colors: [color, Color.lerp(color, Colors.white, 0.25)!],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(amount, style: TextStyle(color: onSurface, fontSize: 10.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  const _CaloriesCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _Card3D(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel('Energy', icon: Icons.local_fire_department_rounded),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(92, 92),
                      painter: _RingPainter(
                        value: 0.62,
                        color: const Color(0xFFF59E0B),
                        track: ec.textMuted.withValues(alpha: 0.18),
                        stroke: 9,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('1,840',
                            style: TextStyle(
                                color: onSurface, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        Text('kcal',
                            style: TextStyle(color: ec.textMuted, fontSize: 9, fontWeight: FontWeight.w600)),
                      ],
                    ),
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

// ----------------------------------------------------------------------------
// Slide 4 — Care circle
// ----------------------------------------------------------------------------

class _CareSlide extends StatelessWidget {
  const _CareSlide({required this.meta});

  final _SlideMeta meta;

  static const _readyItems = [
    'Medication tracking & interaction alerts',
    'Grocery & food safety scanning',
    'Vitals, nutrition & wellness logging',
    'Care circle & emergency SOS',
  ];

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return _FeatureSlide(
      meta: meta,
      title: 'Care,\ntogether',
      subtitle: 'A strong care circle. Emergency is one tap away — with an offline-ready medical ID for first responders.',
      highlights: const ['Caregivers', 'SOS', 'Appointments'],
      cards: [
        const _Enter(index: 0, child: _CareCircleCard()),
        const SizedBox(height: 12),
        const SizedBox(
          height: 152,
          child: Row(
            children: [
              Expanded(child: _Enter(index: 1, child: _EmergencyCard())),
              SizedBox(width: 12),
              Expanded(child: _Enter(index: 2, child: _AppointmentCard())),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Enter(
          index: 3,
          child: EcGlassSurface(
            variant: EcGlassVariant.subtle,
            borderRadius: EcTokens.radiusMd,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOU\'RE READY TO START',
                  style: TextStyle(
                    color: meta.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _readyItems.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: meta.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _readyItems[i],
                          style: TextStyle(
                            color: ec.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CareCircleCard extends StatelessWidget {
  const _CareCircleCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _Card3D(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const _Avatars(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardLabel('Care circle'),
                const SizedBox(height: 2),
                Text('2 caregivers connected',
                    style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: ec.textMuted),
        ],
      ),
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars();

  @override
  Widget build(BuildContext context) {
    final s = _surf(context);
    const data = [
      ('JD', Color(0xFFC03F0C)),
      ('MS', Color(0xFF3B82F6)),
      ('+1', Color(0xFF10B981)),
    ];
    return SizedBox(
      width: 86,
      height: 42,
      child: Stack(
        children: [
          for (var i = 0; i < data.length; i++)
            Positioned(
              left: i * 22.0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data[i].$2,
                  border: Border.all(color: s.top, width: 2.5),
                ),
                alignment: Alignment.center,
                child: Text(data[i].$1,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    return _Card3D(
      padding: const EdgeInsets.all(14),
      borderColor: Colors.white.withValues(alpha: 0.25),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.emergency_rounded, color: Colors.white, size: 30),
          SizedBox(height: 8),
          Text('SOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
          SizedBox(height: 2),
          Text('Hold for help', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return _Card3D(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _CardLabel('Upcoming', icon: Icons.event_rounded),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. Almeida',
                  style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              Text('Cardiology', style: TextStyle(color: ec.textMuted, fontSize: 11)),
            ],
          ),
          const _Chip('Tue · 10:30', color: Color(0xFF3B82F6), icon: Icons.schedule_rounded),
        ],
      ),
    );
  }
}
