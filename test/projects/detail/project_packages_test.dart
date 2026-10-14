import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick/src/modules/projects/detail/project_details.dart';
import 'package:sidekick/src/modules/projects/detail/project_packages.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('readPackages', () {
    test('reads direct and dev dependencies with resolved versions', () {
      final packages = readPackages(flutterPubspec(), pubspecLock);
      final byName = {for (final p in packages) p.name: p};

      expect(packages.map((p) => p.name),
          ['flutter', 'http', 'path', 'local_pkg', 'flutter_test', 'lints']);
      expect(byName['flutter']!.source, DependencySource.sdk);
      expect(byName['local_pkg']!.source, DependencySource.path);
      expect(byName['http']!.constraint, '^0.13.0');
      expect(byName['http']!.resolved, Version.parse('0.13.6'));
      expect(byName['http']!.section, DependencySection.dependencies);
      expect(byName['lints']!.section, DependencySection.devDependencies);
      expect(byName['lints']!.resolved, Version.parse('2.1.1'));
    });

    test('understands every dependency form', () {
      const pubspec = '''
name: app
dependencies:
  any_version:
  hosted_map:
    version: ">=1.0.0 <3.0.0"
  custom:
    hosted: https://packages.example.com
    version: ^1.0.0
  legacy_hosted:
    hosted:
      name: legacy_hosted
      url: https://pub.dartlang.org
    version: ^2.0.0
  from_git:
    git:
      url: https://example.com/repo.git
''';
      final byName = {for (final p in readPackages(pubspec, null)) p.name: p};

      expect(byName['any_version']!.constraint, 'any');
      expect(byName['any_version']!.source, DependencySource.pubDev);
      expect(byName['hosted_map']!.constraint, '>=1.0.0 <3.0.0');
      expect(byName['custom']!.source, DependencySource.customHosted);
      expect(byName['legacy_hosted']!.source, DependencySource.pubDev);
      expect(byName['from_git']!.source, DependencySource.git);
      expect(byName['from_git']!.constraint, isNull);
    });
  });

  group('statusFor', () {
    ProjectPackage package(String constraint, String? resolved) {
      return ProjectPackage(
        name: 'foo',
        section: DependencySection.dependencies,
        source: DependencySource.pubDev,
        constraint: constraint,
        resolved: resolved == null ? null : Version.parse(resolved),
      );
    }

    final latest = Version.parse('2.1.0');

    test('compares resolved and latest versions', () {
      expect(
          package('^2.0.0', '2.1.0').statusFor(latest), PackageStatus.upToDate);
      expect(package('^2.0.0', '2.0.0').statusFor(latest),
          PackageStatus.upgradable);
      expect(package('^1.0.0', '1.5.0').statusFor(latest),
          PackageStatus.constraintOutdated);
      expect(
          package('any', '1.0.0').statusFor(latest), PackageStatus.upgradable);
    });

    test('is not outdated when ahead of the latest stable', () {
      expect(package('^3.0.0-dev', '3.0.0-dev.2').statusFor(latest),
          PackageStatus.upToDate);
      expect(package('^3.0.0', null).statusFor(latest), PackageStatus.upToDate);
    });

    test('is unknown without a latest version or for other sources', () {
      expect(package('^1.0.0', '1.0.0').statusFor(null), PackageStatus.unknown);
      const sdk = ProjectPackage(
        name: 'flutter',
        section: DependencySection.dependencies,
        source: DependencySource.sdk,
      );
      expect(sdk.statusFor(latest), PackageStatus.unknown);
    });
  });

  group('setDependencyConstraint', () {
    test('updates a scalar constraint and keeps comments', () {
      final pubspec = flutterPubspec();
      final updated = setDependencyConstraint(
        pubspec,
        DependencySection.dependencies,
        'http',
        '^1.2.0',
      );

      expect(
        updated,
        pubspec.replaceFirst(
          'http: ^0.13.0 # networking',
          'http: ^1.2.0 # networking',
        ),
      );
    });

    test('updates dev dependencies and map constraints', () {
      const pubspec = '''
name: app
dev_dependencies:
  lints: ^2.0.0
dependencies:
  foo:
    hosted: https://packages.example.com
    version: ^1.0.0
''';
      var updated = setDependencyConstraint(
          pubspec, DependencySection.devDependencies, 'lints', '^5.0.0');
      updated = setDependencyConstraint(
          updated, DependencySection.dependencies, 'foo', '^2.0.0');

      expect(updated, '''
name: app
dev_dependencies:
  lints: ^5.0.0
dependencies:
  foo:
    hosted: https://packages.example.com
    version: ^2.0.0
''');
    });

    test('refuses non-hosted and missing dependencies', () {
      final pubspec = flutterPubspec();
      expect(
        () => setDependencyConstraint(
            pubspec, DependencySection.dependencies, 'local_pkg', '^1.0.0'),
        throwsArgumentError,
      );
      expect(
        () => setDependencyConstraint(
            pubspec, DependencySection.dependencies, 'missing', '^1.0.0'),
        throwsArgumentError,
      );
    });
  });

  test('isLockInSync detects a lock that needs pub get', () {
    expect(isLockInSync(readPackages(flutterPubspec(), pubspecLock)), isTrue);

    final changed = setDependencyConstraint(
        flutterPubspec(), DependencySection.dependencies, 'http', '^1.2.0');
    expect(isLockInSync(readPackages(changed, pubspecLock)), isFalse);

    final added = flutterPubspec()
        .replaceFirst('  path: ^1.8.0', '  path: ^1.8.0\n  collection: ^1.0.0');
    expect(isLockInSync(readPackages(added, pubspecLock)), isFalse);
  });
}
