import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/auth/onboarding_view.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/medications/medication_screens.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/social/social_screens.dart';

void showQuickAddSheet(BuildContext context) {
  showEcGlassSheet(
    context,
    children: [
      _SheetTile(
        icon: Icons.document_scanner_rounded,
        title: 'Scan medication',
        onTap: () { Navigator.pop(context); context.push('/ocr'); },
      ),
      _SheetTile(
        icon: Icons.monitor_heart_rounded,
        title: 'Log vitals',
        onTap: () { Navigator.pop(context); context.push('/health'); },
      ),
      _SheetTile(
        icon: Icons.alarm_rounded,
        title: 'Add reminder',
        onTap: () { Navigator.pop(context); context.push('/reminders'); },
      ),
      _SheetTile(
        icon: Icons.emergency_rounded,
        title: 'Emergency',
        iconColor: EcColors.of(context).textCritical,
        onTap: () { Navigator.pop(context); context.push('/emergency'); },
      ),
    ],
  );
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.subtle,
      borderRadius: 16,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Icon(Icons.chevron_right_rounded, color: EcColors.of(context).textMuted),
        ],
      ),
    );
  }
}

class PatientShell extends ConsumerStatefulWidget {
  const PatientShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends ConsumerState<PatientShell> {
  int _indexFromLocation(String location) {
    if (location.startsWith('/health')) return 1;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return EcGlassScaffold(
      body: widget.child,
      bottomNavigationBar: EcGlassBottomNav(
        selectedIndex: index,
        onSelected: (i) {
          switch (i) {
            case 0: context.go('/dashboard');
            case 1: context.go('/health');
            case 2: showQuickAddSheet(context);
            case 3: context.go('/messages');
            case 4: context.go('/profile');
          }
        },
        destinations: const [
          EcGlassNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
          EcGlassNavDestination(icon: Icons.favorite_outline, selectedIcon: Icons.favorite_rounded, label: 'Health'),
          EcGlassNavDestination(icon: Icons.add_circle_outline, selectedIcon: Icons.add_circle_rounded, label: 'Add'),
          EcGlassNavDestination(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble_rounded, label: 'Messages'),
          EcGlassNavDestination(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class CaregiverShell extends ConsumerWidget {
  const CaregiverShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    var index = 0;
    if (location.startsWith('/messages')) index = 1;
    if (location.startsWith('/profile') || location.startsWith('/settings')) index = 2;

    return EcGlassScaffold(
      body: child,
      bottomNavigationBar: EcGlassBottomNav(
        selectedIndex: index,
        onSelected: (i) {
          switch (i) {
            case 0:
              final access = ref.read(caregiverAccessProvider).valueOrNull;
              if (access != null && access.isNotEmpty) {
                context.go('/caregiver/${access.first.profileId}');
              } else {
                context.go('/caregiver-picker');
              }
            case 1: context.go('/messages');
            case 2: context.go('/profile');
          }
        },
        destinations: const [
          EcGlassNavDestination(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'Dashboard'),
          EcGlassNavDestination(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble_rounded, label: 'Messages'),
          EcGlassNavDestination(icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final shellMode = ref.watch(shellModeProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final onAuth = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/onboarding';
      if (!isLoggedIn && !onAuth) return '/auth';
      if (isLoggedIn && (state.matchedLocation == '/auth' || state.matchedLocation == '/onboarding')) {
        return shellMode == AppShellMode.caregiver ? '/caregiver-picker' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/caregiver-picker', builder: (_, __) => const CaregiverProfilePickerScreen()),
      GoRoute(path: '/emergency', builder: (_, __) => const EmergencyScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/ocr', builder: (_, __) => const OcrCaptureScreen()),
      GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
      GoRoute(path: '/reminders', builder: (_, __) => const RemindersScreen()),
      GoRoute(path: '/refill', builder: (_, __) => const RefillCalendarScreen()),
      GoRoute(path: '/connections', builder: (_, __) => const ConnectionsScreen()),
      GoRoute(path: '/more', builder: (_, __) => const MoreMenuScreen()),
      GoRoute(path: '/safety', builder: (_, __) => const SafetyScreen()),
      ShellRoute(
        builder: (context, state, child) {
          if (shellMode == AppShellMode.caregiver) {
            return CaregiverShell(child: child);
          }
          return PatientShell(child: child);
        },
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/health', builder: (_, __) => const HealthScreen()),
          GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/caregiver/:profileId',
            builder: (_, state) => CaregiverDashboardScreen(
              profileId: state.pathParameters['profileId']!,
            ),
          ),
        ],
      ),
    ],
  );
});
