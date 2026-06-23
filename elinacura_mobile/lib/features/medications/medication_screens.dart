import 'dart:io';
import 'dart:ui';

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

// ═══════════════════════════════════════════════ OCR CAPTURE SCREEN ══

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
      _frequencyController.text =
          draft.draft['frequency']?.toString() ?? '';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Medication added')));
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Scan label',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          if (_draft != null)
            TextButton(
              onPressed: () => setState(() => _draft = null),
              child: const Text('Retake'),
            ),
        ],
      ),
      body: _draft == null ? _buildCapture() : _buildReview(),
    );
  }

  Widget _buildCapture() {
    final isReady = _controller?.value.isInitialized == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        if (isReady)
          ClipRRect(
            child: CameraPreview(_controller!),
          )
        else
          const ColoredBox(color: Colors.black),

        // Glass frame overlay
        if (isReady)
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EcTokens.radiusCard),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.60),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.10),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),

        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: EcTokens.glassBlurZ4,
                sigmaY: EcTokens.glassBlurZ4,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.paddingOf(context).bottom + 20,
                ),
                color: EcGlass.of(context).fillFloat,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isReady
                          ? 'Align the label inside the frame'
                          : 'Camera access required to scan labels',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: EcTokens.statusCritical,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: EcGlassButton(
                            label: 'Gallery',
                            outlined: true,
                            icon: Icons.photo_library_rounded,
                            onPressed: _pickGallery,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EcGlassButton(
                            label: _loading
                                ? 'Processing…'
                                : isReady
                                    ? 'Capture'
                                    : 'Start camera',
                            loading: _loading,
                            icon: _loading ? null : Icons.camera_alt_rounded,
                            onPressed: _loading ? null : _capture,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview() {
    return ListView(
      padding: kEcGlassListPadding,
      children: [
        // ── Header
        EcGlassEntrance(
          index: 0,
          child: EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: EcTokens.radiusGlass,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EcColors.of(context)
                            .accentBrand
                            .withValues(alpha: 0.14),
                      ),
                      child: Icon(
                        Icons.fact_check_rounded,
                        color: EcColors.of(context).accentBrand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Review & confirm',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'AI filled these — confirm before saving.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_draft?.lowConfidenceFields.isNotEmpty ?? false)
                      EcPill(
                        label: 'Review required',
                        tone: EcPillTone.caution,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Fields
        EcGlassEntrance(
          index: 1,
          child: EcGlassSurface(
            variant: EcGlassVariant.elevated,
            borderRadius: EcTokens.radiusGlass,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Medication name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _doseController,
                  decoration: const InputDecoration(labelText: 'Dose'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _frequencyController,
                  decoration:
                      const InputDecoration(labelText: 'Frequency'),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: EcTokens.statusCritical,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 24),
        EcGlassButton(
          label: 'Save medication',
          icon: Icons.check_rounded,
          loading: _loading,
          onPressed: _loading ? null : _confirm,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════ SCANNER SCREEN ══

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Barcode scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Scanned: $raw')),
                );
              }
            },
          ),

          // Glass viewfinder ring
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.08),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Bottom glass overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: EcTokens.glassBlurZ4,
                  sigmaY: EcTokens.glassBlurZ4,
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Center a barcode in the ring',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scans groceries and labels for medication interactions',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════ REMINDERS SCREEN ══

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
            return EcEmptyState(
              icon: Icons.alarm_rounded,
              title: 'No reminders scheduled',
              message:
                  'Reminders are created automatically from your medication list.',
              action: EcGlassButton(
                label: 'Go to medications',
                onPressed: () => context.push('/health'),
              ),
            );
          }
          return ListView.builder(
            padding: kEcGlassListPadding,
            itemCount: items.length,
            itemBuilder: (context, i) {
              final r = items[i];
              return EcGlassEntrance(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: EcTimelineNode(
                    time: r.nextDue ?? r.cadenceLabel ?? '—',
                    label: '${r.medicationName}${(r.dose?.isNotEmpty ?? false) ? ' — ${r.dose}' : ''}',
                    done: false,
                    isLast: i == items.length - 1,
                    onTap: () => _scheduleReminder(ref, r, i),
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

// ═══════════════════════════════════════════ REFILL CALENDAR SCREEN ══

class RefillCalendarScreen extends ConsumerWidget {
  const RefillCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(healthOverviewProvider);
    final ec = EcColors.of(context);

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
            // ── Glass calendar
            EcGlassSurface(
              variant: EcGlassVariant.elevated,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              borderRadius: EcTokens.radiusGlass,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TableCalendar(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                calendarStyle: CalendarStyle(
                  markersMaxCount: 1,
                  todayDecoration: BoxDecoration(
                    color: ec.accentBrand.withValues(alpha: 0.30),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: ec.accentBrand,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: EcTokens.fontFamily,
                  ),
                  weekendTextStyle: TextStyle(
                    color: ec.textSecondary,
                    fontFamily: EcTokens.fontFamily,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleTextStyle: TextStyle(
                    fontFamily: EcTokens.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: ec.accentBrand,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: ec.accentBrand,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EcSectionTitle(
                title: 'All medications',
                action: EcPill(
                  label: '${data.medications.length} tracked',
                  tone: EcPillTone.info,
                ),
              ),
            ),

            // ── Medications list
            Expanded(
              child: data.medications.isEmpty
                  ? EcEmptyState(
                      icon: Icons.medication_rounded,
                      title: 'No medications tracked',
                      message:
                          'Add medications to your profile to see refill schedules here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      itemCount: data.medications.length,
                      itemBuilder: (context, i) {
                        final m = data.medications[i];
                        return EcGlassEntrance(
                          index: i,
                          child: EcGlassSurface(
                            variant: EcGlassVariant.elevated,
                            borderRadius: EcTokens.radiusCard,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ec.accentMint
                                        .withValues(alpha: 0.14),
                                  ),
                                  child: Icon(
                                    Icons.medication_rounded,
                                    color: ec.accentMint,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      if (m.dose.isNotEmpty == true)
                                        Text(
                                          m.dose,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: ec.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (m.schedule.isNotEmpty)
                                  EcPill(
                                    label: m.schedule,
                                    tone: EcPillTone.neutral,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
