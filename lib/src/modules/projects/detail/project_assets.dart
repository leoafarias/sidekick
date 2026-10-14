import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Image extensions that can be previewed
const previewableImageExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.bmp',
};

/// Folder names Flutter uses for resolution-aware images, like `2.0x`
final _variantFolderPattern = RegExp(r'^\d+(\.\d+)?x$');

/// Whether [name] is a resolution variant folder such as `2.0x` or `3x`
bool isResolutionVariantFolder(String name) {
  return _variantFolderPattern.hasMatch(name);
}

/// An entry in an assets folder
sealed class AssetEntry {
  const AssetEntry(this.path);

  /// Absolute path
  final String path;

  /// File or folder name
  String get name => p.basename(path);
}

/// A sub folder
class AssetFolder extends AssetEntry {
  /// Constructor
  const AssetFolder(super.path);
}

/// A file, with its resolution variants collapsed into a single entry
class AssetFile extends AssetEntry {
  /// Constructor
  const AssetFile(super.path, {this.variants = const []});

  /// Resolution variants found next to the file, like `[2.0, 3.0]`.
  ///
  /// Includes 1.0 when the main (1x) file exists and other variants do too.
  final List<double> variants;

  /// Whether the file can be previewed as an image
  bool get isImage =>
      previewableImageExtensions.contains(p.extension(path).toLowerCase());
}

/// Lists [directory] like Flutter resolves assets: `2.0x`/`3.0x` folders are
/// hidden and their files are shown as variants of the main file.
///
/// When only variants exist, the entry points to the highest resolution.
Future<List<AssetEntry>> listAssetFolder(String directory) async {
  final folders = <AssetFolder>[];
  final mainFiles = <String, String>{};
  final variants = <String, Map<double, String>>{};

  await for (final entity in Directory(directory).list(followLinks: false)) {
    final name = p.basename(entity.path);
    if (name.startsWith('.')) continue;

    if (entity is Directory || (entity is Link && _isDirectory(entity))) {
      if (isResolutionVariantFolder(name)) {
        final ratio = double.parse(name.substring(0, name.length - 1));
        await for (final file
            in Directory(entity.path).list(followLinks: false)) {
          final fileName = p.basename(file.path);
          if (file is! File || fileName.startsWith('.')) continue;
          variants.putIfAbsent(fileName, () => {})[ratio] = file.path;
        }
      } else {
        folders.add(AssetFolder(entity.path));
      }
    } else if (entity is File) {
      mainFiles[name] = entity.path;
    }
  }

  final files = <AssetFile>[];
  for (final name in {...mainFiles.keys, ...variants.keys}) {
    final byRatio = variants[name] ?? const {};
    final main = mainFiles[name];
    final ratios = [
      if (main != null && byRatio.isNotEmpty) 1.0,
      ...byRatio.keys
    ]..sort();
    final path = main ?? byRatio[ratios.last]!;
    files.add(AssetFile(path, variants: ratios));
  }

  int byName(AssetEntry a, AssetEntry b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
  folders.sort(byName);
  files.sort(byName);
  return [...folders, ...files];
}

bool _isDirectory(Link link) {
  try {
    return FileSystemEntity.isDirectorySync(link.path);
  } on FileSystemException {
    return false;
  }
}

/// Top-level folders holding the project's assets.
///
/// Uses the folders declared under `flutter: assets:` in pubspec.yaml, plus
/// `assets` if it exists, so projects that keep images in `images/` or
/// `res/` are covered too.
List<String> assetRootFolders(String projectPath, String pubspecYaml) {
  final roots = <String>{};

  try {
    final pubspec = loadYaml(pubspecYaml);
    final flutter = pubspec is YamlMap ? pubspec['flutter'] : null;
    final assets = flutter is YamlMap ? flutter['assets'] : null;
    if (assets is YamlList) {
      for (final asset in assets) {
        // Since Flutter 3.22 an asset can be a map with a `path` key
        final value = asset is YamlMap ? asset['path'] : asset;
        if (value is! String) continue;
        final segments = p.posix.split(p.posix.normalize(value));
        if (segments.isEmpty || segments.first == '..') continue;
        if (segments.length == 1 && !value.endsWith('/')) continue;
        roots.add(segments.first);
      }
    }
  } on YamlException {
    // Fall back to the assets folder
  }
  roots.add('assets');

  return roots
      .where((root) => Directory(p.join(projectPath, root)).existsSync())
      .toList()
    ..sort();
}
