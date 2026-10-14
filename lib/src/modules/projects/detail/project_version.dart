import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Part of the app version to bump
enum VersionBump {
  /// 1.2.3+4 -> 2.0.0+4
  major,

  /// 1.2.3+4 -> 1.3.0+4
  minor,

  /// 1.2.3+4 -> 1.2.4+4
  patch,

  /// 1.2.3+4 -> 1.2.3+5
  build,
}

/// Returns [version] bumped by [bump], or null if it can't be bumped
/// (a build number that is not a single integer).
///
/// Major, minor and patch bumps drop any pre-release and keep the build
/// number: stores require the build number to grow on every upload, so it
/// is bumped separately and never reset.
Version? bumpVersion(Version version, VersionBump bump) {
  final build = version.build.isEmpty ? null : version.build.join('.');

  switch (bump) {
    case VersionBump.major:
      return Version(version.major + 1, 0, 0, build: build);
    case VersionBump.minor:
      return Version(version.major, version.minor + 1, 0, build: build);
    case VersionBump.patch:
      return Version(
        version.major,
        version.minor,
        version.patch + 1,
        build: build,
      );
    case VersionBump.build:
      final current = version.build;
      int next;
      if (current.isEmpty) {
        next = 1;
      } else if (current.length == 1 && current.first is int) {
        next = (current.first as int) + 1;
      } else {
        return null;
      }
      final pre =
          version.preRelease.isEmpty ? null : version.preRelease.join('.');
      return Version(
        version.major,
        version.minor,
        version.patch,
        pre: pre,
        build: '$next',
      );
  }
}

/// Reads the `version` field of a pubspec, or null if missing
String? readPubspecVersion(String pubspecYaml) {
  final doc = loadYaml(pubspecYaml);
  if (doc is! YamlMap) return null;
  final version = doc['version'];
  return version?.toString();
}

/// Returns [pubspecYaml] with its `version` set to [version].
///
/// Only the version value is rewritten, comments and formatting are kept.
String setPubspecVersion(String pubspecYaml, Version version) {
  final editor = YamlEditor(pubspecYaml);
  editor.update(['version'], version.toString());
  return editor.toString();
}
