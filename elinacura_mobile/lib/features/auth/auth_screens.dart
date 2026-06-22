import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, PointMode;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/auth/auth_providers.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_logo.dart';
import '../../shared/widgets/ec_widgets.dart';

// ════════════════════════════════════════════════════════════════════════
//  ElinaCura — Auth
//  A premium, cinematic sign-in that speaks the same language as onboarding:
//  a solid canvas with localized accent light and film grain, frosted liquid
//  glass, bold tight typography, and one commanding solid CTA.
// ════════════════════════════════════════════════════════════════════════

const _violet = Color(0xFF8B6FE8);
const _green = Color(0xFF18C77E);
const _red = Color(0xFFFF4D45);

class _P {
  _P(this.dark);
  final bool dark;

  Color get bg => dark ? const Color(0xFF0A0B0F) : const Color(0xFFEDEAE2);
  Color get surface => dark ? const Color(0xFF14161C) : const Color(0xFFF7F5F0);
  Color get ink => dark ? const Color(0xFFF4F5F8) : const Color(0xFF14161C);
  Color get muted => dark ? const Color(0xFF8A90A0) : const Color(0xFF6C7178);
  Color get faint => dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
  Color get hairline => dark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.10);

  static _P of(BuildContext c) => _P(Theme.of(c).brightness == Brightness.dark);
}

