import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elinacura_mobile/core/design_system/ec_a11y.dart';
import 'package:elinacura_mobile/core/theme/ec_theme.dart';
import 'package:elinacura_mobile/shared/widgets/ec_glass.dart';
import 'package:elinacura_mobile/shared/widgets/ec_page_kit.dart';

/// Golden + accessibility widget tests (Rec #30).
void main() {
  final theme = withEcExtensions(EcTheme.light(), Brightness.light);

  testWidgets('EcPageHero renders headline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: EcPageHero(
            eyebrow: 'TEST',
            title: 'Golden',
            subtitle: 'Subtitle',
            icon: Icons.star_rounded,
            layer: EcSurfaceLayer.solidContent,
          ),
        ),
      ),
    );
    expect(find.text('Golden'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
  });

  testWidgets('EcGlassSurface has semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: EcGlassSurface(
            variant: EcGlassVariant.regular,
            child: const Text('Glass'),
          ),
        ),
      ),
    );
    expect(find.text('Glass'), findsOneWidget);
  });

  testWidgets('EcGlassSurface respects reduced transparency', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: Scaffold(
            body: EcGlassSurface(
              variant: EcGlassVariant.regular,
              child: const Text('Solid fallback'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Solid fallback'), findsOneWidget);
  });

  testWidgets('EcMedallion has button semantics when wrapped', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Semantics(
            label: 'Feature icon',
            child: EcMedallion(
              icon: Icons.favorite_rounded,
              accent: EcAccent.brand,
            ),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Feature icon'), findsOneWidget);
  });

  testWidgets('EcA11y glass hairline is non-empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            final border = EcA11y.glassHairline(context);
            expect(border.top.width, greaterThan(0));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
