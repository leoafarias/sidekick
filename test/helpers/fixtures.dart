import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;

/// A 1x1 transparent PNG
final pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// Writes [content] to [relative] inside [root], creating parent folders
File writeFile(String root, String relative, String content) {
  final file = File(p.joinAll([root, ...relative.split('/')]));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
  return file;
}

/// Writes a PNG to [relative] inside [root]
File writePng(String root, String relative) {
  final file = File(p.joinAll([root, ...relative.split('/')]));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(pngBytes);
  return file;
}

/// Default pubspec for a fixture Flutter app
String flutterPubspec({
  String name = 'sample_app',
  String version = '1.2.3+4',
  String extra = '',
}) {
  return '''
name: $name
description: A sample Flutter app.
# Keep this comment
version: $version

environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.0 # networking
  path: ^1.8.0
  local_pkg:
    path: ../local_pkg

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^2.0.0
$extra''';
}

/// Lock file matching [flutterPubspec]
const pubspecLock = '''
packages:
  http:
    dependency: "direct main"
    description:
      name: http
      sha256: "abc"
      url: "https://pub.dev"
    source: hosted
    version: "0.13.6"
  path:
    dependency: "direct main"
    description:
      name: path
      sha256: "abc"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.0"
  lints:
    dependency: "direct dev"
    description:
      name: lints
      sha256: "abc"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.1"
sdks:
  dart: ">=3.5.0 <4.0.0"
''';

/// Creates a Flutter app fixture in [root]/[name] and returns its path
String createFlutterApp(
  String root, {
  String name = 'sample_app',
  String? pubspec,
  String? fvmrc = '{"flutter": "3.24.0"}',
  List<String> platforms = const ['android', 'ios', 'web'],
  bool withLock = true,
}) {
  final path = p.join(root, name);
  writeFile(path, 'pubspec.yaml', pubspec ?? flutterPubspec(name: name));
  if (withLock) writeFile(path, 'pubspec.lock', pubspecLock);
  if (fvmrc != null) writeFile(path, '.fvmrc', fvmrc);
  for (final platform in platforms) {
    Directory(p.join(path, platform)).createSync(recursive: true);
  }
  return path;
}

/// Writes a [size]x[size] PNG filled with [color] and a lighter circle.
///
/// Must run outside fake async (in `tester.runAsync` in widget tests).
Future<File> writeColorPng(
  String root,
  String relative,
  ui.Color color, {
  int size = 96,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final s = size.toDouble();
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Radius.circular(s / 5),
    ),
    ui.Paint()..color = color,
  );
  canvas.drawCircle(
    ui.Offset(s / 2, s / 2),
    s / 4,
    ui.Paint()..color = const ui.Color(0x88FFFFFF),
  );
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(p.joinAll([root, ...relative.split('/')]));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  return file;
}
