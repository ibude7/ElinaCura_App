import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      _routeAfterAuth();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);

    if (_selectedRole == null) {
      return EcGlassScaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Center(
                  child: const EcLogo(size: 116)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.9, 0.9), duration: 600.ms, curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 28),
                Text(
                  'Welcome to ElinaCura',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 120.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, delay: 120.ms),
                const SizedBox(height: 10),
                Text(
                  'Inspired by Elina — a century of intentional living. '
                  'Let’s set up the experience that fits you.',
                  style: TextStyle(color: ec.textSecondary, fontSize: 14, height: 1.45),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 450.ms),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'HOW WILL YOU USE THE APP?',
                    style: TextStyle(
                      color: ec.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 350.ms),
                _RoleCard(
                  icon: Icons.person_rounded,
                  title: 'Manage my health',
                  subtitle: 'Track meds, vitals, and appointments',
                  onTap: () => setState(() => _selectedRole = UserRole.patient),
                )
                    .animate()
                    .fadeIn(delay: 320.ms, duration: 400.ms)
                    .slideY(begin: 0.12, end: 0, delay: 320.ms, curve: Curves.easeOut),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.people_rounded,
                  title: 'Monitor someone I care for',
                  subtitle: 'Stay connected as a family caregiver',
                  outlined: true,
                  onTap: () => setState(() => _selectedRole = UserRole.caregiver),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.12, end: 0, delay: 400.ms, curve: Curves.easeOut),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    return EcGlassScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _selectedRole = null),
        ),
        title: Text(_isSignUp ? 'Create account' : 'Sign in'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: EcTokens.radiusGlass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isSignUp)
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Display name'),
                    textInputAction: TextInputAction.next,
                  ),
                if (_isSignUp) const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  obscureText: !_showPassword,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: TextStyle(color: ec.textCritical)),
                ],
                const SizedBox(height: 24),
                EcGlassButton(
                  label: _isSignUp ? 'Sign up' : 'Sign in',
                  loading: _loading,
                  onPressed: _loading ? null : _submit,
                ),
                const SizedBox(height: 12),
                EcGlassButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  outlined: true,
                  onPressed: _loading ? null : _google,
                ),
                TextButton(
                  onPressed: _loading ? null : _guest,
                  child: const Text('Continue as guest'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp ? 'Already have an account? Sign in' : 'Need an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    return EcGlassSurface(
      onTap: onTap,
      variant: outlined ? EcGlassVariant.subtle : EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusLg,
      tint: outlined ? null : ec.accentBrand,
      child: _RoleCardContent(
        icon: icon,
        title: title,
        subtitle: subtitle,
        color: outlined ? ec.textSecondary : ec.accentBrand,
      ),
    );
  }
}

class _RoleCardContent extends StatelessWidget {
  const _RoleCardContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: color),
      ],
    );
  }
}

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EcLogo(size: 80),
                  const SizedBox(height: 24),
                  Text('Unlock ElinaCura', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  EcGlassButton(
                    label: 'Unlock with biometrics',
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
