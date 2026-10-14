import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'project_assets.dart';
import 'project_packages.dart';
import 'project_version.dart';

/// Platforms a Flutter project can target, by folder name
enum ProjectPlatform {
  /// android/
  android,

  /// ios/
  ios,

  /// macos/
  macos,

  /// web/
  web,

  /// windows/
  windows,

  /// linux/
  linux,
}

/// Snapshot of a project's pubspec and folders, read from disk
class ProjectDetails {
  /// Constructor
  const ProjectDetails({
    required this.path,
    required this.pubspecYaml,
    required this.rawVersion,
    required this.description,
    required this.dartSdk,
    required this.packages,
    required this.platforms,
    required this.assetRoots,
    required this.lockOutdated,
  });

  /// Project path
  final String path;

  /// pubspec.yaml contents
  final String pubspecYaml;

  /// `version` as written, null if missing
  final String? rawVersion;

  /// `description`
  final String? description;

  /// `environment.sdk` constraint
  final String? dartSdk;

  /// Declared dependencies
  final List<ProjectPackage> packages;

  /// Platforms that have a folder in the project
  final List<ProjectPlatform> platforms;

  /// Folders holding assets, relative to [path]
  final List<String> assetRoots;

  /// pubspec.lock is missing or doesn't match pubspec.yaml, so
  /// `flutter pub get` needs to run
  final bool lockOutdated;

  /// Parsed [rawVersion], null if missing or invalid
  Version? get version {
    final value = rawVersion;
    if (value == null) return null;
    try {
      return Version.parse(value);
    } on FormatException {
      return null;
    }
  }
}

/// Reads the details of the project at [path].
///
/// Throws if pubspec.yaml can't be read or parsed.
Future<ProjectDetails> loadProjectDetails(String path) async {
  final pubspecFile = File(p.join(path, 'pubspec.yaml'));
  final lockFile = File(p.join(path, 'pubspec.lock'));

  final pubspecYaml = await pubspecFile.readAsString();
  final pubspec = loadYaml(pubspecYaml);
  if (pubspec is! YamlMap) {
    throw const FormatException('pubspec.yaml is not a map');
  }

  final lockYaml =
      await lockFile.exists() ? await lockFile.readAsString() : null;
  final overridesFile = File(p.join(path, 'pubspec_overrides.yaml'));
  final overridesYaml = await overridesFile.exists()
      ? await overridesFile.readAsString()
      : null;
  final packages =
      readPackages(pubspecYaml, lockYaml, overridesYaml: overridesYaml);
  // Workspace members are resolved in the workspace root's pubspec.lock
  final isWorkspaceMember = pubspec['resolution'] == 'workspace';

  final environment = pubspec['environment'];
  final platforms = [
    for (final platform in ProjectPlatform.values)
      if (await Directory(p.join(path, platform.name)).exists()) platform,
  ];

  return ProjectDetails(
    path: path,
    pubspecYaml: pubspecYaml,
    rawVersion: readPubspecVersion(pubspecYaml),
    description: pubspec['description']?.toString(),
    dartSdk: environment is YamlMap ? environment['sdk']?.toString() : null,
    packages: packages,
    platforms: platforms,
    assetRoots: assetRootFolders(path, pubspecYaml),
    lockOutdated:
        !isWorkspaceMember && (lockYaml == null || !isLockInSync(packages)),
  );
}

/// Whether every hosted dependency is resolved in pubspec.lock to a version
/// its constraint allows
bool isLockInSync(List<ProjectPackage> packages) {
  for (final package in packages) {
    if (package.source != DependencySource.pubDev &&
        package.source != DependencySource.customHosted) {
      continue;
    }
    if (package.overridden) continue;
    final resolved = package.resolved;
    if (resolved == null) return false;
    final constraint = package.versionConstraint;
    if (constraint != null && !constraint.allows(resolved)) return false;
  }
  return true;
}
