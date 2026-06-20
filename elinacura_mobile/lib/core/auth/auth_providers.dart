import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../api/api_client.dart';
import '../config/app_config.dart';
import '../../shared/models/models.dart';
import '../../shared/utils/health_overview_builder.dart';
import 'secure_token_store.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final userRoleProvider = StateProvider<UserRole?>((ref) => null);

final shellModeProvider = StateProvider<AppShellMode>((ref) => AppShellMode.patient);

final activeProfileIdProvider = StateProvider<String?>((ref) => null);

final biometricEnabledProvider = StateProvider<bool>((ref) => false);

final pipedaConsentProvider = StateProvider<bool>((ref) => false);

class AuthService {
  AuthService(this._auth, this._api, this._tokenStore);

  final FirebaseAuth _auth;
  final ApiClient _api;
  final SecureTokenStore _tokenStore;

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _establishSession(cred.user);
  }

  Future<void> signUpWithEmail(String email, String password, {String? displayName}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    await cred.user?.sendEmailVerification();
    await _establishSession(cred.user);
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    await _establishSession(cred.user);
  }

  Future<void> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    await _establishSession(cred.user);
  }

  /// Sign in with Apple via Firebase OAuth, using a hashed nonce to protect
  /// against replay attacks (per FlutterFire guidance).
  Future<void> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final cred = await _auth.signInWithCredential(oauthCredential);

    // Apple only returns the user's name on the very first authorization —
    // capture it into the Firebase profile when available.
    final given = appleCredential.givenName ?? '';
    final family = appleCredential.familyName ?? '';
    final fullName = '$given $family'.trim();
    final existing = cred.user?.displayName ?? '';
    if (existing.isEmpty && fullName.isNotEmpty) {
      await cred.user?.updateDisplayName(fullName);
    }

    await _establishSession(cred.user);
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// Refresh stored token and backend session after app restart.
  Future<void> ensureBackendSession() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    if (token == null) return;
    await _tokenStore.persistToken(token);
    if (user.isAnonymous) return;
    try {
      await _api.post<Map<String, dynamic>>('/auth/session', data: {'id_token': token});
    } catch (e) {
      debugPrint('Session refresh skipped: $e');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> linkAnonymousWithEmail(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return;
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    await user.linkWithCredential(credential);
    await user.sendEmailVerification();
    await _establishSession(user);
  }

  Future<void> signOut() async {
    await _api.post<Map<String, dynamic>>('/auth/logout').catchError((_) => <String, dynamic>{});
    await GoogleSignIn().signOut();
    await _tokenStore.clear();
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> getSessionInfo() async {
    return _api.get<Map<String, dynamic>>('/auth/me');
  }

  Future<List<CaregiverAccessEntry>> getCaregiverAccess() async {
    final data = await _api.get<Map<String, dynamic>>('/caregiver/access');
    final asCaregiver = data['as_caregiver'] as List? ?? [];
    return asCaregiver
        .whereType<Map<String, dynamic>>()
        .map(CaregiverAccessEntry.fromJson)
        .where((e) => e.status == 'active')
        .toList();
  }

  Future<void> _establishSession(User? user) async {
    if (user == null) return;
    final token = await user.getIdToken();
    if (token == null) return;
    await _tokenStore.persistToken(token);
    // Anonymous Firebase users authenticate via Bearer token only.
    if (user.isAnonymous) return;
    await _api.post<Map<String, dynamic>>('/auth/session', data: {'id_token': token});
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(apiClientProvider),
    SecureTokenStore(),
  );
});

class ProfileCache {
  static const _key = 'ec.active_profile';

  static Future<void> cacheProfile(HealthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, profile.id);
  }

  static Future<String?> readActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}

final healthOverviewProvider =
    AsyncNotifierProvider<HealthOverviewNotifier, HealthOverview>(() {
  return HealthOverviewNotifier();
});

class HealthOverviewNotifier extends AsyncNotifier<HealthOverview> {
  @override
  Future<HealthOverview> build() async => _load();

  Future<HealthOverview> _load() async {
    await ref.read(authServiceProvider).ensureBackendSession();
    final api = ref.read(apiClientProvider);
    final raw = await api.get<dynamic>('/profiles');
    final profiles = normalizeProfiles(raw);
    final cachedId = await ProfileCache.readActiveProfileId();
    HealthProfile? profile;
    if (profiles.isNotEmpty) {
      profile = profiles.cast<HealthProfile?>().firstWhere(
            (p) => p!.id == cachedId,
            orElse: () => profiles.first,
          );
      if (profile != null) {
        await ProfileCache.cacheProfile(profile);
      }
    }
    return HealthOverviewBuilder.build(profile);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final caregiverDashboardProvider = AsyncNotifierProvider.family<
    CaregiverDashboardNotifier, CaregiverDashboardData, String>(() {
  return CaregiverDashboardNotifier();
});

class CaregiverDashboardNotifier
    extends FamilyAsyncNotifier<CaregiverDashboardData, String> {
  @override
  Future<CaregiverDashboardData> build(String profileId) async {
    final api = ref.read(apiClientProvider);
    final data = await api.get<Map<String, dynamic>>(
      '/caregiver-dashboard/$profileId',
    );
    return CaregiverDashboardData.fromJson(data);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }
}

final remindersProvider =
    AsyncNotifierProvider.family<RemindersNotifier, List<ReminderItem>, String>(
  () => RemindersNotifier(),
);

class RemindersNotifier extends FamilyAsyncNotifier<List<ReminderItem>, String> {
  @override
  Future<List<ReminderItem>> build(String profileId) async {
    final api = ref.read(apiClientProvider);
    final data = await api.get<Map<String, dynamic>>(
      '/reminders',
      queryParameters: {'profile_id': profileId},
    );
    final rows = data['reminders'] as List? ?? [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ReminderItem.fromJson)
        .toList();
  }
}

final caregiverAccessProvider =
    FutureProvider<List<CaregiverAccessEntry>>((ref) async {
  return ref.watch(authServiceProvider).getCaregiverAccess();
});
