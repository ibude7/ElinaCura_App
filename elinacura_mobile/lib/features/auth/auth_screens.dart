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
                  position: Tween(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(anim),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const _BrandHero()
                .animate()
                .fadeIn(duration: 560.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 26),
            EcGlassSurface(
                  variant: EcGlassVariant.elevated,
                  borderRadius: EcTokens.radiusGlass,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to ElinaCura',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose your path. We will tune the experience around your daily care role.',
                        style: TextStyle(
                          color: ec.textSecondary,
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _CarePromiseStrip(),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 120.ms, duration: 440.ms)
                .slideY(begin: 0.08, end: 0, delay: 120.ms),
            const SizedBox(height: 22),
            Text(
              'CONTINUE AS',
              style: TextStyle(
                color: ec.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ).animate().fadeIn(delay: 260.ms, duration: 350.ms),
            const SizedBox(height: 12),
            _RoleCard(
                  icon: Icons.self_improvement_rounded,
                  title: 'Manage my health',
                  subtitle:
                      'A private command center for medications, scans, vitals, appointments, and safety alerts.',
                  accent: ec.accentBrand,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedRole = UserRole.patient);
                  },
                )
                .animate()
                .fadeIn(delay: 400.ms, duration: 420.ms)
                .slideY(
                  begin: 0.14,
                  end: 0,
                  delay: 400.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 14),
            _RoleCard(
                  icon: Icons.diversity_1_rounded,
                  title: 'Care for someone I love',
                  subtitle:
                      'See the right updates, coordinate routines, and step in quickly when care needs attention.',
                  accent: const Color(0xFF1A3C34),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedRole = UserRole.caregiver);
                  },
                )
                .animate()
                .fadeIn(delay: 480.ms, duration: 420.ms)
                .slideY(
                  begin: 0.14,
                  end: 0,
                  delay: 480.ms,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 24),
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
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedRole = null;
                    _error = null;
                  });
                },
              ),
              const Spacer(),
              _RoleChip(
                icon: isCaregiver
                    ? Icons.diversity_1_rounded
                    : Icons.self_improvement_rounded,
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
                const SizedBox(height: 16),
                _AuthHeroPanel(
                      isSignUp: _isSignUp,
                      isCaregiver: isCaregiver,
                      accent: _accent,
                    )
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.06, end: 0),
                const SizedBox(height: 22),
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
                                _showPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: ec.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
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
                    )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 400.ms)
                    .slideY(begin: 0.06, end: 0, delay: 80.ms),
                const SizedBox(height: 20),
                _OrDivider(
                  label: _isSignUp
                      ? 'or start faster with'
                      : 'or continue with',
                ),
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
                      style: TextStyle(
                        color: ec.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'By continuing you agree to our Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ec.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
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
      height: 172,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentBrand.withValues(alpha: 0.10),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.94, 0.94),
                end: const Offset(1.06, 1.06),
                duration: 3000.ms,
                curve: Curves.easeInOut,
              ),
          Positioned(
            right: 46,
            top: 30,
            child: _FloatingSignal(
              icon: Icons.health_and_safety_rounded,
              color: ec.accentBrand,
              label: 'Safe',
            ),
          ),
          Positioned(
            left: 42,
            bottom: 24,
            child: const _FloatingSignal(
              icon: Icons.favorite_rounded,
              color: Color(0xFF1A3C34),
              label: 'Care',
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? Colors.white : Colors.white).withValues(
                    alpha: isDark ? 0.08 : 0.5,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.7),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const EcLogo(size: 96),
        ],
      ),
    );
  }
}

class _FloatingSignal extends StatelessWidget {
  const _FloatingSignal({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final glass = EcGlass.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: glass.fillElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glass.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarePromiseStrip extends StatelessWidget {
  const _CarePromiseStrip();

  static const _items = [
    (Icons.lock_rounded, 'Private'),
    (Icons.notifications_active_rounded, 'Timely'),
    (Icons.groups_rounded, 'Shared'),
  ];

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: ec.accentBrand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ec.accentBrand.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                children: [
                  Icon(_items[i].$1, color: ec.accentBrand, size: 17),
                  const SizedBox(height: 5),
                  Text(
                    _items[i].$2,
                    style: TextStyle(
                      color: ec.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthGlow extends StatelessWidget {
  const _AuthGlow({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF080B11) : const Color(0xFFEFEBE3);
    return ColoredBox(
      color: base,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -110,
            right: -92,
            child: _AuthOrb(
              size: 260,
              color: accent,
              opacity: dark ? 0.22 : 0.15,
            ),
          ),
          Positioned(
            bottom: 44,
            left: -120,
            child: _AuthOrb(
              size: 250,
              color: const Color(0xFF1A3C34),
              opacity: dark ? 0.16 : 0.10,
            ),
          ),
          Positioned(
            top: 240,
            left: 28,
            child: _AuthOrb(
              size: 96,
              color: Colors.white,
              opacity: dark ? 0.04 : 0.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthOrb extends StatelessWidget {
  const _AuthOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

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
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
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
      borderRadius: EcTokens.radiusGlass,
      padding: const EdgeInsets.all(18),
      tint: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: accent.withValues(alpha: 0.15),
                  border: Border.all(color: accent.withValues(alpha: 0.24)),
                ),
                child: Icon(icon, color: accent, size: 27),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: ec.textSecondary,
              fontSize: 13,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.icon,
    required this.label,
    required this.accent,
  });
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
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel({
    required this.isSignUp,
    required this.isCaregiver,
    required this.accent,
  });

  final bool isSignUp;
  final bool isCaregiver;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return EcGlassSurface(
      variant: EcGlassVariant.subtle,
      borderRadius: EcTokens.radiusGlass,
      tint: accent,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: accent.withValues(alpha: 0.14),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Icon(
                  isCaregiver
                      ? Icons.diversity_1_rounded
                      : Icons.self_improvement_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                isSignUp ? 'NEW CARE SPACE' : 'SECURE RETURN',
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: EcTokens.motionFast,
            child: Text(
              isSignUp ? 'Create your account' : 'Welcome back',
              key: ValueKey(isSignUp),
              style: TextStyle(
                color: onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSignUp
                ? 'Set up a calm, private place to coordinate your care from day one.'
                : 'Sign in to continue your routines, insights, and care circle.',
            style: TextStyle(
              color: ec.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign in / Create account segmented toggle
// ─────────────────────────────────────────────────────────────────────────────
class _AuthToggle extends StatelessWidget {
  const _AuthToggle({
    required this.isSignUp,
    required this.accent,
    required this.onChanged,
  });
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
                alignment: isSignUp
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: segW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
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
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
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
              color: isDark
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
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
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
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
  const _OrDivider({required this.label});

  final String label;

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
          child: Text(
            label,
            style: TextStyle(
              color: ec.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
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
            child: Text(
              message,
              style: TextStyle(
                color: ec.textCritical,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        Text(
          t,
          style: TextStyle(
            color: ec.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                  Text(
                    'Unlock ElinaCura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use Face ID or your passcode to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EcColors.of(context).textSecondary,
                      fontSize: 13,
                    ),
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
