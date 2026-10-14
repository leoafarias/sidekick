import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18next/i18next.dart';
import 'package:sidekick/src/modules/ide/components/ide_selection_tile.dart';
import 'package:sidekick/src/modules/ide/components/open_in_ide_button.dart';
import 'package:sidekick/src/modules/ide/ide.provider.dart';
import 'package:sidekick/src/modules/ide/ide_launcher.dart';
import 'package:sidekick/src/modules/settings/settings.dto.dart';

import 'fake_ide_environment.dart';

/// A Mac with Cursor and Claude installed, nothing else
FakeIdeEnvironment _machine() {
  return FakeIdeEnvironment(
    platform: HostPlatform.macos,
    variables: {'HOME': '/Users/me', 'PATH': '/usr/bin:/bin'},
    directories: ['/Applications/Cursor.app', '/Applications/Claude.app'],
  );
}

/// Reads the real localization files synchronously, so loading completes
/// inside the fake async zone of widget tests.
class _FileLocalizationDataSource implements LocalizationDataSource {
  @override
  Future<Map<Locale, Map<String, dynamic>>> load(List<Locale> locales) {
    return SynchronousFuture({
      for (final locale in locales)
        locale: {
          for (final file
              in Directory('localizations/${locale.toLanguageTag()}')
                  .listSync()
                  .whereType<File>())
            file.uri.pathSegments.last.replaceAll('.json', ''):
                json.decode(file.readAsStringSync()),
        },
    });
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  const locale = Locale('en', 'US');
  await tester.pumpWidget(
    ProviderScope(
      overrides: [ideEnvironmentProvider.overrideWithValue(_machine())],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [locale],
        localizationsDelegates: [
          I18NextLocalizationDelegate(
            locales: const [locale],
            dataSource: _FileLocalizationDataSource(),
          ),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('settings IDE picker', () {
    testWidgets('lists only detected launchers, None and custom',
        (tester) async {
      final settings = AllSettings.create();
      await _pump(tester, IdeSelectionTile(settings, () {}));

      expect(find.text('None'), findsOneWidget);
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();

      expect(find.text('Cursor'), findsWidgets);
      expect(find.text('Claude'), findsWidgets);
      expect(find.text('Custom application'), findsWidgets);
      expect(find.text('VS Code'), findsNothing);
      expect(find.text('Xcode'), findsNothing);
    });

    testWidgets('selecting a launcher saves its id', (tester) async {
      final settings = AllSettings.create();
      var saved = 0;
      await _pump(tester, IdeSelectionTile(settings, () => saved++));

      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cursor').last);
      await tester.pumpAndSettle();

      expect(settings.sidekick.ide, 'Cursor');
      expect(saved, 1);
    });

    testWidgets('a saved launcher that is no longer installed is flagged',
        (tester) async {
      final settings = AllSettings.create(
        sidekick: SidekickSettings(ide: 'VSCode'),
      );
      await _pump(tester, IdeSelectionTile(settings, () {}));

      expect(find.text('VS Code (not found)'), findsOneWidget);
      expect(
        find.text(
            'VS Code was not found on this computer. Choose another IDE.'),
        findsOneWidget,
      );
      // The stored value is kept until the user picks another one
      expect(settings.sidekick.ide, 'VSCode');
    });
  });

  group('project open in', () {
    testWidgets('menu lists detected launchers and the custom app',
        (tester) async {
      final settings = SidekickSettings(
        customIdeLocation: '/Applications/Nova.app',
      );
      await _pump(tester, OpenInIdeMenu('/work/app', settings));

      await tester.tap(find.byType(OpenInIdeMenu));
      await tester.pumpAndSettle();

      expect(find.text('Cursor'), findsOneWidget);
      expect(find.text('Claude'), findsOneWidget);
      expect(find.text('Custom application'), findsOneWidget);
      expect(find.text('Detect installed IDEs again'), findsOneWidget);
      expect(find.text('VS Code'), findsNothing);
    });

    testWidgets('quick button uses the selected launcher', (tester) async {
      await _pump(
        tester,
        OpenInSelectedIdeButton('/work/app', SidekickSettings(ide: 'Cursor')),
      );
      expect(find.byTooltip('Open in Cursor'), findsOneWidget);
    });

    testWidgets('quick button is hidden when the launcher is missing',
        (tester) async {
      await _pump(
        tester,
        OpenInSelectedIdeButton('/work/app', SidekickSettings(ide: 'VSCode')),
      );
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
