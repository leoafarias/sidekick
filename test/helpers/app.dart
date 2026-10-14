import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show Override;
import 'package:i18next/i18next.dart';
import 'package:oktoast/oktoast.dart';
import 'package:sidekick/src/modules/settings/settings.dto.dart';
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
    child: RepaintBoundary(
      key: screenshotKey,
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
              options: kI18NextOptions,
            ),
            ...GlobalMaterialLocalizations.delegates,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: child,
        ),
      ),
    ),
  );
}

/// Key of the boundary captured by [takeScreenshot]
final screenshotKey = GlobalKey();

/// Saves a PNG of the app to `$SCREENSHOT_DIR/<name>.png` when the
/// SCREENSHOT_DIR environment variable is set
Future<void> takeScreenshot(WidgetTester tester, String name) async {
  final dir = Platform.environment['SCREENSHOT_DIR'];
  if (dir == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(screenshotKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(
      pixelRatio: tester.view.devicePixelRatio,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Sets the window size used by a test
void setWindowSize(WidgetTester tester, Size size, {double pixelRatio = 2}) {
  tester.view.devicePixelRatio = pixelRatio;
  tester.view.physicalSize = size * pixelRatio;
  addTearDown(tester.view.reset);
}

/// Pumps until async work started by the widget tree has settled.
///
/// Real file IO doesn't advance with fake time, and each await on IO needs a
/// pump to run its continuation, so this alternates between letting real
/// async work run and pumping frames.
Future<void> settle(WidgetTester tester, {int rounds = 60}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
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
