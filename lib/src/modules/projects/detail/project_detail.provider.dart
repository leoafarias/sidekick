import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../projects.provider.dart';
import 'project_assets.dart';
import 'project_details.dart';
import 'project_packages.dart';
import 'project_version.dart';
import 'pub_dev_client.dart';

/// Path of the project open in the detail view, null shows the list
final selectedProjectProvider = StateProvider<String?>((_) => null);

/// pub.dev client. Overridden in tests.
final pubDevClientProvider = Provider<PubDevClient>((ref) {
  final client = PubDevClient(http.Client());
  ref.onDispose(client.close);
  return client;
});

/// Details of the project at a path, read from disk
final projectDetailsProvider =
    FutureProvider.autoDispose.family<ProjectDetails, String>(
  (ref, path) => loadProjectDetails(path),
  retry: (_, __) => null,
);

/// Latest version of a package on pub.dev.
///
/// Kept for the session so switching tabs or projects doesn't refetch.
/// Errors are not retried automatically, the user can retry from the UI.
final latestVersionProvider = FutureProvider.family<Version, String>(
  (ref, package) => ref.watch(pubDevClientProvider).latestVersion(package),
  retry: (_, __) => null,
);

/// Entries of an assets folder
final assetFolderProvider =
    FutureProvider.autoDispose.family<List<AssetEntry>, String>(
  (ref, directory) => listAssetFolder(directory),
  retry: (_, __) => null,
);

/// Edits to a project's pubspec.yaml
final projectEditorProvider = Provider(ProjectEditor.new);

/// Edits a project's pubspec.yaml.
///
/// Every edit re-reads the file first, so changes made in an editor since
/// the details were loaded are not overwritten.
class ProjectEditor {
  /// Constructor
  ProjectEditor(this._ref);

  final Ref _ref;

  File _pubspec(String path) => File(p.join(path, 'pubspec.yaml'));

  /// Bumps the version. Returns the new version.
  ///
  /// A missing version is treated as 0.0.0.
  Future<Version> bump(String path, VersionBump bump) async {
    final yaml = await _pubspec(path).readAsString();
    final raw = readPubspecVersion(yaml);
    final current = raw == null ? Version.none : Version.parse(raw);
    final next = bumpVersion(current, bump);
    if (next == null) {
      throw FormatException('Cannot bump the build number of $raw');
    }
    await _write(path, setPubspecVersion(yaml, next));
    return next;
  }

  /// Sets the version
  Future<void> setVersion(String path, Version version) async {
    final yaml = await _pubspec(path).readAsString();
    await _write(path, setPubspecVersion(yaml, version));
  }

  /// Sets the constraint of a hosted dependency.
  ///
  /// Doesn't run `pub get`: IDEs run it when pubspec.yaml changes, and the
  /// packages view shows that pubspec.lock is out of date until it runs.
  Future<void> setConstraint(
    String path,
    ProjectPackage package,
    String constraint,
  ) async {
    final yaml = await _pubspec(path).readAsString();
    final updated = setDependencyConstraint(
      yaml,
      package.section,
      package.name,
      constraint,
    );
    await _write(path, updated);
  }

  Future<void> _write(String path, String yaml) async {
    // Write to a temp file and rename it over pubspec.yaml, so a failure
    // mid-write (full disk, crash) can't leave the pubspec truncated
    final pubspec = _pubspec(path);
    final temp = File('${pubspec.path}.sidekick-tmp');
    try {
      await temp.writeAsString(yaml, flush: true);
      await temp.rename(pubspec.path);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    }
    _ref.invalidate(projectDetailsProvider(path));
    await _ref.read(projectsProvider.notifier).reloadPath(path);
  }
}
