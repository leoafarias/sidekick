import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick/src/modules/projects/detail/project_version.dart';

import '../../helpers/fixtures.dart';

void main() {
  String bump(String version, VersionBump bump) =>
      bumpVersion(Version.parse(version), bump).toString();

  group('bumpVersion', () {
    test('bumps semver parts and keeps the build number', () {
      expect(bump('1.2.3+4', VersionBump.major), '2.0.0+4');
      expect(bump('1.2.3+4', VersionBump.minor), '1.3.0+4');
      expect(bump('1.2.3+4', VersionBump.patch), '1.2.4+4');
      expect(bump('1.2.3', VersionBump.patch), '1.2.4');
    });

    test('bumps the build number', () {
      expect(bump('1.2.3+4', VersionBump.build), '1.2.3+5');
      expect(bump('1.2.3', VersionBump.build), '1.2.3+1');
      expect(bump('1.0.0-beta.1+9', VersionBump.build), '1.0.0-beta.1+10');
    });

    test('bumps a pre-release to the release it leads to', () {
      expect(bump('1.0.0-beta.1+3', VersionBump.patch), '1.0.0+3');
      expect(bump('0.9.0-dev', VersionBump.minor), '0.9.0');
      expect(bump('2.0.0-dev.1', VersionBump.major), '2.0.0');
      expect(bump('2.1.0-dev.1', VersionBump.major), '3.0.0');
    });

    test('cannot bump a build number that is not an integer', () {
      expect(
        bumpVersion(Version.parse('1.0.0+abc'), VersionBump.build),
        isNull,
      );
      expect(
        bumpVersion(Version.parse('1.0.0+1.2'), VersionBump.build),
        isNull,
      );
    });
  });

  group('pubspec version', () {
    test('reads the version', () {
      expect(readPubspecVersion(flutterPubspec()), '1.2.3+4');
      expect(readPubspecVersion('name: app\n'), isNull);
    });

    test('writes only the version and keeps comments', () {
      final pubspec = flutterPubspec();
      final updated = setPubspecVersion(pubspec, Version.parse('2.0.0+5'));

      expect(updated, pubspec.replaceFirst('1.2.3+4', '2.0.0+5'));
    });

    test('adds a missing version', () {
      final updated = setPubspecVersion(
        'name: app\nenvironment:\n  sdk: ^3.0.0\n',
        Version.parse('1.0.0+1'),
      );

      expect(readPubspecVersion(updated), '1.0.0+1');
      expect(updated, startsWith('name: app\nenvironment:\n  sdk: ^3.0.0\n'));
    });
  });
}
