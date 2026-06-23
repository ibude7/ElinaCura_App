import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_providers.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/ec_theme.dart';
import 'core/theme/ec_tokens.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/auth_screens.dart';
import 'shared/widgets/ec_glass.dart';

class ElinaCuraApp extends ConsumerStatefulWidget {
  const ElinaCuraApp({super.key});

  @override
  ConsumerState<ElinaCuraApp> createState() => _ElinaCuraAppState();
}

class _ElinaCuraAppState extends ConsumerState<ElinaCuraApp> {
  bool _notificationsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only run notification setup / profile sync once the user is signed in —
      // we never want a system permission prompt interrupting onboarding.
      if (ref.read(authStateProvider).valueOrNull != null) {
        _onAuthenticated();
      }
    });
  }

  Future<void> _onAuthenticated() async {
    if (!_notificationsReady) {
      _notificationsReady = true;
      try {
        await ref.read(notificationServiceProvider).initialize();
      } catch (e) {
        debugPrint('Notifications init skipped: $e');
      }
    }
    _syncActiveProfile();
  }

  Future<void> _syncActiveProfile() async {
    try {
      final overview = await ref.read(healthOverviewProvider.future);
      if (overview.profile != null) {
        ref.read(activeProfileIdProvider.notifier).state = overview.profile!.id;
      }
    } catch (_) {
      // User may not be logged in yet
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final auth = ref.watch(authStateProvider);
    final themePreference = ref.watch(themePreferenceProvider);

    // Defer notification setup until the user actually signs in.
    ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull != null) _onAuthenticated();
    });

    return MaterialApp.router(
      title: 'ElinaCura',
      debugShowCheckedModeBanner: false,
      theme: withEcExtensions(EcTheme.light(), Brightness.light),
      darkTheme: withEcExtensions(EcTheme.dark(), Brightness.dark),
      themeMode: themePreference.themeMode,
      themeAnimationDuration: EcTokens.motionBase,
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: router,
      builder: (context, child) {
        Widget content = child ?? const SizedBox.shrink();
        if (auth.isLoading) {
          content = const Center(child: CircularProgressIndicator());
        } else if (auth.valueOrNull != null) {
          content = BiometricGate(child: content);
        }
        return EcVoidBackground(child: content);
      },
    );
  }
}
