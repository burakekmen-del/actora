import 'package:actora/app/actora_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Onboarding is shown on first launch',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: ActoraApp()));
    var onboardingVisible = false;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(ElevatedButton).evaluate().isNotEmpty) {
        onboardingVisible = true;
        break;
      }
    }

    expect(onboardingVisible, isTrue,
        reason: 'Onboarding primary action should become visible.');

    final hasContinue = find.text('Continue').evaluate().isNotEmpty ||
        find.text('Devam et').evaluate().isNotEmpty;
    final hasStart = find.text('Start').evaluate().isNotEmpty ||
        find.text('Başla').evaluate().isNotEmpty;

    expect(hasContinue || hasStart, isTrue,
        reason: 'Onboarding should show a localized primary action label.');
  });
}
