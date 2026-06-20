import 'package:equatable/equatable.dart';

class HealthProfile extends Equatable {
  const HealthProfile({
    required this.id,
    this.name,
    this.email,
    this.location,
    this.bloodType,
    this.primaryGoal,
    this.conditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.emergencyContacts = const [],
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      location: json['location'] as String?,
      bloodType: json['blood_type'] as String?,
      primaryGoal: json['primary_goal'] as String?,
      conditions: _stringList(json['conditions']),
      medications: _stringList(json['medications']),
      allergies: _stringList(json['allergies']),
      emergencyContacts: _contactList(json['emergency_contacts']),
    );
  }

  final String id;
  final String? name;
  final String? email;
  final String? location;
  final String? bloodType;
  final String? primaryGoal;
  final List<String> conditions;
  final List<String> medications;
  final List<String> allergies;
  final List<EmergencyContact> emergencyContacts;

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  static List<EmergencyContact> _contactList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(EmergencyContact.fromJson)
        .toList();
  }

  @override
  List<Object?> get props => [id, name, email];
}

class EmergencyContact extends Equatable {
  const EmergencyContact({required this.name, this.phone, this.relationship});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      relationship: json['relationship'] as String?,
    );
  }

  final String name;
  final String? phone;
  final String? relationship;

  @override
  List<Object?> get props => [name, phone];
}

class MedicationItem extends Equatable {
  const MedicationItem({
    required this.id,
    required this.name,
    this.dose = '',
    this.route = '',
    this.schedule = '',
    this.nextDue = '',
  });

  final String id;
  final String name;
  final String dose;
  final String route;
  final String schedule;
  final String nextDue;

  @override
  List<Object?> get props => [id, name];
}

class ConditionItem extends Equatable {
  const ConditionItem({required this.id, required this.name, this.status = 'neutral'});

  final String id;
  final String name;
  final String status;

  @override
  List<Object?> get props => [id, name];
}

class GoalItem extends Equatable {
  const GoalItem({required this.id, required this.label, this.priority = 'High'});

  final String id;
  final String label;
  final String priority;

  @override
  List<Object?> get props => [id, label];
}

class HealthOverview extends Equatable {
  const HealthOverview({
    required this.hasProfile,
    required this.hasAnalytics,
    this.profile,
    this.medications = const [],
    this.conditions = const [],
    this.goals = const [],
    this.keyVitals = const [],
    this.dailyPills = const [],
    this.openIssues = const [],
  });

  final bool hasProfile;
  final bool hasAnalytics;
  final HealthProfile? profile;
  final List<MedicationItem> medications;
  final List<ConditionItem> conditions;
  final List<GoalItem> goals;
  final List<Map<String, String>> keyVitals;
  final List<dynamic> dailyPills;
  final List<dynamic> openIssues;

  @override
  List<Object?> get props => [hasProfile, hasAnalytics, profile?.id];
}

class CaregiverAccessEntry extends Equatable {
  const CaregiverAccessEntry({
    required this.id,
    required this.profileId,
    this.status = 'active',
    this.permissions = const [],
  });

  factory CaregiverAccessEntry.fromJson(Map<String, dynamic> json) {
    return CaregiverAccessEntry(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  final String id;
  final String profileId;
  final String status;
  final List<String> permissions;

  @override
  List<Object?> get props => [id, profileId];
}

class CaregiverDashboardData extends Equatable {
  const CaregiverDashboardData({
    required this.profileId,
    this.adherenceRate7d,
    this.missedDoseCount = 0,
    this.activeMedications = const [],
    this.daysSinceLastUpdate,
    this.safetyEvents = const [],
    this.clinicianSummary,
  });

  factory CaregiverDashboardData.fromJson(Map<String, dynamic> json) {
    return CaregiverDashboardData(
      profileId: json['profile_id'] as String? ?? '',
      adherenceRate7d: (json['adherence_rate_7d'] as num?)?.toDouble(),
      missedDoseCount: json['missed_dose_count'] as int? ?? 0,
      activeMedications: (json['active_medications'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      daysSinceLastUpdate: json['days_since_last_update'] as int?,
      safetyEvents: (json['safety_events'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(SafetyEvent.fromJson)
              .toList() ??
          [],
      clinicianSummary: json['clinician_summary'] as Map<String, dynamic>?,
    );
  }

  final String profileId;
  final double? adherenceRate7d;
  final int missedDoseCount;
  final List<String> activeMedications;
  final int? daysSinceLastUpdate;
  final List<SafetyEvent> safetyEvents;
  final Map<String, dynamic>? clinicianSummary;

  int? get adherencePercent =>
      adherenceRate7d == null ? null : (adherenceRate7d! * 100).round();

  @override
  List<Object?> get props => [profileId, adherenceRate7d, missedDoseCount];
}

class SafetyEvent extends Equatable {
  const SafetyEvent({
    required this.id,
    this.summary,
    this.level,
    this.subject,
    this.source,
  });

  factory SafetyEvent.fromJson(Map<String, dynamic> json) {
    final risk = json['risk'] as Map<String, dynamic>?;
    return SafetyEvent(
      id: json['id'] as String? ?? '',
      summary: risk?['summary'] as String?,
      level: risk?['level'] as String?,
      subject: json['subject'] as String?,
      source: json['source'] as String?,
    );
  }

  final String id;
  final String? summary;
  final String? level;
  final String? subject;
  final String? source;

  String get displayText => summary ?? subject ?? source ?? '—';

  @override
  List<Object?> get props => [id];
}

class ReminderItem extends Equatable {
  const ReminderItem({
    required this.id,
    required this.medicationName,
    this.dose,
    this.nextDue,
    this.cadenceLabel,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String? ?? json['medication_name'] as String? ?? '',
      medicationName: json['medication_name'] as String? ?? 'Medication',
      dose: json['dose'] as String?,
      nextDue: json['next_due'] as String? ?? json['next_occurrence'] as String?,
      cadenceLabel: json['cadence_label'] as String? ?? json['timezone'] as String?,
    );
  }

  final String id;
  final String medicationName;
  final String? dose;
  final String? nextDue;
  final String? cadenceLabel;

  @override
  List<Object?> get props => [id, medicationName];
}

class OcrDraft extends Equatable {
  const OcrDraft({
    required this.ocrId,
    required this.draft,
    this.lowConfidenceFields = const [],
    this.message,
  });

  factory OcrDraft.fromJson(Map<String, dynamic> json) {
    return OcrDraft(
      ocrId: json['ocr_id'] as String? ?? '',
      draft: json['draft'] as Map<String, dynamic>? ?? {},
      lowConfidenceFields: (json['low_confidence_fields'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message'] as String?,
    );
  }

  final String ocrId;
  final Map<String, dynamic> draft;
  final List<String> lowConfidenceFields;
  final String? message;

  @override
  List<Object?> get props => [ocrId];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.read = false,
  });

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      text: data['text'] as String? ?? '',
      senderId: data['senderId'] as String? ?? data['sender_id'] as String? ?? '',
      timestamp: data['timestamp']?.toString() ?? '',
      read: data['read'] as bool? ?? false,
    );
  }

  final String id;
  final String text;
  final String senderId;
  final String timestamp;
  final bool read;

  @override
  List<Object?> get props => [id, text];
}

enum UserRole { patient, caregiver }

enum AppShellMode { patient, caregiver }