// ───────────────────────────────────────────────────── Backdrop + grain ──
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.bg),
        Positioned(
          top: -130,
          right: -100,
          child: _Orb(size: 300, color: accent, opacity: p.dark ? 0.22 : 0.14)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.9, end: 1.08, duration: 4200.ms, curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: 10,
          left: -120,
          child: _Orb(size: 280, color: _violet, opacity: p.dark ? 0.14 : 0.09),
        ),
        const Positioned.fill(child: IgnorePointer(child: _Grain())),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color, required this.opacity});
  final double size;
  final Color color;
  final double opacity;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _Grain extends StatelessWidget {
  const _Grain();
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(child: CustomPaint(painter: _GrainPainter(dark: dark)));
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

// ───────────────────────────────────────────────────── Glass + controls ──
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.padding = const EdgeInsets.all(18), this.tint, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final r = BorderRadius.circular(22);
    var fill = p.dark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.55);
    if (tint != null) fill = Color.alphaBlend(tint!.withValues(alpha: p.dark ? 0.12 : 0.10), fill);
    final border = p.dark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.85);

    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.dark ? 0.26 : 0.08), blurRadius: 34, spreadRadius: -14, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(borderRadius: r, color: fill, border: Border.all(color: border, width: 1.2)),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
    if (onTap != null) body = _Pressable(onTap: onTap, child: body);
    return body;
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.icon, this.onPressed, this.loading = false, this.accent = _violet});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final bg = p.dark ? Colors.white : const Color(0xFF14161C);
    final fg = p.dark ? const Color(0xFF0A0B0F) : Colors.white;
    return _Pressable(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: p.dark ? 0.42 : 0.30), blurRadius: 28, spreadRadius: -10, offset: const Offset(0, 12)),
            BoxShadow(color: Colors.black.withValues(alpha: p.dark ? 0.30 : 0.12), blurRadius: 18, spreadRadius: -12, offset: const Offset(0, 10)),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(fg)))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                  if (icon != null) ...[const SizedBox(width: 9), Icon(icon, color: fg, size: 20)],
                ],
              ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, this.icon, this.onPressed});
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return _Pressable(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: p.dark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.hairline),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: p.ink, size: 22), const SizedBox(width: 8)],
            Text(label, style: TextStyle(color: p.ink, fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accent,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accent;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    OutlineInputBorder b(Color c, [double w = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: accent,
      style: TextStyle(color: p.ink, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: accent, fontWeight: FontWeight.w700),
        prefixIcon: Icon(icon, size: 20, color: p.muted),
        suffixIcon: trailing,
        filled: true,
        fillColor: p.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.65),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: b(p.hairline),
        border: b(p.hairline),
        focusedBorder: b(accent, 1.6),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════ AuthScreen ══
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _showPassword = false;
  bool _loading = false;
  String? _error;
  UserRole? _selectedRole;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          displayName: _nameController.text,
        );
      } else {
        await auth.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      }
      _routeAfterAuth();
    } catch (e) {
      if (mounted) setState(() => _error = _pretty(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      _routeAfterAuth();
    } catch (e) {
      if (mounted) setState(() => _error = _pretty(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guest() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      _routeAfterAuth();
    } catch (e) {
      if (mounted) setState(() => _error = _pretty(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apple() async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithApple();
      _routeAfterAuth();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled && mounted) {
        setState(() => _error = e.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _pretty(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _pretty(Object e) {
    final s = e.toString().replaceFirst('Exception: ', '');
    if (s.length > 160) return '${s.substring(0, 157)}…';
    return s;
  }

  void _routeAfterAuth() {
    final role = _selectedRole ?? UserRole.patient;
    ref.read(userRoleProvider.notifier).state = role;
    if (role == UserRole.caregiver) {
      ref.read(shellModeProvider.notifier).state = AppShellMode.caregiver;
      context.go('/caregiver-picker');
    } else {
      ref.read(shellModeProvider.notifier).state = AppShellMode.patient;
      context.go('/dashboard');
    }
  }

  Color get _accent => _selectedRole == UserRole.caregiver ? _green : _violet;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Backdrop(accent: _accent),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim), child: child),
              ),
              child: _selectedRole == null ? _buildRolePicker() : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: choose how you'll use the app ───────────────────────────────
  Widget _buildRolePicker() {
    final p = _P.of(context);
    return SingleChildScrollView(
      key: const ValueKey('role'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Center(child: _BrandMark())
                .animate()
                .fadeIn(duration: 560.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 26),
            _revealOrder(
              0,
              Row(children: [
                Container(width: 18, height: 2, color: _violet),
                const SizedBox(width: 9),
                Text('WELCOME', style: TextStyle(color: _violet, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.6)),
              ]),
            ),
            const SizedBox(height: 12),
            _revealOrder(
              1,
              Text(
                'Care, made personal',
                style: TextStyle(color: p.ink, fontSize: 34, height: 1.04, fontWeight: FontWeight.w800, letterSpacing: -1.4),
              ),
            ),
            const SizedBox(height: 10),
            _revealOrder(
              2,
              Text(
                'Tune ElinaCura around how you show up for health each day.',
                style: TextStyle(color: p.muted, fontSize: 15, height: 1.45, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            _revealOrder(
              3,
              Text('CONTINUE AS', style: TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
            ),
            const SizedBox(height: 12),
            _revealOrder(
              4,
              _RoleCard(
                icon: Icons.self_improvement_rounded,
                title: 'Manage my health',
                subtitle: 'A private command center for medications, vitals, nutrition and safety.',
                accent: _violet,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = UserRole.patient);
                },
              ),
            ),
            const SizedBox(height: 14),
            _revealOrder(
              5,
              _RoleCard(
                icon: Icons.diversity_1_rounded,
                title: 'Care for someone I love',
                subtitle: 'See the right updates, coordinate routines and step in when it matters.',
                accent: _green,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRole = UserRole.caregiver);
                },
              ),
            ),
            const SizedBox(height: 26),
            const Center(child: _TrustRow()).animate().fadeIn(delay: 640.ms, duration: 500.ms),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _revealOrder(int order, Widget child) {
    return child
        .animate()
        .fadeIn(delay: (140 + order * 90).ms, duration: 420.ms)
        .slideY(begin: 0.12, end: 0, delay: (140 + order * 90).ms, curve: Curves.easeOutCubic);
  }

  // ── Step 2: sign in / create account ────────────────────────────────────
  Widget _buildForm() {
    final p = _P.of(context);
    final isCaregiver = _selectedRole == UserRole.caregiver;
    final showApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 18, 0),
          child: Row(
            children: [
              _Pressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedRole = null;
                    _error = null;
                  });
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.surface, border: Border.all(color: p.hairline)),
                  child: Icon(Icons.arrow_back_rounded, color: p.ink, size: 20),
                ),
              ),
              const Spacer(),
              _RoleChip(
                icon: isCaregiver ? Icons.diversity_1_rounded : Icons.self_improvement_rounded,
                label: isCaregiver ? 'Caregiver' : 'Personal',
                accent: _accent,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroPanel(isSignUp: _isSignUp, isCaregiver: isCaregiver, accent: _accent)
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.06, end: 0),
                const SizedBox(height: 20),
                _AuthToggle(
                  isSignUp: _isSignUp,
                  accent: _accent,
                  onChanged: (v) {
                    if (v == _isSignUp) return;
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isSignUp = v;
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _Glass(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        child: _isSignUp
                            ? Column(
                                children: [
                                  _Field(
                                    controller: _nameController,
                                    label: 'Full name',
                                    icon: Icons.badge_outlined,
                                    accent: _accent,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      _Field(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.alternate_email_rounded,
                        accent: _accent,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        accent: _accent,
                        obscure: !_showPassword,
                        trailing: IconButton(
                          splashRadius: 20,
                          icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: p.muted),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 20),
                      _PrimaryButton(
                        label: _isSignUp ? 'Create account' : 'Sign in',
                        icon: Icons.arrow_forward_rounded,
                        loading: _loading,
                        accent: _accent,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.06, end: 0, delay: 80.ms),
                const SizedBox(height: 20),
                _OrDivider(label: _isSignUp ? 'or start faster with' : 'or continue with'),
                const SizedBox(height: 16),
                if (showApple) ...[
                  _AppleButton(onPressed: _loading ? null : _apple),
                  const SizedBox(height: 10),
                ],
                _GhostButton(label: 'Continue with Google', icon: Icons.g_mobiledata_rounded, onPressed: _loading ? null : _google),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _guest,
                    child: Text('Explore as a guest', style: TextStyle(color: p.muted, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────── Brand ──
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return SizedBox(
      height: 170,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_violet.withValues(alpha: p.dark ? 0.34 : 0.22), _violet.withValues(alpha: 0)]),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 0.92, end: 1.06, duration: 3200.ms, curve: Curves.easeInOut),
          const Positioned(right: 26, top: 28, child: _Signal(icon: Icons.shield_rounded, color: _violet, label: 'Private')),
          const Positioned(left: 24, bottom: 26, child: _Signal(icon: Icons.favorite_rounded, color: _green, label: 'Care')),
          // frosted glass disc + logo
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
                    color: p.dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.40),
                    border: Border.all(color: p.dark ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.85), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: const EcLogo(size: 86),
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.03, duration: 3400.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.hairline),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.dark ? 0.3 : 0.08), blurRadius: 16, spreadRadius: -6, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: p.ink, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();
  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    Widget item(IconData i, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 13, color: p.muted),
            const SizedBox(width: 6),
            Text(t, style: TextStyle(color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        item(Icons.lock_rounded, 'Private by design'),
        item(Icons.cloud_done_rounded, 'Encrypted sync'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────── Role card ──
class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.accent, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return _Glass(
      onTap: onTap,
      tint: accent,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: accent.withValues(alpha: 0.18),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(color: p.ink, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.4)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.14), border: Border.all(color: accent.withValues(alpha: 0.22))),
            child: Icon(Icons.arrow_forward_rounded, color: accent, size: 17),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.icon, required this.label, required this.accent});
  final IconData icon;
  final String label;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(label.toUpperCase(), style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.isSignUp, required this.isCaregiver, required this.accent});
  final bool isSignUp;
  final bool isCaregiver;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return _Glass(
      tint: accent,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(isCaregiver ? Icons.diversity_1_rounded : Icons.self_improvement_rounded, color: accent, size: 23),
              ),
              const Spacer(),
              Text(
                isSignUp ? 'NEW CARE SPACE' : 'SECURE RETURN',
                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              isSignUp ? 'Create your account' : 'Welcome back',
              key: ValueKey(isSignUp),
              style: TextStyle(color: p.ink, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.04),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSignUp
                ? 'Set up a calm, private place to coordinate your care from day one.'
                : 'Sign in to continue your routines, insights and care circle.',
            style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────── Sign in / Create toggle ──
class _AuthToggle extends StatelessWidget {
  const _AuthToggle({required this.isSignUp, required this.accent, required this.onChanged});
  final bool isSignUp;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: p.faint, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.hairline)),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: isSignUp ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: segW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: accent,
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.34), blurRadius: 14, spreadRadius: -2, offset: const Offset(0, 4))],
                  ),
                ),
              ),
              Row(
                children: [
                  _seg('Sign in', !isSignUp, p, () => onChanged(false)),
                  _seg('Create account', isSignUp, p, () => onChanged(true)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _seg(String label, bool active, _P p, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              color: active ? Colors.white : p.muted,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;
    return _Pressable(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.22), blurRadius: 16, spreadRadius: -6, offset: const Offset(0, 6))],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apple, color: fg, size: 22),
            const SizedBox(width: 8),
            Text('Continue with Apple', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: -0.2)),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final line = Expanded(child: Container(height: 1, color: p.hairline));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        line,
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: _red, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).shakeX(amount: 2, duration: 320.ms);
  }
}

