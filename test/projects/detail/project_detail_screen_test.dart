import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/src/modules/projects/detail/project_detail.provider.dart';
import 'package:sidekick/src/modules/projects/detail/project_detail.screen.dart';
import 'package:sidekick/src/modules/projects/detail/pub_dev_client.dart';
import 'package:sidekick/src/modules/projects/project.dto.dart';
import 'package:sidekick/src/modules/projects/projects.service.dart';
import 'package:sidekick/src/modules/settings/settings.dto.dart';
import 'package:sidekick/src/modules/settings/settings.provider.dart';

import '../../helpers/app.dart';
import '../../helpers/fixtures.dart';

/// Latest versions served by the fake pub.dev
const _latest = {
  'http': '1.2.2',
  'path': '1.9.1',
  'lints': '2.1.1',
};

PubDevClient _fakePubDev({bool offline = false}) {
  return PubDevClient(MockClient((request) async {
    if (offline) {
      throw const SocketException('Failed host lookup: pub.dev');
    }
    final name = request.url.pathSegments.last;
    final version = _latest[name];
    if (version == null) return http.Response('{}', 404);
    return http.Response(
        jsonEncode({
          'latest': {'version': version}
        }),
        200);
  }));
}

void main() {
  late Directory temp;
  late String app;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ProjectPathAdapter());
    }
  });

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('sidekick_detail_test');
    app = createFlutterApp(
      temp.path,
      name: 'weather_app',
      pubspec: flutterPubspec(
        name: 'weather_app',
        extra: '''
sidekick:
  icon: assets/icon.png

flutter:
  uses-material-design: true
  assets:
    - assets/
    - assets/images/
''',
      ),
      platforms: ['android', 'ios', 'macos', 'web'],
    );
    writeFile(app, 'assets/data/cities.json', '[]');
    writeFile(app, 'assets/fonts/README.md', '');

    // Fixture project stored through the app's own storage code
    Hive.init(p.join(temp.path, 'hive'));
    await ProjectsService.init();
    await ProjectsService.add(app);
  });

  tearDown(() async {
    await ProjectsService.close();
    await Hive.close();
    temp.deleteSync(recursive: true);
  });

  Future<void> writeImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      await writeColorPng(app, 'assets/icon.png', const Color(0xFF2196F3));
      for (final (name, color) in [
        ('logo.png', const Color(0xFF00BCD4)),
        ('banner.png', const Color(0xFFFF7043)),
        ('avatar.png', const Color(0xFF8BC34A)),
      ]) {
        await writeColorPng(app, 'assets/images/$name', color);
        await writeColorPng(app, 'assets/images/2.0x/$name', color);
        await writeColorPng(app, 'assets/images/3.0x/$name', color);
      }
      // Only provided in high resolution
      await writeColorPng(
          app, 'assets/images/3.0x/splash.png', const Color(0xFF9C27B0));
    });
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    ProjectDetailTab tab = ProjectDetailTab.overview,
    bool offline = false,
  }) async {
    setWindowSize(tester, const Size(1000, 640));
    await writeImages(tester);
    final project = ProjectsService.loadProject(app);
    expect(project.invalid, isFalse);

    await pumpTestApp(
      tester,
      ProjectDetailScreen(project, initialTab: tab),
      overrides: [
        pubDevClientProvider.overrideWithValue(_fakePubDev(offline: offline)),
        sidekickSettingsProvider.overrideWithValue(SidekickSettings()),
      ],
    );
    await settle(tester);
  }

  String pubspec() => File(p.join(app, 'pubspec.yaml')).readAsStringSync();

  testWidgets('overview shows project information', (tester) async {
    await pumpDetail(tester);

    expect(find.text('weather_app'), findsWidgets);
    expect(find.text('v1.2.3+4'), findsOneWidget);
    expect(find.text('A sample Flutter app.'), findsOneWidget);
    expect(find.text('3.24.0'), findsOneWidget);
    expect(find.text('^3.5.0'), findsOneWidget);
    for (final platform in ['Android', 'iOS', 'macOS', 'Web']) {
      expect(find.text(platform), findsOneWidget);
    }
    expect(find.text('Windows'), findsNothing);
    expect(
      find.text('4 dependencies, 2 dev dependencies'),
      findsOneWidget,
    );

    await takeScreenshot(tester, 'project_detail_overview');
  });

  testWidgets('packages compares with pub.dev and upgrades a constraint',
      (tester) async {
    await pumpDetail(tester, tab: ProjectDetailTab.packages);

    expect(find.text('Dependencies'), findsWidgets);
    expect(find.text('Dev dependencies'), findsOneWidget);
    expect(find.text('2 outdated'), findsOneWidget);
    expect(find.text('0.13.6'), findsOneWidget); // resolved http
    expect(find.text('1.2.2'), findsOneWidget); // latest http
    expect(find.text('sdk'), findsNWidgets(2));
    expect(find.text('path'), findsNWidgets(2)); // package and source
    expect(find.textContaining('pubspec.lock'), findsNothing);

    await takeScreenshot(tester, 'project_detail_packages');

    // Only http needs a constraint change
    expect(find.text('Upgrade'), findsOneWidget);
    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade http?'), findsOneWidget);
    expect(find.textContaining('from ^0.13.0 to ^1.2.2'), findsOneWidget);

    await takeScreenshot(tester, 'project_detail_packages_upgrade');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Upgrade'));
    await settle(tester);

    expect(pubspec(), contains('  http: ^1.2.2 # networking\n'));
    // pubspec.lock no longer matches until pub get runs
    expect(find.textContaining('Run flutter pub get'), findsOneWidget);
    expect(find.text('Upgrade'), findsNothing);

    // Let the confirmation toast go away
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('packages handles pub.dev being unreachable', (tester) async {
    await pumpDetail(
      tester,
      tab: ProjectDetailTab.packages,
      offline: true,
    );

    expect(find.text('Could not reach pub.dev'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('outdated'), findsNothing);
    // Resolved versions still show
    expect(find.text('0.13.6'), findsOneWidget);

    await takeScreenshot(tester, 'project_detail_packages_offline');
  });

  testWidgets('assets collapses resolution variants', (tester) async {
    await pumpDetail(tester, tab: ProjectDetailTab.assets);

    // Root of the assets folder
    expect(find.text('images'), findsOneWidget);
    expect(find.text('data'), findsOneWidget);
    expect(find.text('icon.png'), findsOneWidget);

    await tester.tap(find.text('images'));
    await settle(tester);

    expect(find.text('logo.png'), findsOneWidget);
    expect(find.text('splash.png'), findsOneWidget);
    expect(find.text('2.0x'), findsNothing);
    expect(find.text('3.0x'), findsNothing);
    expect(find.text('1x 2x 3x'), findsNWidgets(3));
    expect(find.text('3x'), findsOneWidget);

    await takeScreenshot(tester, 'project_detail_assets');

    // Breadcrumb back to the root
    await tester.tap(find.text('assets'));
    await settle(tester);
    expect(find.text('data'), findsOneWidget);
  });

  testWidgets('version bumps and sets the version', (tester) async {
    await pumpDetail(tester, tab: ProjectDetailTab.version);

    expect(find.text('1.2.3+4'), findsWidgets);
    expect(find.text('2.0.0+4'), findsOneWidget);
    expect(find.text('1.3.0+4'), findsOneWidget);
    expect(find.text('1.2.4+4'), findsOneWidget);
    expect(find.text('1.2.3+5'), findsOneWidget);

    await takeScreenshot(tester, 'project_detail_version');

    await tester.tap(find.text('Minor'));
    await settle(tester);
    expect(pubspec(), contains('\nversion: 1.3.0+4\n'));
    expect(find.text('v1.3.0+4'), findsOneWidget);

    await tester.tap(find.text('Build'));
    await settle(tester);
    expect(pubspec(), contains('\nversion: 1.3.0+5\n'));

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.pump();
    expect(find.text('Invalid version'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2.0.0+10');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);
    // Only the version changed
    expect(
      pubspec(),
      flutterPubspec(name: 'weather_app', version: '2.0.0+10', extra: '''
sidekick:
  icon: assets/icon.png

flutter:
  uses-material-design: true
  assets:
    - assets/
    - assets/images/
'''),
    );

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('shows an error when pubspec.yaml is invalid', (tester) async {
    setWindowSize(tester, const Size(1000, 640));
    final project = ProjectsService.loadProject(app);
    writeFile(app, 'pubspec.yaml', '- not a map');

    await pumpTestApp(
      tester,
      ProjectDetailScreen(project),
      overrides: [
        pubDevClientProvider.overrideWithValue(_fakePubDev()),
        sidekickSettingsProvider.overrideWithValue(SidekickSettings()),
      ],
    );
    await settle(tester);

    expect(find.textContaining('Could not read pubspec.yaml'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
