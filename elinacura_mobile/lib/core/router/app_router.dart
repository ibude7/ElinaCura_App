import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/app_localizations.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../features/auth/auth_screens.dart';
import '../../features/auth/onboarding_view.dart';
import '../../features/body_map/body_map_screen.dart';
import '../../features/care/care_inbox_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/circle/circle_screens.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/digest/digest_screen.dart';
import '../../features/medications/medication_screens.dart';
import '../../features/medications/medication_timeline_screen.dart';
import '../../features/nutrition/nutrition_screens.dart';
import '../../features/emergency/emergency_screen.dart';
import '../../features/profile/profile_create_screen.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/shopping/shopping_list_screen.dart';
import '../../features/social/social_screens.dart';
import '../../features/telehealth/telehealth_screen.dart';
import '../../features/travel/travel_mode_screen.dart';
import '../../features/voice/voice_screen.dart';
import '../../core/config/feature_flags.dart';
import '../../features/caregiver/caregiver_command_center.dart';
import '../../features/moments/health_story_screen.dart';
import '../../features/settings/trust_center_screen.dart';
import '../../shared/widgets/ec_context_quick_add.dart';
import '../../shared/widgets/ec_grouped_more.dart';

/// Context-aware quick-add (Rec #13). Long-press nav + for full sheet.
void showQuickAddSheet(BuildContext context, WidgetRef ref) {
  EcContextQuickAdd.show(context, ref);
}

void showQuickAddSheetLegacy(BuildContext context) {
  EcGroupedMoreSheet.show(context);
}

// ─────────────────────────────────────────────────── Patient shell ──

class PatientShell extends ConsumerStatefulWidget {
  const PatientShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends ConsumerState<PatientShell> {
  /// 0=Today, 1=Health, 2=Care, 3=You
  int _indexFromLocation(String location) {
    if (location.startsWith('/health')) return 1;
    if (location.startsWith('/care') || location.startsWith('/messages')) {
      return 2;
    }
    if (location.startsWith('/profile') || location.startsWith('/you')) {
      return 3;
    }
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
              context.go('/care');
            case 3:
              context.go('/you');
          }
        },
        onAdd: () => showQuickAddSheet(context, ref),
        onAddLongPress: () {
          final flags = ref.read(featureFlagsProvider).valueOrNull;
          EcGroupedMoreSheet.show(context, flags: flags);
        },
        compressLabels: ref.watch(dashboardScrollOffsetProvider) > 80,
        destinations: [
          EcGlassNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: context.l10n.tabToday,
            accent: EcTokens.tabToday,
          ),
          EcGlassNavDestination(
            icon: Icons.favorite_outline,
            selectedIcon: Icons.favorite_rounded,
            label: context.l10n.tabHealth,
            accent: EcTokens.tabHealth,
          ),
          EcGlassNavDestination(
            icon: Icons.shield_moon_outlined,
            selectedIcon: Icons.shield_moon_rounded,
            label: context.l10n.tabCare,
            accent: EcTokens.tabCare,
          ),
          EcGlassNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person_rounded,
            label: context.l10n.tabYou,
            accent: EcTokens.tabYou,
          ),
        ],
      ),
    );
  }
}

/// Scroll offset for Today tab nav compression (Rec #25).
final dashboardScrollOffsetProvider = StateProvider<double>((ref) => 0);

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
        path: '/profile/create',
        builder: (context, state) => const ProfileCreateScreen(),
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
        path: '/trust-center',
        builder: (context, state) => const TrustCenterScreen(),
      ),
      GoRoute(
        path: '/health-story',
        builder: (context, state) => const HealthStoryScreen(),
      ),
      // Domain nested navigation aliases (Rec #14)
      GoRoute(path: '/meds/reminders', redirect: (_, _) => '/reminders'),
      GoRoute(path: '/meds/ocr', redirect: (_, _) => '/ocr'),
      GoRoute(path: '/meds/scanner', redirect: (_, _) => '/scanner'),
      GoRoute(path: '/meds/refill', redirect: (_, _) => '/refill'),
      GoRoute(path: '/nutrition/meals', redirect: (_, _) => '/meals'),
      GoRoute(path: '/nutrition/grocery', redirect: (_, _) => '/grocery'),
      GoRoute(path: '/nutrition/shopping', redirect: (_, _) => '/shopping-list'),
      GoRoute(path: '/care/chat', redirect: (_, _) => '/chat'),
      GoRoute(path: '/care/voice', redirect: (_, _) => '/voice'),
      GoRoute(path: '/care/moments', redirect: (_, _) => '/moments'),
      GoRoute(path: '/safety/emergency', redirect: (_, _) => '/emergency'),
      GoRoute(path: '/safety/travel', redirect: (_, _) => '/travel-mode'),
      GoRoute(
        path: '/telehealth',
        builder: (context, state) => const TelehealthScreen(),
      ),
      GoRoute(
        path: '/body-map',
        builder: (context, state) => const BodyMapScreen(),
      ),
      GoRoute(
        path: '/med-timeline',
        builder: (context, state) => const MedicationTimelineScreen(),
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
            path: '/care',
            builder: (context, state) => const CareInboxScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/you',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile',
            redirect: (context, state) => '/you',
          ),
          GoRoute(
            path: '/caregiver/:profileId',
            builder: (context, state) => CaregiverCommandCenter(
              profileId: state.pathParameters['profileId']!,
            ),
          ),
        ],
      ),
    ],
  );
});
