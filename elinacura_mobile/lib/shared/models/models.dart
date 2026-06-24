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

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (location != null) 'location': location,
        if (bloodType != null) 'blood_type': bloodType,
        if (primaryGoal != null) 'primary_goal': primaryGoal,
        'conditions': conditions,
        'medications': medications,
        'allergies': allergies,
        'emergency_contacts':
            emergencyContacts.map((c) => c.toJson()).toList(),
      };

  HealthProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? location,
    String? bloodType,
    String? primaryGoal,
    List<String>? conditions,
    List<String>? medications,
    List<String>? allergies,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return HealthProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      location: location ?? this.location,
      bloodType: bloodType ?? this.bloodType,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
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

  Map<String, dynamic> toJson() => {
        'name': name,
        if (phone != null) 'phone': phone,
        if (relationship != null) 'relationship': relationship,
      };

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
    this.times = const [],
  });

  final String id;
  final String name;
  final String dose;
  final String route;

  /// Human-readable cadence label, e.g. "Twice daily" or "Daily at 8 AM".
  final String schedule;
  final String nextDue;

  /// Structured dose times in 24h "HH:mm" form, derived from the entry text.
  /// Empty means no fixed schedule (e.g. "as needed").
  final List<String> times;

  bool get hasSchedule => times.isNotEmpty;

  @override
  List<Object?> get props => [id, name, dose, schedule, times];
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

// ── Engagement models (PWA migration) ─────────────────────────────────────

class ChatHistoryMessage extends Equatable {
  const ChatHistoryMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    return ChatHistoryMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  final String id;
  final String role;
  final String content;
  final String? createdAt;

  bool get isAssistant => role == 'assistant';

  @override
  List<Object?> get props => [id, role, content];
}

class ChatReply extends Equatable {
  const ChatReply({
    required this.response,
    this.escalated = false,
    this.riskLevel,
  });

  factory ChatReply.fromJson(Map<String, dynamic> json) {
    final risk = json['risk'] as Map<String, dynamic>?;
    return ChatReply(
      response: json['response'] as String? ?? '',
      escalated: json['escalated'] as bool? ?? false,
      riskLevel: risk?['level'] as String?,
    );
  }

  final String response;
  final bool escalated;
  final String? riskLevel;

  @override
  List<Object?> get props => [response, escalated];
}

class WeeklyDigest extends Equatable {
  const WeeklyDigest({
    required this.id,
    required this.profileId,
    this.periodLabel = '',
    this.summary = '',
    this.score = 0,
    this.highlights = const [],
    this.attention = const [],
  });

