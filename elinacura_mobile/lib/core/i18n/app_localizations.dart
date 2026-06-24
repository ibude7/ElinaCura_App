import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads nested JSON from assets/i18n/{locale}.json (Rec #48).
class AppLocalizations {
  AppLocalizations(this._strings);

  final Map<String, dynamic> _strings;

  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
  ];

  static Future<AppLocalizations> load(Locale locale) async {
    final code = locale.languageCode;
    final path = 'assets/i18n/$code.json';
    try {
      final raw = await rootBundle.loadString(path);
      return AppLocalizations(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      final raw = await rootBundle.loadString('assets/i18n/en.json');
      return AppLocalizations(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  String t(String key, {String fallback = ''}) {
    final parts = key.split('.');
    dynamic cur = _strings;
    for (final p in parts) {
      if (cur is Map<String, dynamic> && cur.containsKey(p)) {
        cur = cur[p];
      } else {
        return fallback.isNotEmpty ? fallback : key;
      }
    }
    return cur?.toString() ?? (fallback.isNotEmpty ? fallback : key);
  }

  String get appTitle => t('app.title', fallback: 'ElinaCura');
  String get tabToday => t('nav.tabs.today', fallback: 'Today');
  String get tabHealth => t('nav.tabs.health', fallback: 'Health');
  String get tabCare => t('nav.tabs.care', fallback: 'Care');
  String get tabYou => t('nav.tabs.you', fallback: 'You');

  // Emergency Medical ID
  String get emergencyTitle => t('emergency.title', fallback: 'Emergency Medical ID');
  String get emergencyTip => t('emergency.tip', fallback: 'Keep this page accessible offline.');
  String get emergencyContact => t('emergency.contact', fallback: 'Emergency Contact');
  String get emergencyBloodType => t('emergency.bloodType', fallback: 'Blood Type');
  String get emergencyAllergies => t('emergency.allergies', fallback: 'Known Allergies');
  String get emergencyConditions => t('emergency.conditions', fallback: 'Active Conditions');
  String get emergencyMedications => t('emergency.medications', fallback: 'Current Medications');
  String get emergencyNoProfile =>
      t('emergency.noProfile', fallback: 'Create a profile to generate your Emergency Medical ID');
  String get emergencyCall => t('emergency.callEmergency', fallback: 'Call Emergency Services');
  String get emergencyTextServices =>
      t('emergency.textServices', fallback: 'Text emergency services');

  // Care AI
  String get chatTitle => t('chatPage.title', fallback: 'Care AI');
  String get chatEyebrow => t('chatPage.eyebrow', fallback: 'AI companion');
  String get chatHeroHeadline => t('chatPage.heroHeadline', fallback: 'Ask anything about your care');
  String get chatSubtitle => t('chatPage.subtitle', fallback: 'Personal guidance grounded in your profile.');
  String get chatWelcomeTitle => t('chatPage.welcomeTitle', fallback: 'Start with a question');
  String get chatWelcomeSub => t('chatPage.welcomeSub', fallback: 'Tap a prompt or type your own below');
  String get chatPlaceholder => t('chatPage.placeholder', fallback: 'Ask about your health…');
  String get chatOfflineQueued =>
      t('chatPage.offlineQueued', fallback: 'Your message is queued and will send when you\'re back online.');

  // Dashboard
  String get dashboardOnboardingTitle =>
      t('dashboardPage.onboarding.title', fallback: 'Build your care profile');
  String get dashboardOnboardingLead => t(
        'dashboardPage.onboarding.lead',
        fallback:
            'Add medications, conditions, allergies, and care preferences to unlock personalized daily intelligence.',
      );
  String get dashboardOnboardingCta =>
      t('dashboardPage.onboarding.cta', fallback: 'Complete profile');
  String get dashboardQuickActionsTitle =>
      t('dashboardPage.quickActions.title', fallback: 'Quick actions');
  String get dashboardScanLabel =>
      t('dashboardPage.quickActions.scannerShort', fallback: 'Scan label');
  String get dashboardReminders =>
      t('dashboardPage.quickActions.reminders', fallback: 'Reminders');
  String get dashboardMore => t('nav.more', fallback: 'More');
  String get dashboardGreetingMorning =>
      t('dashboardPage.greeting.morning', fallback: 'Good morning');
  String get dashboardGreetingAfternoon =>
      t('dashboardPage.greeting.afternoon', fallback: 'Good afternoon');
  String get dashboardGreetingEvening =>
      t('dashboardPage.greeting.evening', fallback: 'Good evening');
  String get dashboardConditionsTitle =>
      t('dashboardPage.conditions.title', fallback: 'Conditions');

  String dashboardGreetingNamed(int hour, String name) {
    final greet = hour < 12
        ? dashboardGreetingMorning
        : hour < 17
            ? dashboardGreetingAfternoon
            : dashboardGreetingEvening;
    return t('dashboardPage.greeting.named', fallback: '{greeting}, {name}')
        .replaceAll('{greeting}', greet)
        .replaceAll('{name}', name);
  }

  // Health hub
  String get healthEyebrow => t('healthPage.title', fallback: 'Health');
  String get healthVitalsTitle =>
      t('healthPage.vitalsHub.title', fallback: 'Your vitals');
  String get healthEmergencyTooltip =>
      t('emergency.title', fallback: 'Emergency ID');
  String get healthStatusTitle =>
      t('healthPage.vitalsHub.statusTitle', fallback: 'Health status');
  String get healthNoVitals =>
      t('healthPage.vitalsHub.noVitals', fallback: 'No vitals logged yet');
  String healthTrackedCount(int count, int total) => t(
        'healthPage.vitalsHub.tracked',
        fallback: '{count} of {total} vitals tracked',
      )
          .replaceAll('{count}', '$count')
          .replaceAll('{total}', '$total');
  String get healthKeyMetrics =>
      t('healthPage.vitalsHub.keyMetrics', fallback: 'Key metrics');
  String get healthLogButton =>
      t('healthPage.vitalsHub.logButton', fallback: '+ Log');
  String get healthLogVitals =>
      t('healthPage.vitalsHub.logVitals', fallback: 'Log vitals');
  String get healthConnectTitle =>
      t('healthPage.vitalsHub.connectHealth', fallback: 'Connect Apple Health');
  String get healthConnected =>
      t('healthPage.vitalsHub.healthConnected',
          fallback: 'Health data connection enabled');
  String get healthConnectFailed => t(
        'healthPage.vitalsHub.healthConnectFailed',
        fallback: 'Could not connect — check permissions',
      );
  String get healthClinicianReport =>
      t('healthPage.vitalsHub.clinicianReport', fallback: 'Clinician report');
  String get healthNeedsAttention =>
      t('dashboardPage.attention.title', fallback: 'Needs attention');
  String get healthConditionsTitle =>
      t('healthPage.conditions.eyebrow', fallback: 'Conditions');

  // Care inbox
  String get careInboxEyebrow =>
      t('careInbox.eyebrow', fallback: 'Care network');
  String get careInboxTitle => t('careInbox.title', fallback: 'Care');
  String get careInboxSubtitle => t(
        'careInbox.subtitle',
        fallback: 'Messages, AI, alerts, and updates',
      );
  String get careInboxTabInbox => t('careInbox.tabs.inbox', fallback: 'Inbox');
  String get careInboxTabAi => t('careInbox.tabs.ai', fallback: 'AI');
  String get careInboxTabPeople =>
      t('careInbox.tabs.people', fallback: 'People');
  String get careInboxTabAlerts =>
      t('careInbox.tabs.alerts', fallback: 'Alerts');
  String get careInboxEmptyTitle =>
      t('careInbox.emptyTitle', fallback: 'Your care inbox is clear');
  String get careInboxEmptyCta =>
      t('careInbox.emptyCta', fallback: 'Ask Care AI');
  String get careInboxNew => t('careInbox.new', fallback: 'New');
  String get carePeopleEyebrow =>
      t('careInbox.people.eyebrow', fallback: 'Connect');
  String get carePeopleTitle =>
      t('careInbox.people.title', fallback: 'Your care circle');
  String get carePeopleSubtitle => t(
        'careInbox.people.subtitle',
        fallback: 'Family, caregivers, and clinical connections.',
      );
  String get carePeopleMessages =>
      t('messagesPage.title', fallback: 'Messages');
  String get carePeopleMessagesSub => t(
        'careInbox.people.messagesSub',
        fallback: 'Chat with your care circle',
      );
  String get carePeopleCircle =>
      t('messagesPage.openCircle', fallback: 'Family circle');
  String get carePeopleConnections =>
      t('nav.connections', fallback: 'Connections');
  String get carePeopleMoments => t('nav.moments', fallback: 'Moments');
  String get careAlertsEyebrow =>
      t('careInbox.alerts.eyebrow', fallback: 'Safety');
  String get careAlertsTitle =>
      t('careInbox.alerts.title', fallback: 'Alerts & monitoring');
  String get careAlertsSubtitle => t(
        'careInbox.alerts.subtitle',
        fallback: 'Safety events, emergency tools, and travel prep.',
      );
  String get careAlertsSafety =>
      t('careInbox.alerts.safety', fallback: 'Safety monitoring');
  String get careAlertsEmergency =>
      t('emergency.title', fallback: 'Emergency ID');
  String get careAlertsTravel =>
      t('careInbox.alerts.travel', fallback: 'Travel mode');
  String get careAlertsTelehealth =>
      t('careInbox.alerts.telehealth', fallback: 'Telehealth handoff');
  String get careVoiceTooltip => t('careInbox.voice', fallback: 'Voice');

  // Settings
  String get settingsTitle =>
      t('settingsPage.title', fallback: 'Settings');
  String get settingsPrivacyTitle =>
      t('settingsPage.privacy.title', fallback: 'Privacy consent');
  String get settingsPrivacyBody => t(
        'settingsPage.privacy.body',
        fallback:
            'ElinaCura collects personal health information to help manage your care under PIPEDA. You may request deletion at any time.',
      );
  String get settingsConsentCta =>
      t('settingsPage.accountActions.consentCta', fallback: 'I consent');
  String get settingsAppearanceTitle =>
      t('settingsPage.appearance.title', fallback: 'Appearance');
  String get settingsSecurityTitle =>
      t('settingsPage.security.title', fallback: 'Security');
  String get settingsBiometricTitle => t(
        'settingsPage.security.biometricTitle',
        fallback: 'Biometric unlock',
      );
  String get settingsBiometricSub => t(
        'settingsPage.security.biometricSub',
        fallback: 'Use Face ID or fingerprint to open the app',
      );
  String get settingsAccountTitle =>
      t('settingsPage.account.title', fallback: 'Account');
  String get settingsDisplayName => t(
        'settingsPage.accountActions.displayName',
        fallback: 'Display name',
      );
  String get settingsNameHint =>
      t('settingsPage.accountActions.nameHint', fallback: 'Your name');
  String get settingsUpdateName => t(
        'settingsPage.accountActions.updateName',
        fallback: 'Update name',
      );
  String get settingsNameUpdated => t(
        'settingsPage.accountActions.nameUpdated',
        fallback: 'Name updated',
      );
  String get settingsResendVerification => t(
        'settingsPage.accountActions.resendVerification',
        fallback: 'Resend verification email',
      );
  String get settingsNewPassword => t(
        'settingsPage.accountActions.newPassword',
        fallback: 'New password',
      );
  String get settingsChangePassword => t(
        'settingsPage.accountActions.changePassword',
        fallback: 'Change password',
      );
  String get settingsPasswordUpdated => t(
        'settingsPage.accountActions.passwordUpdated',
        fallback: 'Password updated',
      );
  String get settingsUpgradeAccount => t(
        'settingsPage.accountActions.upgradeAccount',
        fallback: 'Create permanent account',
      );
  String get settingsSignOut => t('auth.signOut', fallback: 'Sign out');
  String get settingsUpgradeTitle => t(
        'settingsPage.accountActions.upgradeTitle',
        fallback: 'Upgrade account',
      );
  String get settingsEmail =>
      t('auth.emailLabel', fallback: 'Email');
  String get settingsCancel =>
      t('settingsPage.accountActions.cancel', fallback: 'Cancel');
  String get settingsUpgradeAction => t(
        'settingsPage.accountActions.upgradeAction',
        fallback: 'Upgrade',
      );

  // Profile create
  String get profileCreateHeading =>
      t('profileCreate.headingFirst', fallback: 'Create your health profile');
  String get profileCreateLead => t(
        'profileCreate.lead',
        fallback:
            'Tell us a little about yourself so ElinaCura can tailor guidance to you.',
      );
  String get profileCreateBasicsTitle =>
      t('profileCreate.basicsTitle', fallback: 'Basics');
  String get profileCreateBasicsSub =>
      t('profileCreate.basicsSub', fallback: 'The essentials we use to personalize your care.');
  String get profileCreateName =>
      t('profileCreate.name', fallback: 'Full name');
  String get profileCreateNamePlaceholder =>
      t('profileCreate.namePlaceholder', fallback: 'e.g. Jordan Rivera');
  String get profileCreatePrimaryGoal =>
      t('profileCreate.primaryGoal', fallback: 'Primary goal');
  String get profileCreateBloodType =>
      t('profileCreate.bloodType', fallback: 'Blood type');
  String get profileCreateBloodTypePlaceholder =>
      t('profileCreate.bloodTypePlaceholder', fallback: 'Optional');
  String get profileCreateHealthTitle =>
      t('profileCreate.healthTitle', fallback: 'Health details');
  String get profileCreateHealthSub => t(
        'profileCreate.healthSub',
        fallback: 'Used to flag interactions and tailor recommendations.',
      );
  String get profileCreateConditions =>
      t('profileCreate.conditions', fallback: 'Conditions');
  String get profileCreateConditionsPlaceholder =>
      t('profileCreate.conditionsPlaceholder', fallback: 'e.g. Hypertension');
  String get profileCreateMedications =>
      t('profileCreate.medications', fallback: 'Medications');
  String get profileCreateMedicationsPlaceholder =>
      t('profileCreate.medicationsPlaceholder', fallback: 'e.g. Lisinopril 10mg');
  String get profileCreateAllergies =>
      t('profileCreate.allergies', fallback: 'Allergies');
  String get profileCreateAllergiesPlaceholder =>
      t('profileCreate.allergiesPlaceholder', fallback: 'e.g. Penicillin');
  String get profileCreateEmergencyTitle =>
      t('profileCreate.emergencyTitle', fallback: 'Emergency contact');
  String get profileCreateEmergencySub => t(
        'profileCreate.emergencySub',
        fallback: 'Who we surface on your medical ID in an emergency.',
      );
  String get profileCreateEmergencyName =>
      t('profileCreate.emergencyName', fallback: 'Contact name');
  String get profileCreateEmergencyNamePlaceholder =>
      t('profileCreate.emergencyNamePlaceholder', fallback: 'Optional');
  String get profileCreateEmergencyPhone =>
      t('profileCreate.emergencyPhone', fallback: 'Contact phone');
  String get profileCreateEmergencyPhonePlaceholder =>
      t('profileCreate.emergencyPhonePlaceholder', fallback: 'Optional');
  String get profileCreateConsent => t(
        'profileCreate.consent',
        fallback:
            'I consent to ElinaCura storing this health information to personalize my care.',
      );
  String get profileCreateSubmit =>
      t('profileCreate.submit', fallback: 'Create profile');
  String get profileCreateNameRequired => t(
        'profileCreate.errors.nameRequired',
        fallback: 'Please enter a name for this profile.',
      );
  String get profileCreateConsentRequired =>
      'Please accept the privacy consent to continue.';
  String get profileCreateFailed => t(
        'profileCreate.errors.failed',
        fallback: 'Could not create your profile. Please try again.',
      );
  String get profileCreateSuccess =>
      'Profile created — your dashboard is ready.';
}

class AppLocalizationsScope extends InheritedWidget {
  const AppLocalizationsScope({
    super.key,
    required this.l10n,
    required super.child,
  });

  final AppLocalizations l10n;

  static AppLocalizations of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    return scope?.l10n ??
        AppLocalizations(const {'app': {'title': 'ElinaCura'}});
  }

  @override
  bool updateShouldNotify(AppLocalizationsScope oldWidget) =>
      l10n != oldWidget.l10n;
}

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizationsScope.of(this);
}

final appLocalizationsProvider =
    FutureProvider<AppLocalizations>((ref) async {
  return AppLocalizations.load(const Locale('en'));
});

String tr(BuildContext context, String key, {String fallback = ''}) =>
    context.l10n.t(key, fallback: fallback);
