import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

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
    setState(() { _loading = true; _error = null; });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isSignUp) {
        await auth.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          displayName: _nameController.text,
        );
      } else {
        await auth.signInWithEmail(_emailController.text, _passwordController.text);
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
    setState(() { _loading = true; _error = null; });
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
    setState(() { _loading = true; _error = null; });
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
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithApple();
      _routeAfterAuth();
    } on SignInWithAppleAuthorizationException catch (e) {
      // User dismissed the Apple sheet — not an error worth surfacing.
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

  Color get _accent => _selectedRole == UserRole.caregiver
      ? const Color(0xFF1A3C34)
      : EcColors.of(context).accentBrand;

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AuthGlow(accent: _accent),
          SafeArea(
            child: AnimatedSwitcher(
              duration: EcTokens.motionBase,
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: _selectedRole == null ? _buildRolePicker() : _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: choose how you'll use the app ─────────────────────────────────
  Widget _buildRolePicker() {
    final ec = EcColors.of(context);
    return SingleChildScrollView(
      key: const ValueKey('role'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const _BrandHero()
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.86, 0.86), curve: Curves.easeOutBack, duration: 700.ms),
            const SizedBox(height: 30),
            Text(
              'Welcome to ElinaCura',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
                height: 1.05,
              ),
            ).animate().fadeIn(delay: 160.ms, duration: 450.ms).slideY(begin: 0.12, end: 0, delay: 160.ms),
            const SizedBox(height: 12),
            Text(
              'A century of intentional living, distilled into one calm, careful companion.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ec.textSecondary, fontSize: 14.5, height: 1.5),
            ).animate().fadeIn(delay: 260.ms, duration: 450.ms),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'HOW WILL YOU USE THE APP?',
                style: TextStyle(
                  color: ec.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ).animate().fadeIn(delay: 340.ms, duration: 350.ms),
            _RoleCard(
              icon: Icons.self_improvement_rounded,
              title: 'Manage my health',
              subtitle: 'Track meds, vitals, scans and appointments',
              accent: ec.accentBrand,
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedRole = UserRole.patient); },
            ).animate().fadeIn(delay: 400.ms, duration: 420.ms).slideY(begin: 0.14, end: 0, delay: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 14),
            _RoleCard(
              icon: Icons.diversity_1_rounded,
              title: 'Care for someone I love',
              subtitle: 'Stay connected as a family caregiver',
              accent: const Color(0xFF1A3C34),
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedRole = UserRole.caregiver); },
            ).animate().fadeIn(delay: 480.ms, duration: 420.ms).slideY(begin: 0.14, end: 0, delay: 480.ms, curve: Curves.easeOut),
            const SizedBox(height: 28),
            const _TrustRow().animate().fadeIn(delay: 600.ms, duration: 500.ms),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Step 2: sign in / create account ──────────────────────────────────────
  Widget _buildForm() {
    final ec = EcColors.of(context);
    final isCaregiver = _selectedRole == UserRole.caregiver;
    final showApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () { HapticFeedback.selectionClick(); setState(() { _selectedRole = null; _error = null; }); },
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EcLogo(size: 64).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 18),
                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp
                      ? 'A few seconds to set up your care space.'
                      : 'Pick up right where you left off.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ec.textSecondary, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 22),
                _AuthToggle(
                  isSignUp: _isSignUp,
                  accent: _accent,
                  onChanged: (v) {
                    if (v == _isSignUp) return;
                    HapticFeedback.selectionClick();
                    setState(() { _isSignUp = v; _error = null; });
                  },
                ),
                const SizedBox(height: 18),
                EcGlassSurface(
                  variant: EcGlassVariant.elevated,
                  borderRadius: EcTokens.radiusGlass,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSize(
                        duration: EcTokens.motionBase,
                        curve: Curves.easeOutCubic,
                        child: _isSignUp
                            ? Column(
                                children: [
                                  _AuthField(
                                    controller: _nameController,
                                    label: 'Full name',
                                    icon: Icons.badge_outlined,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      _AuthField(
                        controller: _emailController,
                        label: 'Email address',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),
                      _AuthField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: !_showPassword,
                        trailing: IconButton(
                          splashRadius: 20,
                          icon: Icon(
                            _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                            color: ec.textMuted,
                          ),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 20),
                      EcGlassButton(
                        label: _isSignUp ? 'Create account' : 'Sign in',
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.06, end: 0, delay: 80.ms),
                const SizedBox(height: 20),
                const _OrDivider(),
                const SizedBox(height: 16),
                if (showApple) ...[
                  _AppleButton(onPressed: _loading ? null : _apple),
                  const SizedBox(height: 10),
                ],
                EcGlassButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  outlined: true,
                  onPressed: _loading ? null : _google,
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _guest,
                    child: Text(
                      'Explore as a guest',
                      style: TextStyle(color: ec.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ec.textMuted, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand hero — logo on a soft glass medallion with a breathing glow.
// ─────────────────────────────────────────────────────────────────────────────
class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 188,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 188,
            height: 188,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ec.accentBrand.withValues(alpha: 0.22),
                  ec.accentBrand.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.94, 0.94), end: const Offset(1.06, 1.06), duration: 3000.ms, curve: Curves.easeInOut),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.white).withValues(alpha: isDark ? 0.08 : 0.5),
                  border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.7), width: 1.2),
                ),
              ),
            ),
          ),
          const EcLogo(size: 104),
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  const _AuthGlow({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.85),
            radius: 1.0,
            colors: [
              accent.withValues(alpha: 0.12),
              accent.withValues(alpha: 0.03),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusLg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withValues(alpha: 0.22), accent.withValues(alpha: 0.10)],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 15.5, letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: ec.textSecondary, fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
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
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sign in / Create account segmented toggle
// ─────────────────────────────────────────────────────────────────────────────
class _AuthToggle extends StatelessWidget {
  const _AuthToggle({required this.isSignUp, required this.accent, required this.onChanged});
  final bool isSignUp;
  final Color accent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final glass = EcGlass.of(context);
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: glass.fillSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glass.border.withValues(alpha: 0.7)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final segW = (c.maxWidth - 0) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: EcTokens.motionBase,
                curve: Curves.easeOutCubic,
                alignment: isSignUp ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: segW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [accent, Color.lerp(accent, Colors.white, 0.12)!],
                    ),
                    boxShadow: [
                      BoxShadow(color: accent.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _seg('Sign in', !isSignUp, ec, () => onChanged(false)),
                  _seg('Create account', isSignUp, ec, () => onChanged(true)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _seg(String label, bool active, EcColors ec, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: EcTokens.motionFast,
            style: TextStyle(
              color: active ? Colors.white : ec.textSecondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Glass text field
// ─────────────────────────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: ec.textMuted),
        suffixIcon: trailing,
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
    // Apple HIG: black button on light surfaces, white on dark surfaces.
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(EcTokens.radiusMd),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(EcTokens.radiusMd),
            border: Border.all(
              color: isDark ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.22), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.apple, color: fg, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Continue with Apple',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final line = Expanded(
      child: Container(height: 1, color: ec.textMuted.withValues(alpha: 0.16)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: ec.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
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
    final ec = EcColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ec.textCritical.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ec.textCritical.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: ec.textCritical),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: ec.textCritical, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).shakeX(amount: 2, duration: 320.ms);
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    Widget item(IconData i, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, size: 14, color: ec.textMuted),
            const SizedBox(width: 6),
            Text(t, style: TextStyle(color: ec.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 8,
      children: [
        item(Icons.lock_rounded, 'Private by design'),
        item(Icons.health_and_safety_rounded, 'PIPEDA aligned'),
        item(Icons.cloud_done_rounded, 'Encrypted sync'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Biometric unlock gate (logic unchanged)
// ─────────────────────────────────────────────────────────────────────────────
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
    if (!_unlocked) {
      return EcGlassScaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EcLogo(size: 84),
                  const SizedBox(height: 22),
                  Text('Unlock ElinaCura', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Use Face ID or your passcode to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EcColors.of(context).textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  EcGlassButton(
                    label: 'Unlock',
                    icon: Icons.fingerprint_rounded,
                    onPressed: _maybeUnlock,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Caregiver profile picker (logic unchanged)
// ─────────────────────────────────────────────────────────────────────────────
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EcGlassSurface(
                  child: const Text(
                    'No linked patients yet. Ask them to invite you via Connections.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
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
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final entry = entries[i];
              return EcCard(
                onTap: () => context.go('/caregiver/${entry.profileId}'),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Patient ${entry.profileId.substring(0, 8)}…')),
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