// ─────────────────────────────────────────────────── Biometric gate ──
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate> {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _maybeUnlock();
  }

  Future<void> _maybeUnlock() async {
    final enabled = ref.read(biometricEnabledProvider);
    if (!enabled) {
      if (mounted) setState(() => _unlocked = true);
      return;
    }
    final auth = LocalAuthentication();
    final can = await auth.canCheckBiometrics;
    if (!can) {
      if (mounted) setState(() => _unlocked = true);
      return;
    }
    final ok = await auth.authenticate(
      localizedReason: 'Unlock ElinaCura',
      options: const AuthenticationOptions(biometricOnly: false),
    );
    if (ok && mounted) setState(() => _unlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    final p = _P.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Backdrop(accent: _violet),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _Glass(
                  padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _violet.withValues(alpha: p.dark ? 0.3 : 0.18), blurRadius: 34, spreadRadius: -6)],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.dark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.4),
                                border: Border.all(color: p.dark ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.85), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: const EcLogo(size: 72),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text('Unlock ElinaCura', style: TextStyle(color: p.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                      const SizedBox(height: 8),
                      Text(
                        'Use Face ID or your passcode to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 26),
                      _PrimaryButton(label: 'Unlock', icon: Icons.fingerprint_rounded, onPressed: _maybeUnlock),
                    ],
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

// ─────────────────────────────────────────────────── Caregiver picker ──
class CaregiverProfilePickerScreen extends ConsumerWidget {
  const CaregiverProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(caregiverAccessProvider);
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Select patient', showEmergency: false),
      body: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EcErrorState(
          message: 'Could not load linked profiles',
          onRetry: () => ref.invalidate(caregiverAccessProvider),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EcEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No linked patients yet',
              message:
                  'Ask the person you care for to invite you from Connections before opening caregiver mode.',
            );
          }
          if (entries.length == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/caregiver/${entries.first.profileId}');
            });
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) {
                return const EcScreenHero(
                  eyebrow: 'Caregiver access',
                  title: 'Choose a profile',
                  subtitle:
                      'Open the care view for the person you are supporting today.',
                  icon: Icons.diversity_1_rounded,
                );
              }
              final entry = entries[i - 1];
              return EcCard(
                onTap: () => context.go('/caregiver/${entry.profileId}'),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Patient ${entry.profileId.substring(0, 8)}…',
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
