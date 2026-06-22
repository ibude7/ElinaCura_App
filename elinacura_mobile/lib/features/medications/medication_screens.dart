import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/ec_theme.dart';
import '../../shared/models/models.dart';
import '../../core/theme/ec_tokens.dart';
import '../../shared/widgets/ec_glass.dart';
import '../../shared/widgets/ec_widgets.dart';

class OcrCaptureScreen extends ConsumerStatefulWidget {
  const OcrCaptureScreen({super.key});

  @override
  ConsumerState<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends ConsumerState<OcrCaptureScreen> {
  CameraController? _controller;
  OcrDraft? _draft;
  bool _loading = false;
  String? _error;

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _frequencyController = TextEditingController();

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _doseController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await _initCamera();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await _controller!.takePicture();
      await _upload(File(file.path));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _upload(File(file.path));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _upload(File image) async {
    final api = ref.read(apiClientProvider);
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path, filename: 'label.jpg'),
    });
    final data = await api.postMultipart<Map<String, dynamic>>(
      '/ocr/medication-label',
      formData: formData,
    );
    final draft = OcrDraft.fromJson(data);
    setState(() {
      _draft = draft;
      _nameController.text = draft.draft['medication_name']?.toString() ?? '';
      _doseController.text = draft.draft['dose']?.toString() ?? '';
      _frequencyController.text = draft.draft['frequency']?.toString() ?? '';
    });
  }

  Future<void> _confirm() async {
    final profileId = ref.read(activeProfileIdProvider);
    if (_draft == null || profileId == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<Map<String, dynamic>>(
        '/ocr/${_draft!.ocrId}/confirm',
        data: {
          'profile_id': profileId,
          'medication_name': _nameController.text,
          'dose': _doseController.text,
          'frequency': _frequencyController.text,
        },
      );
      ref.invalidate(healthOverviewProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medication added')));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Scan prescription'),
      body: _draft == null ? _buildCapture() : _buildReview(),
    );
  }

  Widget _buildCapture() {
    return Padding(
      padding: kEcGlassListPadding,
      child: Column(
        children: [
          EcScreenHero(
            eyebrow: 'Medication scan',
            title: 'Capture the label clearly',
            subtitle:
                'Use OCR to turn medication packaging into a draft you can review before saving.',
            icon: Icons.document_scanner_rounded,
            trailing: EcPill(label: 'Review first', tone: EcPillTone.info),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _controller?.value.isInitialized == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(EcTokens.radiusGlass),
                    child: CameraPreview(_controller!),
                  )
                : EcCard(
                    elevated: true,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 48,
                            color: EcColors.of(context).accentBrand,
                          ),
                          const SizedBox(height: 16),
                          EcGlassButton(
                            label: 'Start camera',
                            onPressed: _initCamera,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: EcColors.of(context).textCritical),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EcGlassButton(
                  label: 'Gallery',
                  outlined: true,
                  onPressed: _pickGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EcGlassButton(
                  label: _loading ? 'Processing…' : 'Capture',
                  loading: _loading,
                  onPressed: _loading ? null : _capture,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    return ListView(
      padding: kEcGlassListPadding,
      children: [
        const EcScreenHero(
          eyebrow: 'Review required',
          title: 'Confirm each field',
          subtitle:
              'AI extraction gives you a head start. Check details before adding this medication to your care record.',
          icon: Icons.fact_check_rounded,
          trailing: EcPill(label: 'Draft', tone: EcPillTone.caution),
        ),
        const SizedBox(height: 16),
        EcGlassSurface(
          variant: EcGlassVariant.elevated,
          borderRadius: EcTokens.radiusGlass,
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medication name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doseController,
                decoration: const InputDecoration(labelText: 'Dose'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _frequencyController,
                decoration: const InputDecoration(labelText: 'Frequency'),
              ),
            ],
          ),
        ),
        if (_draft!.lowConfidenceFields.isNotEmpty) ...[
          const SizedBox(height: 12),
          EcPill(
            label: 'Low confidence: ${_draft!.lowConfidenceFields.join(', ')}',
            tone: EcPillTone.caution,
          ),
        ],
        const SizedBox(height: 24),
        EcGlassButton(
          label: 'Save medication',
          loading: _loading,
          onPressed: _loading ? null : _confirm,
        ),
      ],
    );
  }
}

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Barcode scanner'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Scanned: $raw')));
              }
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EcScreenHero(
                eyebrow: 'Food and product safety',
                title: 'Center the barcode',
                subtitle:
                    'Scan groceries and labels to check them against your medication and health profile.',
                icon: Icons.qr_code_scanner_rounded,
                trailing: const EcPill(
                  label: 'Live',
                  tone: EcPillTone.positive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ref.watch(activeProfileIdProvider);
    if (profileId == null) {
      return EcGlassScaffold(
        appBar: const EcAppBar(title: 'Reminders'),
        body: const EcEmptyState(
          icon: Icons.person_search_rounded,
          title: 'Select a profile first',
          message:
              'Choose a care profile before scheduling medication reminders.',
        ),
      );
    }
    final reminders = ref.watch(remindersProvider(profileId));
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Reminders'),
      body: reminders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EcErrorState(
          message: 'Could not load reminders',
          onRetry: () => ref.invalidate(remindersProvider(profileId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EcEmptyState(
              icon: Icons.alarm_rounded,
              title: 'No reminders scheduled',
              message:
                  'Create reminders from your medication list to keep daily routines visible.',
            );
          }
          return ListView.separated(
            padding: kEcGlassListPadding,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = items[i];
              return EcGlassEntrance(
                index: i,
                child: EcCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcColors.of(context).accentAmberFill,
                        ),
                        child: Icon(
                          Icons.alarm_rounded,
                          color: EcColors.of(context).accentAmberText,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.medicationName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              [r.dose, r.nextDue, r.cadenceLabel]
                                  .whereType<String>()
                                  .where((s) => s.isNotEmpty)
                                  .join(' · '),
                              style: TextStyle(
                                color: EcColors.of(context).textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_active_rounded),
                        onPressed: () => _scheduleReminder(ref, r, i),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _scheduleReminder(
    WidgetRef ref,
    ReminderItem r,
    int index,
  ) async {
    final notif = ref.read(notificationServiceProvider);
    final scheduled = DateTime.now().add(const Duration(hours: 1));
    await notif.scheduleMedicationReminder(
      id: index,
      title: 'Time for ${r.medicationName}',
      body: r.dose ?? 'Take your medication',
      scheduledTime: scheduled,
    );
  }
}

class RefillCalendarScreen extends ConsumerWidget {
  const RefillCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Refill calendar'),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EcErrorState(
          message: 'Could not load medications',
          onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
        ),
        data: (data) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: EcScreenHero(
                eyebrow: 'Refill planning',
                title: 'Know what is running low',
                subtitle:
                    'Pair refill dates with your medication list so important prescriptions do not disappear from routine.',
                icon: Icons.calendar_month_rounded,
                trailing: EcPill(
                  label: '${data.medications.length} meds',
                  tone: EcPillTone.info,
                ),
              ),
            ),
            EcGlassSurface(
              variant: EcGlassVariant.subtle,
              margin: const EdgeInsets.all(16),
              borderRadius: EcTokens.radiusGlass,
              padding: EdgeInsets.zero,
              child: TableCalendar(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                calendarStyle: const CalendarStyle(markersMaxCount: 1),
              ),
            ),
            Expanded(
              child: ListView(
                padding: kEcGlassListPadding.copyWith(top: 0),
                children: data.medications
                    .asMap()
                    .entries
                    .map(
                      (e) => EcGlassEntrance(
                        index: e.key,
                        child: EcCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.medication_rounded,
                                color: EcColors.of(context).accentBrand,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.value.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      e.value.dose.isNotEmpty
                                          ? e.value.dose
                                          : 'No dose recorded',
                                      style: TextStyle(
                                        color: EcColors.of(
                                          context,
                                        ).textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