  factory WeeklyDigest.fromJson(Map<String, dynamic> json) {
    return WeeklyDigest(
      id: json['id'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      periodLabel: json['period_label'] as String? ??
          '${json['iso_year'] ?? ''} W${json['iso_week'] ?? ''}',
      summary: json['summary'] as String? ?? json['narrative'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      highlights: _stringList(json['highlights']),
      attention: _stringList(json['attention']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  final String id;
  final String profileId;
  final String periodLabel;
  final String summary;
  final int score;
  final List<String> highlights;
  final List<String> attention;

  @override
  List<Object?> get props => [id, profileId, score];
}

class ShoppingListItem extends Equatable {
  const ShoppingListItem({
    required this.id,
    required this.name,
    this.purchased = false,
    this.kind,
  });

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['text'] as String? ?? '',
      purchased: json['purchased'] as bool? ?? json['done'] as bool? ?? false,
      kind: json['kind'] as String?,
    );
  }

  final String id;
  final String name;
  final bool purchased;
  final String? kind;

  ShoppingListItem copyWith({bool? purchased}) => ShoppingListItem(
        id: id,
        name: name,
        purchased: purchased ?? this.purchased,
        kind: kind,
      );

  @override
  List<Object?> get props => [id, name, purchased];
}

class MomentFeedItem extends Equatable {
  const MomentFeedItem({
    required this.id,
    required this.authorName,
    required this.caption,
    this.kind = 'note',
    this.reactions = 0,
    this.createdAt,
    this.liked = false,
  });

  factory MomentFeedItem.fromJson(Map<String, dynamic> json) {
    return MomentFeedItem(
      id: json['id'] as String? ?? '',
      authorName: json['author_name'] as String? ??
          json['author_display_name'] as String? ??
          'Care circle',
      caption: json['caption'] as String? ?? json['body'] as String? ?? '',
      kind: json['kind'] as String? ?? 'note',
      reactions: json['reactions'] as int? ?? json['reaction_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      liked: json['viewer_reacted'] as bool? ?? false,
    );
  }

  final String id;
  final String authorName;
  final String caption;
  final String kind;
  final int reactions;
  final String? createdAt;
  final bool liked;

  MomentFeedItem copyWith({bool? liked, int? reactions}) => MomentFeedItem(
        id: id,
        authorName: authorName,
        caption: caption,
        kind: kind,
        reactions: reactions ?? this.reactions,
        createdAt: createdAt,
        liked: liked ?? this.liked,
      );

  @override
  List<Object?> get props => [id, caption, liked];
}

class FamilyCircleMember extends Equatable {
  const FamilyCircleMember({
    required this.id,
    required this.name,
    this.role = 'member',
    this.email,
  });

  factory FamilyCircleMember.fromJson(Map<String, dynamic> json) {
    return FamilyCircleMember(
      id: json['id'] as String? ?? json['profile_id'] as String? ?? '',
      name: json['name'] as String? ?? json['display_name'] as String? ?? 'Member',
      role: json['role'] as String? ?? 'member',
      email: json['email'] as String?,
    );
  }

  final String id;
  final String name;
  final String role;
  final String? email;

  @override
  List<Object?> get props => [id, name];
}

class FamilyCircle extends Equatable {
  const FamilyCircle({
    required this.id,
    required this.name,
    this.members = const [],
    this.guardianIds = const [],
  });

  factory FamilyCircle.fromJson(Map<String, dynamic> json) {
    final memberRows = json['members'] as List? ?? [];
    return FamilyCircle(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Family circle',
      members: memberRows
          .whereType<Map<String, dynamic>>()
          .map(FamilyCircleMember.fromJson)
          .toList(),
      guardianIds: (json['guardian_user_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  final String id;
  final String name;
  final List<FamilyCircleMember> members;
  final List<String> guardianIds;

  @override
  List<Object?> get props => [id, name];
}

class FamilyCirclesData extends Equatable {
  const FamilyCirclesData({
    this.asOwner = const [],
    this.asGuardian = const [],
  });

  factory FamilyCirclesData.fromJson(Map<String, dynamic> json) {
    List<FamilyCircle> parse(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(FamilyCircle.fromJson)
          .toList();
    }

    return FamilyCirclesData(
      asOwner: parse(json['as_owner']),
      asGuardian: parse(json['as_guardian']),
    );
  }

  final List<FamilyCircle> asOwner;
  final List<FamilyCircle> asGuardian;

  List<FamilyCircle> get all => [...asOwner, ...asGuardian];

  @override
  List<Object?> get props => [asOwner, asGuardian];
}

class VoiceIntentResult extends Equatable {
  const VoiceIntentResult({
    required this.intent,
    required this.transcript,
    this.confidence = 0,
    this.actionTaken,
    this.chatResponse,
  });

  factory VoiceIntentResult.fromJson(Map<String, dynamic> json) {
    final chat = json['chat'] as Map<String, dynamic>?;
    return VoiceIntentResult(
      intent: json['intent'] as String? ?? 'unknown',
      transcript: json['transcript'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      actionTaken: json['action_taken'] as String?,
      chatResponse: chat?['response'] as String?,
    );
  }

  final String intent;
  final String transcript;
  final double confidence;
  final String? actionTaken;
  final String? chatResponse;

  String get displayReply =>
      chatResponse ??
      actionTaken ??
      'I heard you. Try asking about medications, reminders, or your health plan.';

  @override
  List<Object?> get props => [intent, transcript];
}

class TelehealthPartner extends Equatable {
  const TelehealthPartner({
    required this.id,
    required this.name,
    this.description,
    this.url,
  });

  factory TelehealthPartner.fromJson(Map<String, dynamic> json) {
    return TelehealthPartner(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Partner',
      description: json['description'] as String?,
      url: json['url'] as String? ?? json['handoff_url'] as String?,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? url;

  @override
  List<Object?> get props => [id, name];
}
