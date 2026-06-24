import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elinacura_mobile/core/theme/ec_theme.dart';
import 'package:elinacura_mobile/shared/widgets/ec_widgets.dart';

void main() {
  testWidgets('EcPill renders its label within the themed app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: withEcExtensions(EcTheme.light(), Brightness.light),
        home: const Scaffold(
          body: Center(
            child: EcPill(label: 'Stable', tone: EcPillTone.positive),
          ),
        ),
      ),
    );
    expect(find.text('Stable'), findsOneWidget);
  });
}
