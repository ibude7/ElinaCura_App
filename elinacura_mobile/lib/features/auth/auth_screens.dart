import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_logo.dart';
import '../../shared/widgets/ec_widgets.dart';

// ════════════════════════════════════════════════════════════════════════
//  ElinaCura — Auth
//  Editorial, solid-surface sign-in. No gradients — just precise type,
//  restrained accent color, hairline borders, and confident spacing.
// ════════════════════════════════════════════════════════════════════════

class _AuthPalette {
  const _AuthPalette(this.dark);
  final bool dark;

  Color get bg => dark ? const Color(0xFF0A0B0F) : const Color(0xFFEDEAE2);
  Color get surface => dark ? const Color(0xFF14161C) : const Color(0xFFFCFAF8);
  Color get surfaceRaised => dark ? const Color(0xFF1A1D26) : const Color(0xFFFFFFFF);
  Color get ink => dark ? const Color(0xFFF4F5F8) : const Color(0xFF14161C);
  Color get muted => dark ? const Color(0xFF8A90A0) : const Color(0xFF6C7178);
  Color get faint => dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04);
  Color get hairline => dark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08);
  Color get shadow => dark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06);

  static _AuthPalette of(BuildContext c) =>
      _AuthPalette(Theme.of(c).brightness == Brightness.dark);
}

Color _roleAccent(UserRole? role, BuildContext context) {
  final ec = EcColors.of(context);
  return role == UserRole.caregiver ? ec.accentMint : ec.accentBrand;
}

// ──────────────────────────────────────────────────────── Backdrop ──
class _AuthCanvas extends StatelessWidget {
  const _AuthCanvas({this.accent});
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    final wash = accent ?? EcColors.of(context).accentBrand;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.bg),
        if (accent != null)
          Positioned(
            top: -48,
            right: -64,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: wash.withValues(alpha: p.dark ? 0.10 : 0.07),
                  borderRadius: BorderRadius.circular(48),
                ),
              ),
            ),
          ),
        const Positioned.fill(child: IgnorePointer(child: _Grain())),
      ],
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
    final rnd = math.Random(11);
    final n = (size.width * size.height / 1100).clamp(280, 2800).toInt();
    final paint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: dark ? 0.018 : 0.016);
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
    ];
    canvas.drawPoints(PointMode.points, pts, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) => old.dark != dark;
}

