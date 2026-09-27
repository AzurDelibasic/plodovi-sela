import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plodovi_sela/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme builds a valid light ThemeData', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: Text('Plodovi sela')),
        ),
      ),
    );

    expect(find.text('Plodovi sela'), findsOneWidget);
  });
}
