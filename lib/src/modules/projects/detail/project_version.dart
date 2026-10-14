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
/// Major, minor and patch bumps follow pub_semver: a pre-release bumps to
/// the release it leads to (`2.0.0-dev.1` -> `2.0.0` for major). They keep
/// the build number: stores require it to grow on every upload, so it is
/// bumped separately and never reset.
Version? bumpVersion(Version version, VersionBump bump) {
  final build = version.build.isEmpty ? null : version.build.join('.');
  Version withBuild(Version next) =>
      Version(next.major, next.minor, next.patch, build: build);

  switch (bump) {
    case VersionBump.major:
      return withBuild(version.nextMajor);
    case VersionBump.minor:
      return withBuild(version.nextMinor);
    case VersionBump.patch:
      return withBuild(version.nextPatch);
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
