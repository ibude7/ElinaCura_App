import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_theme.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/auth/onboarding_view.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/circle/circle_screens.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/digest/digest_screen.dart';
import '../../features/medications/medication_screens.dart';
import '../../features/nutrition/nutrition_screens.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/report/report_screen.dart';
import '../../features/shopping/shopping_list_screen.dart';
import '../../features/social/social_screens.dart';
import '../../features/telehealth/telehealth_screen.dart';
import '../../features/travel/travel_mode_screen.dart';
import '../../features/voice/voice_screen.dart';

/// Show the quick-add glass sheet from anywhere in the patient shell.
void showQuickAddSheet(BuildContext context) {
  showEcGlassSheet(
    context,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick add',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Capture something from your care flow.',
              style: TextStyle(
                color: EcColors.of(context).textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      _SheetTile(
        icon: Icons.auto_awesome_rounded,
        title: 'Ask Care AI',
        subtitle: 'Chat about your health plan',
        onTap: () {
          Navigator.pop(context);
          context.push('/chat');
        },
      ),
      _SheetTile(
        icon: Icons.document_scanner_rounded,
        title: 'Scan medication label',
        subtitle: 'OCR → review → save',
        onTap: () {
          Navigator.pop(context);
          context.push('/ocr');
        },
      ),
      _SheetTile(
        icon: Icons.monitor_heart_rounded,
        title: 'Log vitals',
        subtitle: 'Blood pressure, heart rate…',
        onTap: () {
          Navigator.pop(context);
          context.push('/health');
        },
      ),
      _SheetTile(
        icon: Icons.alarm_rounded,
        title: 'Set reminder',
        subtitle: 'Schedule a medication alert',
        onTap: () {
          Navigator.pop(context);
          context.push('/reminders');
        },
      ),
      _SheetTile(
        icon: Icons.emergency_rounded,
        title: 'Emergency',
        subtitle: 'SOS and Medical ID',
        iconColor: EcTokens.statusCritical,
        onTap: () {
          Navigator.pop(context);
          context.push('/emergency');
        },
      ),
    ],
  );
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final color = iconColor ?? ec.accentBrand;

    return EcGlassSurface(
      onTap: onTap,
      variant: EcGlassVariant.regular,
      borderRadius: EcTokens.radiusCard,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: ec.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: ec.textMuted, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────── Patient shell ──

class PatientShell extends ConsumerStatefulWidget {
  const PatientShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends ConsumerState<PatientShell> {
  /// Maps location → index in the 4-tab nav (0=Today, 1=Health, 2=Messages, 3=Profile).
  int _indexFromLocation(String location) {
    if (location.startsWith('/health')) return 1;
    if (location.startsWith('/messages')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return EcGlassScaffold(
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: EcFloatingNav(
        selectedIndex: index,
        onSelected: (i) {
          switch (i) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/health');
            case 2:
              context.go('/messages');
            case 3:
              context.go('/profile');
          }
        },
        onAdd: () => showQuickAddSheet(context),
        destinations: const [
          EcGlassNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Today',
          ),
          EcGlassNavDestination(
            icon: Icons.favorite_outline,
            selectedIcon: Icons.favorite_rounded,
            label: 'Health',
          ),
          EcGlassNavDestination(
            icon: Icons.chat_bubble_outline,
            selectedIcon: Icons.chat_bubble_rounded,
            label: 'Messages',
          ),
          EcGlassNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── Caregiver shell ──

class CaregiverShell extends ConsumerWidget {
  const CaregiverShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    var index = 0;
    if (location.startsWith('/messages')) index = 1;
    if (location.startsWith('/profile') || location.startsWith('/settings')) {
      index = 2;
    }

    return EcGlassScaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: EcFloatingNav(
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
            case 1:
              context.go('/messages');
            case 2:
              context.go('/profile');
          }
        },
        destinations: const [
          EcGlassNavDestination(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          EcGlassNavDestination(
            icon: Icons.chat_bubble_outline,
            selectedIcon: Icons.chat_bubble_rounded,
            label: 'Messages',
          ),
          EcGlassNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── Router ──

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final shellMode = ref.watch(shellModeProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final onAuth =
          state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/onboarding';
      if (!isLoggedIn && !onAuth) return '/auth';
      if (isLoggedIn &&
          (state.matchedLocation == '/auth' ||
              state.matchedLocation == '/onboarding')) {
        return shellMode == AppShellMode.caregiver
            ? '/caregiver-picker'
            : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/caregiver-picker',
        builder: (context, state) => const CaregiverProfilePickerScreen(),
      ),
      GoRoute(
        path: '/emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/ocr',
        builder: (context, state) => const OcrCaptureScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/refill',
        builder: (context, state) => const RefillCalendarScreen(),
      ),
      GoRoute(
        path: '/connections',
        builder: (context, state) => const ConnectionsScreen(),
      ),
      GoRoute(
        path: '/more',
        builder: (context, state) => const MoreMenuScreen(),
      ),
      GoRoute(
        path: '/safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/grocery',
        builder: (context, state) => const GroceryScreen(),
      ),
      GoRoute(
        path: '/meals',
        builder: (context, state) => const MealsScreen(),
      ),
      GoRoute(
        path: '/travel-mode',
        builder: (context, state) => const TravelModeScreen(),
      ),
      GoRoute(
        path: '/shopping-list',
        builder: (context, state) => const ShoppingListScreen(),
      ),
      GoRoute(
        path: '/voice',
        builder: (context, state) => const VoiceScreen(),
      ),
      GoRoute(
        path: '/digest',
        builder: (context, state) => const DigestScreen(),
      ),
      GoRoute(
        path: '/family-circle',
        builder: (context, state) => const FamilyCircleScreen(),
      ),
      GoRoute(
        path: '/moments',
        builder: (context, state) => const MomentsScreen(),
      ),
      GoRoute(
        path: '/telehealth',
        builder: (context, state) => const TelehealthScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          if (shellMode == AppShellMode.caregiver) {
            return CaregiverShell(child: child);
          }
          return PatientShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/health',
            builder: (context, state) => const HealthScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/caregiver/:profileId',
            builder: (context, state) => CaregiverDashboardScreen(
              profileId: state.pathParameters['profileId']!,
            ),
          ),
        ],
      ),
    ],
  );
});
