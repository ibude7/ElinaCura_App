import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/domain/api_result.dart';
import '../../core/health/dose_log.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/widgets/ec_glass.dart';

class MedicationProofSettings {
  const MedicationProofSettings({this.enabled = false});

  factory MedicationProofSettings.fromJson(Map<String, dynamic> json) {
    return MedicationProofSettings(
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  final bool enabled;
}

class MedicationProofRepository {
  MedicationProofRepository(this._api);

  final ApiClient _api;

  Future<ApiResult<MedicationProofSettings>> getSettings(String profileId) async {
    try {
      final data = await _api.get<Map<String, dynamic>>(
        '/medication-proof/settings/$profileId',
      );
      return ApiSuccess(MedicationProofSettings.fromJson(data));
    } catch (e) {
      return ApiFailure(formatApiError(e), e);
    }
  }
}

final medicationProofRepositoryProvider = Provider<MedicationProofRepository>(
  (ref) => MedicationProofRepository(ref.watch(apiClientProvider)),
);

final medicationProofEnabledProvider =
    FutureProvider.family<bool, String>((ref, profileId) async {
  final result =
      await ref.watch(medicationProofRepositoryProvider).getSettings(profileId);
  return result.valueOrNull?.enabled ?? false;
});

/// Optional accountability photo before marking a dose taken.
Future<bool> showMedicationProofSheet(
  BuildContext context, {
  required String medName,
  required String timeLabel,
}) async {
  final picker = ImagePicker();
  String? photoPath;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: EcGlassSurface(
              variant: EcGlassVariant.elevated,
              borderRadius: 24,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accountability photo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture proof for $medName at $timeLabel. When proof mode is enabled server-side, caregivers may verify doses.',
                    style: TextStyle(
                      color: EcColors.of(context).textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (photoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(photoPath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 12),
                  EcGlassButton(
                    label: photoPath == null ? 'Take photo' : 'Retake photo',
                    icon: Icons.photo_camera_rounded,
                    onPressed: () async {
                      final file = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        setLocal(() => photoPath = file.path);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  EcGlassButton(
                    label: photoPath == null
                        ? 'Mark taken without photo'
                        : 'Mark taken with photo',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  return result ?? false;
}

/// Marks a dose, optionally prompting for accountability photo when proof is on.
Future<void> markDoseWithOptionalProof({
  required BuildContext context,
  required WidgetRef ref,
  required String slotKey,
  required String medName,
  required String timeLabel,
}) async {
  final profileId = ref.read(healthOverviewProvider).valueOrNull?.profile?.id;
  var proofEnabled = false;
  if (profileId != null) {
    proofEnabled =
        await ref.read(medicationProofEnabledProvider(profileId).future);
  }

  if (proofEnabled && context.mounted) {
    final ok = await showMedicationProofSheet(
      context,
      medName: medName,
      timeLabel: timeLabel,
    );
    if (!ok || !context.mounted) return;
  }

  await ref.read(doseLogProvider.notifier).toggle(slotKey);
}
