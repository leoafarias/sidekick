import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:i18next/i18next.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sidekick/src/theme.dart';

/// Loads translations straight from the `localizations` folder
class _FileDataSource implements LocalizationDataSource {
  @override
  Future<Map<Locale, Map<String, dynamic>>> load(List<Locale> locales) async {
    final result = <Locale, Map<String, dynamic>>{};
    for (final locale in locales) {
      final folder =
          'localizations/${locale.languageCode}-${locale.countryCode}';
      result[locale] = {
        for (final namespace in ['modules', 'components', 'settings'])
          namespace: jsonDecode(
            await File('$folder/$namespace.json').readAsString(),
          ),
      };
    }
    return result;
  }
}

/// Wraps [child] like the app does: theme, i18n, toasts and Riverpod
Widget testApp(
  Widget child, {
  List<Override> overrides = const [],
  Locale locale = const Locale('en', 'US'),
}) {
  return ProviderScope(
    overrides: overrides,
    retry: (_, __) => null,
    child: OKToast(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        locale: locale,
        supportedLocales: [locale],
        localizationsDelegates: [
          I18NextLocalizationDelegate(
            locales: [locale],
            dataSource: _FileDataSource(),
          ),
          ...GlobalMaterialLocalizations.delegates,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
}

/// Pumps until async work started by the widget tree has settled.
///
/// Real file IO doesn't advance with fake time, so this alternates between
/// running real async work and pumping frames.
Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps [child] inside [testApp] and waits until translations are loaded
Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(testApp(child, overrides: overrides));
  for (var i = 0; i < 100; i++) {
    if (find.byWidget(child).evaluate().isNotEmpty) break;
    await settle(tester, rounds: 1);
  }
  expect(find.byWidget(child), findsOneWidget);
}
