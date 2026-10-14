import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/src/modules/projects/detail/project_assets.dart';
import 'package:sidekick/src/modules/projects/detail/project_details.dart';

import '../../helpers/fixtures.dart';

void main() {
  late Directory temp;
  late String app;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('sidekick_assets_test');
    app = createFlutterApp(temp.path);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  test('collapses resolution variants into one entry', () async {
    final images = p.join(app, 'assets', 'images');
    writePng(images, 'logo.png');
    writePng(images, '2.0x/logo.png');
    writePng(images, '3.0x/logo.png');
    writePng(images, '3.0x/only_hd.png');
    writePng(images, 'Banner.jpg');
    writeFile(images, 'data.json', '{}');
    writeFile(images, '.DS_Store', '');
    writePng(images, 'icons/home.png');

    final entries = await listAssetFolder(images);

    expect(entries.map((e) => e.name),
        ['icons', 'Banner.jpg', 'data.json', 'logo.png', 'only_hd.png']);
    expect(entries.first, isA<AssetFolder>());

    final files = {for (final e in entries.whereType<AssetFile>()) e.name: e};
    expect(files['logo.png']!.variants, [1.0, 2.0, 3.0]);
    expect(files['logo.png']!.path, p.join(images, 'logo.png'));
    expect(files['only_hd.png']!.variants, [3.0]);
    expect(files['only_hd.png']!.path, p.join(images, '3.0x', 'only_hd.png'));
    expect(files['Banner.jpg']!.variants, isEmpty);
    expect(files['Banner.jpg']!.isImage, isTrue);
    expect(files['data.json']!.isImage, isFalse);
  });

  test('recognizes variant folder names', () {
    expect(isResolutionVariantFolder('2.0x'), isTrue);
    expect(isResolutionVariantFolder('3x'), isTrue);
    expect(isResolutionVariantFolder('1.5x'), isTrue);
    expect(isResolutionVariantFolder('x'), isFalse);
    expect(isResolutionVariantFolder('2.0x_old'), isFalse);
  });

  test('finds asset folders declared in pubspec', () {
    Directory(p.join(app, 'images')).createSync();
    Directory(p.join(app, 'assets')).createSync();
    Directory(p.join(app, 'fonts')).createSync();
    final pubspec = flutterPubspec(extra: '''
flutter:
  assets:
    - images/icons/
    - path: assets/flavored/
      flavors: [dev]
    - missing/
    - logo.png
    - ../outside/
''');

    expect(assetRootFolders(app, pubspec), ['assets', 'images']);
  });

  test('loads project details', () async {
    writeFile(app, 'pubspec.yaml', flutterPubspec());

    final details = await loadProjectDetails(app);

    expect(details.version.toString(), '1.2.3+4');
    expect(details.description, 'A sample Flutter app.');
    expect(details.dartSdk, '^3.5.0');
    expect(details.platforms,
        [ProjectPlatform.android, ProjectPlatform.ios, ProjectPlatform.web]);
    expect(details.packages, hasLength(6));
    expect(details.lockOutdated, isFalse);

    File(p.join(app, 'pubspec.lock')).deleteSync();
    expect((await loadProjectDetails(app)).lockOutdated, isTrue);
  });
}
