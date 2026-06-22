import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elinacura_mobile/core/theme/ec_theme.dart';
import 'package:elinacura_mobile/features/auth/onboarding_view.dart';

void main() {
  final errors = <String>[];
  late void Function(FlutterErrorDetails)? previous;

  setUp(() {
    errors.clear();
    previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.toString());
  });

  tearDown(() => FlutterError.onError = previous);

  Future<void> drive(WidgetTester tester, {required Size size, required double dpr, required Brightness brightness}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = dpr;
    final theme = brightness == Brightness.dark
        ? withEcExtensions(EcTheme.dark(), Brightness.dark)
        : withEcExtensions(EcTheme.light(), Brightness.light);
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: theme, home: const OnboardingScreen()));
    await tester.pump(const Duration(milliseconds: 120));
    for (var i = 0; i < 8; i++) {
      for (var f = 0; f < 5; f++) {
        await tester.pump(const Duration(milliseconds: 180));
      }
      await tester.drag(find.byType(PageView), const Offset(-700, 0), warnIfMissed: false);
      for (var f = 0; f < 5; f++) {
        await tester.pump(const Duration(milliseconds: 140));
      }
    }
  }

  testWidgets('heart-circle care + flow renders overflow-free', (tester) async {
    for (final (size, dpr) in <(Size, double)>[
      (const Size(1170, 2532), 3.0),
      (const Size(750, 1334), 2.0),
    ]) {
      for (final brightness in Brightness.values) {
        await drive(tester, size: size, dpr: dpr, brightness: brightness);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final relevant = errors.where((e) => e.contains('overflowed') || e.contains('onboarding_view.dart:') || e.contains('RenderFlex')).toList();
    expect(relevant, isEmpty, reason: relevant.join('\n\n'));
  });
}