// ──────────────────────────────────────────────────────── Primitives ──
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
        scale: _down ? 0.985 : 1,
        duration: EcTokens.motionInstant,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(EcTokens.radiusCard),
        border: Border.all(color: p.hairline),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    required this.accent,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return _Pressable(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: onPressed == null && !loading ? accent.withValues(alpha: 0.45) : accent,
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, this.onPressed, this.leading});
  final String label;
  final Widget? leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return _Pressable(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
          border: Border.all(color: p.hairline),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Text(
              label,
              style: TextStyle(
                color: p.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.15,
              ),
            ),
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
    final p = _AuthPalette.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(EcTokens.radiusSm),
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
        labelStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w500, fontSize: 14),
        floatingLabelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: 20, color: p.muted),
        suffixIcon: trailing,
        filled: true,
        fillColor: p.faint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: border(p.hairline),
        border: border(p.hairline),
        focusedBorder: border(accent, 1.5),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.controller});
  final TextEditingController controller;

  int _score(String pw) {
    if (pw.isEmpty) return 0;
    var s = 0;
    if (pw.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(pw) && RegExp(r'[a-z]').hasMatch(pw)) s++;
    if (RegExp(r'[0-9]').hasMatch(pw) || RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) s++;
    return s.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pw = controller.text;
        if (pw.isEmpty) return const SizedBox.shrink();
        final score = _score(pw);
        const colors = [
          EcTokens.statusCritical,
          EcTokens.statusCritical,
          EcTokens.statusCaution,
          EcTokens.statusPositive,
        ];
        const labels = ['Keep going', 'Weak', 'Good', 'Strong'];
        final color = colors[score];
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: EcTokens.motionFast,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i < score ? color : p.faint,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Password strength · ${labels[score]}',
                style: TextStyle(
                  color: score == 0 ? p.muted : color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        );
      },
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

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Enter your email above, then tap reset.')));
      return;
    }
    HapticFeedback.selectionClick();
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Reset link sent to $email')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_pretty(e))));
    }
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

  Color get _accent => _roleAccent(_selectedRole, context);

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AuthCanvas(accent: _selectedRole != null ? _accent : null),
          AnimatedSwitcher(
            duration: EcTokens.motionBase,
            switchInCurve: EcTokens.curveEmphasized,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _selectedRole == null ? _buildRolePicker() : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePicker() {
    final p = _AuthPalette.of(context);
    final ec = EcColors.of(context);
    final pad = MediaQuery.paddingOf(context);
    return SafeArea(
      key: const ValueKey('role'),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, pad.top > 0 ? 8 : 20, 24, pad.bottom + 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandLockup(),
            const SizedBox(height: 36),
            Text(
              'Care, made\npersonal.',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: p.ink,
                    height: 1.05,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose how you show up for health. We\'ll tune ElinaCura around you.',
              style: TextStyle(
                color: p.muted,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'CONTINUE AS',
              style: TextStyle(
                color: p.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.self_improvement_rounded,
              title: 'Manage my health',
              subtitle: 'Medications, vitals, nutrition and safety — in one private command center.',
              accent: ec.accentBrand,
              features: const ['Medications', 'Vitals', 'Nutrition'],
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedRole = UserRole.patient);
              },
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.diversity_1_rounded,
              title: 'Care for someone I love',
              subtitle: 'Coordinate routines, see the right updates, and step in when it matters.',
              accent: ec.accentMint,
              features: const ['Live updates', 'Coordinate', 'SOS alerts'],
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedRole = UserRole.caregiver);
              },
            ),
            const SizedBox(height: 28),
            const Center(child: _TrustRow()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final p = _AuthPalette.of(context);
    final pad = MediaQuery.paddingOf(context);
    final isCaregiver = _selectedRole == UserRole.caregiver;
    final showApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    return SafeArea(
      key: const ValueKey('form'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
            child: SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _IconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedRole = null;
                          _error = null;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EcLogo(size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ElinaCura',
                        style: TextStyle(
                          color: p.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _RoleChip(
                      icon: isCaregiver ? Icons.diversity_1_rounded : Icons.self_improvement_rounded,
                      label: isCaregiver ? 'Caregiver' : 'Personal',
                      accent: _accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 16, 24, pad.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: EcTokens.motionFast,
                    child: Text(
                      _isSignUp ? 'Create your account' : 'Welcome back',
                      key: ValueKey(_isSignUp),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: p.ink),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUp
                        ? 'A calm, private home for your care.'
                        : 'Continue your routines and care circle.',
                    style: TextStyle(color: p.muted, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  _SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSize(
                          duration: EcTokens.motionBase,
                          curve: EcTokens.curveEmphasized,
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
                            icon: Icon(
                              _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 20,
                              color: p.muted,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: 10),
                          _PasswordStrength(controller: _passwordController),
                        ],
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
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading ? null : _forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: _accent,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OrDivider(label: _isSignUp ? 'or start faster with' : 'or continue with'),
                  const SizedBox(height: 16),
                  if (showApple) ...[
                    _AppleButton(onPressed: _loading ? null : _apple),
                    const SizedBox(height: 10),
                  ],
                  _OutlineButton(
                    label: 'Continue with Google',
                    leading: _GoogleMark(color: p.ink),
                    onPressed: _loading ? null : _google,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : _guest,
                      child: Text(
                        'Explore as a guest',
                        style: TextStyle(color: p.muted, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By continuing you agree to our Terms & Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.muted, fontSize: 11, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────── Brand ──
class _BrandLockup extends StatelessWidget {
  const _BrandLockup();
  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    final ec = EcColors.of(context);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: ec.accentBrand.withValues(alpha: p.dark ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ec.accentBrand.withValues(alpha: 0.22)),
          ),
          alignment: Alignment.center,
          child: const EcLogo(size: 32),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ELINACURA',
              style: TextStyle(
                color: p.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Health OS',
              style: TextStyle(
                color: p.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: TextStyle(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: EcTokens.fontFamily,
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          border: Border.all(color: p.hairline),
        ),
        child: Icon(icon, color: p.ink, size: 20),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();
  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    Widget item(IconData i, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 13, color: p.muted),
            const SizedBox(width: 6),
            Text(t, style: TextStyle(color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 8,
      children: [
        item(Icons.lock_rounded, 'Private by design'),
        item(Icons.verified_user_outlined, 'Encrypted sync'),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.features = const [],
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return _Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: BorderRadius.circular(EcTokens.radiusCard),
          border: Border.all(color: p.hairline),
          boxShadow: [
            BoxShadow(color: p.shadow, blurRadius: 20, spreadRadius: -6, offset: const Offset(0, 6)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(EcTokens.radiusCard)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: accent.withValues(alpha: 0.12),
                        ),
                        child: Icon(icon, color: accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: p.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: p.muted,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (features.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [for (final f in features) _FeatureChip(label: f, accent: accent)],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: p.muted, size: 18),
                    ],
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

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.accent});
  final String label;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: accent, fontSize: 10.5, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(EcTokens.radiusFull),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AuthToggle extends StatelessWidget {
  const _AuthToggle({required this.isSignUp, required this.accent, required this.onChanged});
  final bool isSignUp;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = _AuthPalette.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.faint,
        borderRadius: BorderRadius.circular(EcTokens.radiusSm),
        border: Border.all(color: p.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = c.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: EcTokens.motionBase,
                curve: EcTokens.curveEmphasized,
                alignment: isSignUp ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: segW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
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

  Widget _seg(String label, bool active, _AuthPalette p, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: EcTokens.motionFast,
            style: TextStyle(
              color: active ? Colors.white : p.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              letterSpacing: -0.15,
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
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(EcTokens.radiusMd),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apple, color: fg, size: 22),
            const SizedBox(width: 8),
            Text(
              'Continue with Apple',
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: -0.15),
            ),
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
    final p = _AuthPalette.of(context);
    final line = Expanded(child: Container(height: 1, color: p.hairline));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: TextStyle(color: p.muted, fontSize: 12, fontWeight: FontWeight.w500)),
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
        color: EcTokens.statusCritical.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(EcTokens.radiusSm),
        border: Border.all(color: EcTokens.statusCritical.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: EcTokens.statusCritical),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: EcTokens.statusCritical,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
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
    final p = _AuthPalette.of(context);
    final ec = EcColors.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AuthCanvas(accent: ec.accentBrand),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: ec.accentBrand.withValues(alpha: p.dark ? 0.14 : 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ec.accentBrand.withValues(alpha: 0.22)),
                        ),
                        alignment: Alignment.center,
                        child: const EcLogo(size: 44),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Unlock ElinaCura',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: p.ink),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use Face ID or your passcode to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.muted, fontSize: 14, height: 1.45),
                      ),
                      const SizedBox(height: 28),
                      _PrimaryButton(
                        label: 'Unlock',
                        icon: Icons.fingerprint_rounded,
                        accent: ec.accentBrand,
                        onPressed: _maybeUnlock,
                      ),
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
