import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Writes immutable access-log entries so users can see exactly who viewed
/// what health data and when — trust is everything in this category.
///
/// Entries land in the top-level `access_log` collection. Writes are
/// best-effort and never throw into the UI.
class AuditLogService {
  AuditLogService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> record({
    required String action,
    required String target,
    String? patientId,
  }) async {
    try {
      await _db.collection('access_log').add({
        'actor': FirebaseAuth.instance.currentUser?.uid,
        'action': action,
        'target': target,
        'patientId': ?patientId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best-effort; auditing must not disrupt the caregiver experience.
    }
  }

  /// Convenience: a caregiver viewed a patient's health snapshot.
  Future<void> recordCaregiverView(String patientId) =>
      record(action: 'view', target: 'caregiver_dashboard', patientId: patientId);

  /// Live stream of recent access events for [patientId] (newest first).
  Stream<List<AccessLogEntry>> watch(String patientId, {int limit = 50}) {
    return _db
        .collection('access_log')
        .where('patientId', isEqualTo: patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AccessLogEntry.fromDoc(d.data())).toList());
  }
}

class AccessLogEntry {
  const AccessLogEntry({
    required this.actor,
    required this.action,
    required this.target,
    this.timestamp,
  });

  factory AccessLogEntry.fromDoc(Map<String, dynamic> d) => AccessLogEntry(
        actor: d['actor'] as String? ?? 'unknown',
        action: d['action'] as String? ?? '',
        target: d['target'] as String? ?? '',
        timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
      );

  final String actor;
  final String action;
  final String target;
  final DateTime? timestamp;
}

final auditLogServiceProvider =
    Provider<AuditLogService>((ref) => AuditLogService());
