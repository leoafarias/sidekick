import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/src/modules/projects/project_icon.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory temp;
  late String app;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('sidekick_icon_test');
    app = createFlutterApp(temp.path, platforms: []);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  String relative(File? file) =>
      p.relative(file!.path, from: app).replaceAll(r'\', '/');

  test('uses sidekick.icon from pubspec first', () async {
    writePng(app, 'assets/icon.png');
    writePng(app, 'assets/launcher.png');
    writeFile(
      app,
      'pubspec.yaml',
      flutterPubspec(extra: '''
sidekick:
  icon: assets/icon.png
flutter_launcher_icons:
  image_path: assets/launcher.png
'''),
    );

    expect(relative(await findProjectIcon(app)), 'assets/icon.png');
  });

  test('reads flutter_launcher_icons configs at the project root', () async {
    writePng(app, 'assets/launcher_dev.png');
    writePng(app, 'assets/launcher.png');
    writeFile(app, 'flutter_launcher_icons-dev.yaml',
        'flutter_launcher_icons:\n  image_path: assets/launcher_dev.png\n');
    writeFile(app, 'flutter_launcher_icons.yaml',
        'flutter_launcher_icons:\n  image_path: assets/launcher.png\n');

    expect(relative(await findProjectIcon(app)), 'assets/launcher.png');
  });

  test('ignores configs in nested folders and build outputs', () async {
    writePng(app, 'example/icon.png');
    writeFile(app, 'example/flutter_launcher_icons.yaml',
        'flutter_launcher_icons:\n  image_path: ../example/icon.png\n');
    writePng(app, 'build/logo.png');

    expect(await findProjectIcon(app), isNull);
  });

  test('falls back to a logo in assets, preferring the 1x image', () async {
    writePng(app, 'assets/images/3.0x/logo.png');
    writePng(app, 'assets/images/logo.png');
    writePng(app, 'assets/images/background.png');

    expect(relative(await findProjectIcon(app)), 'assets/images/logo.png');
  });

  test('falls back to platform launcher icons', () async {
    writePng(app, 'web/icons/Icon-192.png');
    writePng(app, 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png');

    expect(
      relative(await findProjectIcon(app)),
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    );
  });

  test('ignores invalid yaml and missing images', () async {
    writeFile(app, 'flutter_launcher_icons.yaml', ': : not yaml [');
    writeFile(
      app,
      'pubspec.yaml',
      flutterPubspec(extra: 'sidekick:\n  icon: assets/missing.png\n'),
    );

    expect(await findProjectIcon(app), isNull);
  });
}
