import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/src/theme.dart';

/// Runs before every test file
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Use Roboto instead of fetching IBM Plex Sans from Google Fonts
  appTextTheme = ([textTheme]) =>
      (textTheme ?? ThemeData.dark().textTheme).apply(fontFamily: 'Roboto');

  await _loadFonts();
  await testMain();
}

/// Loads real fonts so screenshots are readable instead of using the Ahem
/// test font, which renders every glyph as a box.
Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final dir = Directory(
      p.join(flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
    );
    if (dir.existsSync()) {
      final roboto = FontLoader('Roboto');
      for (final file in dir.listSync().whereType<File>()) {
        final name = p.basename(file.path);
        if (name.startsWith('Roboto-') && !name.contains('Italic')) {
          roboto.addFont(_bytes(file));
        }
      }
      await roboto.load();
    }
  }

  const iconFonts = {
    'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    'packages/material_design_icons_flutter/Material Design Icons':
        'packages/material_design_icons_flutter/lib/fonts/materialdesignicons-webfont.ttf',
  };
  for (final entry in iconFonts.entries) {
    try {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load(entry.value));
      await loader.load();
    } catch (_) {
      // Icons render as boxes without the font, tests still work
    }
  }
}

Future<ByteData> _bytes(File file) async {
  final bytes = await file.readAsBytes();
  return ByteData.view(bytes.buffer);
}
