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
import '../../core/health/dose_log.dart';
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

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null || raw.isEmpty) return;
    setState(() => _handled = true);
    _controller.stop();
    _showResult(raw);
  }

  void _resume() {
    if (!mounted) return;
    setState(() => _handled = false);
    _controller.start();
  }

  Future<void> _showResult(String code) async {
    final ec = EcColors.of(context);
    await showEcGlassSheet(
      context,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ec.accentBrand.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.qr_code_2_rounded,
                    color: ec.accentBrand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code scanned',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      code,
                      style: TextStyle(color: ec.textSecondary, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Captured. Cross-checking products against your medications for '
            'interactions is on the roadmap — for now the code is recorded.',
            style: TextStyle(color: ec.textMuted, fontSize: 12.5, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: EcGlassButton(
                  label: 'Scan again',
                  outlined: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resume();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EcGlassButton(
                  label: 'Done',
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (mounted) context.pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
    // Resume scanning if the sheet was dismissed by dragging (not a button).
    if (mounted && _handled) _resume();
  }

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
          tooltip: 'Close scanner',
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
          MobileScanner(controller: _controller, onDetect: _onDetect),

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
    final overview = ref.watch(healthOverviewProvider);
    return EcGlassScaffold(
      appBar: const EcAppBar(title: 'Reminders'),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EcErrorState(
          message: 'Could not load your medications',
          onRetry: () => ref.read(healthOverviewProvider.notifier).retry(),
        ),
        data: (data) {
          if (data.medications.isEmpty) {
            return EcEmptyState(
              icon: Icons.alarm_rounded,
              title: 'No medications yet',
              message:
                  'Add medications to your profile and reminders build '
                  'automatically from their schedule.',
              action: EcGlassButton(
                label: 'Go to medications',
                onPressed: () => context.push('/health'),
              ),
            );
          }
          return _RemindersBody(medications: data.medications);
        },
      ),
    );
  }
}

class _RemindersBody extends ConsumerStatefulWidget {
  const _RemindersBody({required this.medications});

  final List<MedicationItem> medications;

  @override
  ConsumerState<_RemindersBody> createState() => _RemindersBodyState();
}

class _RemindersBodyState extends ConsumerState<_RemindersBody> {
  bool _busy = false;

  Future<void> _enableReminders() async {
    setState(() => _busy = true);
    try {
      final notif = ref.read(notificationServiceProvider);
      await notif.initialize();
      await notif.syncMedicationReminders(widget.medications);
      final count = widget.medications
          .fold<int>(0, (sum, m) => sum + m.times.length);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled $count daily reminder${count == 1 ? '' : 's'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not schedule reminders: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final scheduled =
        widget.medications.where((m) => m.hasSchedule).toList();
    final asNeeded =
        widget.medications.where((m) => !m.hasSchedule).toList();
    final totalSlots = scheduled.fold<int>(0, (sum, m) => sum + m.times.length);

    return ListView(
      padding: kEcGlassListPadding,
      children: [
        EcGlassSurface(
          variant: EcGlassVariant.elevated,
          borderRadius: EcTokens.radiusGlass,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily reminders',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                totalSlots == 0
                    ? 'None of your medications have a fixed schedule yet.'
                    : 'Turn on $totalSlots daily '
                        'notification${totalSlots == 1 ? '' : 's'} built from '
                        'your schedule. Tap a dose below to mark it taken.',
                style: TextStyle(
                  color: ec.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              if (totalSlots > 0) ...[
                const SizedBox(height: 16),
                EcGlassButton(
                  label: _busy ? 'Scheduling…' : 'Turn on reminders',
                  icon: _busy ? null : Icons.notifications_active_rounded,
                  loading: _busy,
                  onPressed: _busy ? null : _enableReminders,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < scheduled.length; i++)
          EcGlassEntrance(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReminderMedCard(med: scheduled[i]),
            ),
          ),
        if (asNeeded.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: EcSectionTitle(title: 'As needed'),
          ),
          for (final m in asNeeded)
            EcGlassListTile(
              icon: Icons.medication_outlined,
              title: m.name,
              subtitle: m.dose.isNotEmpty ? m.dose : 'No fixed schedule',
              trailing: const SizedBox.shrink(),
            ),
        ],
      ],
    );
  }
}

class _ReminderMedCard extends ConsumerWidget {
  const _ReminderMedCard({required this.med});

  final MedicationItem med;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ec = EcColors.of(context);
    final log = ref.watch(doseLogProvider).valueOrNull ?? const {};
    final takenToday = log[dayKey(DateTime.now())] ?? const <String>{};

    return EcGlassSurface(
      variant: EcGlassVariant.elevated,
      borderRadius: EcTokens.radiusCard,
      padding: const EdgeInsets.all(16),
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
                  color: ec.accentBrand.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: ec.accentBrand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      [if (med.dose.isNotEmpty) med.dose, med.schedule]
                          .join(' · '),
                      style: TextStyle(color: ec.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final time in med.times)
                _DoseChip(
                  label: _formatSlot(time),
                  taken: takenToday.contains(doseSlotKey(med.id, time)),
                  onTap: () => ref
                      .read(doseLogProvider.notifier)
                      .toggle(doseSlotKey(med.id, time)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoseChip extends StatelessWidget {
  const _DoseChip({
    required this.label,
    required this.taken,
    required this.onTap,
  });

  final String label;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ec = EcColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = taken ? EcTokens.statusPositive : ec.textMuted;

    return Semantics(
      button: true,
      selected: taken,
      label: '$label dose, ${taken ? 'taken' : 'not taken'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EcTokens.radiusFull),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: taken
                  ? EcTokens.statusPositive
                      .withValues(alpha: isDark ? 0.18 : 0.14)
                  : Colors.white.withValues(alpha: isDark ? 0.06 : 0.5),
              borderRadius: BorderRadius.circular(EcTokens.radiusFull),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  taken ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 15,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: taken
                        ? color
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatSlot(String hhmm) {
  final parts = hhmm.split(':');
  var h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? parts[1] : '00';
  final mer = h >= 12 ? 'PM' : 'AM';
  if (h == 0) {
    h = 12;
  } else if (h > 12) {
    h -= 12;
  }
  return m == '00' ? '$h $mer' : '$h:$m $mer';
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
                                    color: ec.accentBrand
                                        .withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    Icons.medication_rounded,
                                    color: ec.accentBrand,
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
