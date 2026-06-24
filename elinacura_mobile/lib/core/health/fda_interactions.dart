import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Checks a newly captured medication against the user's existing medications
/// using the public openFDA drug label API (drug_interactions field).
///
/// Network/parse failures resolve to an empty list — interaction checking is
/// best-effort and must never block the medication review flow.
class FdaInteractionService {
  FdaInteractionService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;
  static const _base = 'https://api.fda.gov/drug/label.json';

  /// Returns human-readable interaction warnings between [newMed] and any of
  /// [existingMeds]. Empty when none found or the lookup fails.
  Future<List<String>> checkAgainstExisting({
    required String newMed,
    required List<String> existingMeds,
  }) async {
    final query = newMed.trim();
    if (query.isEmpty || existingMeds.isEmpty) return const [];
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        _base,
        queryParameters: {
          'search':
              'openfda.generic_name:"$query" openfda.brand_name:"$query"',
          'limit': 1,
        },
      );
      final results = resp.data?['results'];
      if (results is! List || results.isEmpty) return const [];
      final first = results.first as Map<String, dynamic>;
      final interactions = first['drug_interactions'];
      if (interactions is! List || interactions.isEmpty) return const [];
      final text = interactions.join(' ').toLowerCase();
      final warnings = <String>[];
      for (final med in existingMeds) {
        final name = med.trim().toLowerCase();
        if (name.length < 3) continue;
        if (text.contains(name)) {
          warnings.add('$query may interact with $med. Review with a clinician.');
        }
      }
      return warnings;
    } catch (_) {
      return const [];
    }
  }
}

final fdaInteractionServiceProvider =
    Provider<FdaInteractionService>((ref) => FdaInteractionService());
