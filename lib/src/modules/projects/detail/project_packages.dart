import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Pubspec section a dependency is declared in
enum DependencySection {
  /// `dependencies`
  dependencies('dependencies'),

  /// `dev_dependencies`
  devDependencies('dev_dependencies');

  const DependencySection(this.key);

  /// Key in pubspec.yaml
  final String key;
}

/// Where a dependency comes from
enum DependencySource {
  /// pub.dev
  pubDev,

  /// A third-party package server
  customHosted,

  /// `sdk: flutter`
  sdk,

  /// `path:`
  path,

  /// `git:`
  git,
}

/// How a dependency compares to its latest version on pub.dev
enum PackageStatus {
  /// Latest version unknown
  unknown,

  /// Resolved version is the latest
  upToDate,

  /// The latest version is allowed by the constraint, `pub upgrade` gets it
  upgradable,

  /// The constraint has to change to get the latest version
  constraintOutdated,
}

/// A dependency declared in pubspec.yaml
class ProjectPackage {
  /// Constructor
  const ProjectPackage({
    required this.name,
    required this.section,
    required this.source,
    this.constraint,
    this.resolved,
  });

  /// Package name
  final String name;

  /// Section it is declared in
  final DependencySection section;

  /// Source of the package
  final DependencySource source;

  /// Version constraint as written in pubspec.yaml (null for non-hosted)
  final String? constraint;

  /// Version resolved in pubspec.lock
  final Version? resolved;

  /// Whether the latest version can be looked up on pub.dev
  bool get isOnPubDev => source == DependencySource.pubDev;

  /// Parsed [constraint], null if missing or invalid
  VersionConstraint? get versionConstraint {
    final value = constraint;
    if (value == null) return null;
    try {
      return VersionConstraint.parse(value);
    } on FormatException {
      return null;
    }
  }

  /// Status compared to [latest]
  PackageStatus statusFor(Version? latest) {
    if (latest == null || !isOnPubDev) return PackageStatus.unknown;
    final current = resolved;
    // A pre-release newer than the latest stable is not outdated
    if (current != null && current >= latest) return PackageStatus.upToDate;

    final range = versionConstraint;
    if (range is VersionRange) {
      final min = range.min;
      // Constraint already ahead of the latest stable
      if (min != null && min > latest) return PackageStatus.upToDate;
    }
    if (range != null && !range.allows(latest)) {
      return PackageStatus.constraintOutdated;
    }
    if (current == null) return PackageStatus.unknown;
    return PackageStatus.upgradable;
  }

  /// Constraint to suggest when upgrading to [latest]
  static String constraintFor(Version latest) => '^$latest';
}

/// Reads the dependencies of a pubspec, with resolved versions from
/// [lockYaml] when available
List<ProjectPackage> readPackages(String pubspecYaml, String? lockYaml) {
  final pubspec = loadYaml(pubspecYaml);
  if (pubspec is! YamlMap) return const [];
  final resolved = _readLockVersions(lockYaml);

  final packages = <ProjectPackage>[];
  for (final section in DependencySection.values) {
    final deps = pubspec[section.key];
    if (deps is! YamlMap) continue;
    for (final entry in deps.entries) {
      final name = entry.key.toString();
      final (source, constraint) = _parseDependency(entry.value);
      packages.add(ProjectPackage(
        name: name,
        section: section,
        source: source,
        constraint: constraint,
        resolved: resolved[name],
      ));
    }
  }
  return packages;
}

(DependencySource, String?) _parseDependency(Object? value) {
  // `foo:` with no value means any version from pub.dev
  if (value == null) return (DependencySource.pubDev, 'any');
  if (value is! YamlMap) return (DependencySource.pubDev, value.toString());

  if (value.containsKey('sdk')) return (DependencySource.sdk, null);
  if (value.containsKey('path')) return (DependencySource.path, null);
  if (value.containsKey('git')) return (DependencySource.git, null);

  final constraint = value['version']?.toString() ?? 'any';
  final hosted = value['hosted'];
  final url = hosted is YamlMap ? hosted['url'] : hosted;
  if (url is String && !_isPubDev(url)) {
    return (DependencySource.customHosted, constraint);
  }
  return (DependencySource.pubDev, constraint);
}

bool _isPubDev(String url) {
  final host = Uri.tryParse(url)?.host;
  return host == 'pub.dev' || host == 'pub.dartlang.org';
}

Map<String, Version> _readLockVersions(String? lockYaml) {
  if (lockYaml == null) return const {};
  try {
    final lock = loadYaml(lockYaml);
    final packages = lock is YamlMap ? lock['packages'] : null;
    if (packages is! YamlMap) return const {};
    final versions = <String, Version>{};
    for (final entry in packages.entries) {
      final version = entry.value is YamlMap ? entry.value['version'] : null;
      if (version == null) continue;
      try {
        versions[entry.key.toString()] = Version.parse(version.toString());
      } on FormatException {
        continue;
      }
    }
    return versions;
  } on YamlException {
    return const {};
  }
}

/// Returns [pubspecYaml] with the constraint of [name] in [section] set to
/// [constraint]. Comments and formatting are kept.
///
/// Throws [ArgumentError] if the dependency is not a hosted dependency.
String setDependencyConstraint(
  String pubspecYaml,
  DependencySection section,
  String name,
  String constraint,
) {
  final editor = YamlEditor(pubspecYaml);
  final path = [section.key, name];
  final current = editor.parseAt(path, orElse: () {
    throw ArgumentError('$name is not in ${section.key}');
  });

  if (current is YamlMap) {
    final (source, _) = _parseDependency(current);
    if (source != DependencySource.pubDev &&
        source != DependencySource.customHosted) {
      throw ArgumentError('$name is not a hosted dependency');
    }
    editor.update([...path, 'version'], constraint);
  } else {
    editor.update(path, constraint);
  }
  return editor.toString();
}
