import 'dart:convert';
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart';

/// Returns the Flutter SDK version of a cached [CacheVersion].
///
/// Older Flutter SDKs write the version to a `version` file at the SDK root.
/// Newer SDKs no longer create that file and store the version in
/// `bin/cache/flutter.version.json` instead. This checks the legacy file
/// first, then falls back to the JSON file.
///
/// Returns null when neither source is available, meaning the SDK
/// has not been set up yet.
String? getSdkVersionSync(CacheVersion cacheVersion) {
  final legacyVersion = FVMClient.getSdkVersionSync(cacheVersion);
  if (legacyVersion != null && legacyVersion.trim().isNotEmpty) {
    return legacyVersion.trim();
  }

  final jsonFile = File(
    join(cacheVersion.dir.path, 'bin', 'cache', 'flutter.version.json'),
  );
  if (!jsonFile.existsSync()) return null;

  try {
    final data = jsonDecode(jsonFile.readAsStringSync());
    if (data is! Map<String, dynamic>) return null;
    final version = data['frameworkVersion'] ?? data['flutterVersion'];
    if (version is String && version.trim().isNotEmpty) {
      return version.trim();
    }
  } on FormatException {
    // Malformed JSON: treat the SDK as not set up.
  } on FileSystemException {
    // Unreadable file: treat the SDK as not set up.
  }
  return null;
}
