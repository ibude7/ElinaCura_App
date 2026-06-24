import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import '../domain/api_result.dart';

/// Structured clinical artifact exports (Rec #33, #44).
class ClinicalArtifactsRepository {
  ClinicalArtifactsRepository(this._api);

  final ApiClient _api;

  Future<ApiResult<ReportExport>> exportReport(
    String profileId, {
    List<String> sections = const ['summary', 'medications', 'vitals'],
    bool includeFhir = false,
  }) async {
    try {
      final data = await _api.post<Map<String, dynamic>>(
        '/report/$profileId/export',
        data: {
          'sections': sections,
          'include_fhir': includeFhir,
        },
      );
      return ApiSuccess(ReportExport.fromJson(data));
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<ApiResult<TelehealthHandoff>> getTelehealthHandoff(
    String profileId,
  ) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/telehealth/$profileId/handoff',
      );
      return ApiSuccess(TelehealthHandoff.fromJson(data));
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }

  Future<ApiResult<TravelPlanArtifact>> createTravelPlan(
    String profileId, {
    required String originTz,
    required String destinationTz,
    int days = 5,
  }) async {
    try {
      final data = await _api.post<Map<String, dynamic>>(
        '/travel/$profileId/plan',
        data: {
          'origin_tz': originTz,
          'destination_tz': destinationTz,
          'days': days,
        },
      );
      return ApiSuccess(TravelPlanArtifact.fromJson(data));
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }
}

class ReportExport {
  const ReportExport({this.pdfUrl, this.fhirBundleUrl, this.summary = ''});

  factory ReportExport.fromJson(Map<String, dynamic> json) => ReportExport(
        pdfUrl: json['pdf_url'] as String?,
        fhirBundleUrl: json['fhir_bundle_url'] as String?,
        summary: json['summary'] as String? ?? '',
      );

  final String? pdfUrl;
  final String? fhirBundleUrl;
  final String summary;
}

class TelehealthHandoff {
  const TelehealthHandoff({this.packetUrl, this.partnerUrl, this.summary = ''});

  factory TelehealthHandoff.fromJson(Map<String, dynamic> json) =>
      TelehealthHandoff(
        packetUrl: json['packet_url'] as String?,
        partnerUrl: json['partner_url'] as String?,
        summary: json['summary'] as String? ?? '',
      );

  final String? packetUrl;
  final String? partnerUrl;
  final String summary;
}

class TravelPlanArtifact {
  const TravelPlanArtifact({this.planSummary = '', this.shifts = const []});

  factory TravelPlanArtifact.fromJson(Map<String, dynamic> json) =>
      TravelPlanArtifact(
        planSummary: json['plan_summary'] as String? ?? '',
        shifts: (json['dose_shifts'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(
                  (e) => '${e['med']}: ${e['from']} → ${e['to']}',
                )
                .toList() ??
            const [],
      );

  final String planSummary;
  final List<String> shifts;
}

final clinicalArtifactsRepositoryProvider =
    Provider<ClinicalArtifactsRepository>(
  (ref) => ClinicalArtifactsRepository(ref.watch(apiClientProvider)),
);
