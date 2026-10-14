import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:fvm/fvm.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import 'project.dto.dart';

/// Normalizes a project [path] before it is stored.
///
/// Makes the path absolute and removes redundant separators, `.` and `..`
/// segments and trailing separators. The original casing is kept so the path
/// can still be displayed and used for file access.
String normalizeProjectPath(String path, {p.Context? context}) {
  final ctx = context ?? p.context;
  return ctx.normalize(ctx.absolute(path));
}

/// Whether two project paths point to the same directory.
///
/// Comparison is case-insensitive and separator-agnostic on Windows.
bool isSameProjectPath(String a, String b, {p.Context? context}) {
  final ctx = context ?? p.context;
  return ctx.equals(a, b);
}

/// Projects service
class ProjectsService {
  /// Constructor
  const ProjectsService._();

  /// Storage key
  ///
  /// Entries are stored with auto-increment keys. Paths are not used as
  /// keys because Hive limits string keys to 255 UTF-8 bytes and writes a
  /// corrupt box when a longer key (for example a deep or non-ASCII Windows
  /// path) is stored.
  static const _key = 'sidekick_projects';

  /// Storage key used up to Sidekick 1.1.x, which keyed entries by path
  static const _legacyKey = 'projects_service_box';

  static Box<ProjectRef>? _box;

  /// Storage box
  static Box<ProjectRef> get box {
    final box = _box;
    if (box == null) {
      throw StateError('ProjectsService.init() has not been called');
    }
    return box;
  }

  /// Initializes the service
  static Future<void> init() async {
    _box = await Hive.openBox<ProjectRef>(_key);
    await _migrateLegacyBox();
  }

  /// Closes the storage. Used by tests.
  @visibleForTesting
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Moves projects from the legacy path-keyed box into the current box.
  ///
  /// If the legacy box can't be read (for example because it was corrupted
  /// by an over-long key), it is left on disk untouched and the app starts
  /// with the projects that could be recovered.
  static Future<void> _migrateLegacyBox() async {
    try {
      if (!await Hive.boxExists(_legacyKey)) return;
      final legacy = await _openBoxGuarded(_legacyKey);
      for (final ref in legacy.values) {
        await add(ref.path);
      }
      await legacy.deleteFromDisk();
    } catch (e, stackTrace) {
      debugPrint('Could not migrate saved projects: $e\n$stackTrace');
    }
  }

  /// Opens a box, reporting a failure only through the returned future.
  ///
  /// When opening fails, Hive also completes an internal future nobody
  /// listens to, which would surface as an uncaught async error.
  static Future<Box<ProjectRef>> _openBoxGuarded(String name) {
    final completer = Completer<Box<ProjectRef>>();
    runZonedGuarded(() async {
      completer.complete(await Hive.openBox<ProjectRef>(name));
    }, (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    });
    return completer.future;
  }

  /// Stored project paths, without duplicates
  static List<String> get paths {
    final paths = <String>[];
    for (final ref in box.values) {
      if (ref.path.isEmpty) continue;
      if (paths.any((path) => isSameProjectPath(path, ref.path))) continue;
      paths.add(ref.path);
    }
    return paths;
  }

  /// Whether [path] is already stored
  static bool contains(String path) {
    return box.values.any((ref) => isSameProjectPath(ref.path, path));
  }

  /// Stores a project [path]. Returns false if it was already stored.
  static Future<bool> add(String path) async {
    final normalized = normalizeProjectPath(path);
    if (contains(normalized)) return false;
    await box.add(
      ProjectRef(name: p.basename(normalized), path: normalized),
    );
    return true;
  }

  /// Removes every stored entry that points to [path]
  static Future<void> remove(String path) async {
    final keys = box.keys.where((key) {
      final ref = box.get(key);
      return ref != null && isSameProjectPath(ref.path, path);
    }).toList();
    await box.deleteAll(keys);
  }

  /// Loads a single project from [path].
  ///
  /// Never throws: projects that can't be loaded are returned as unavailable
  /// with the reason in [FlutterProject.loadError].
  static FlutterProject loadProject(String path) {
    try {
      if (!Directory(path).existsSync()) {
        return FlutterProject.unavailable(path, ProjectLoadError.notFound);
      }
      final project = Project.loadFromDirectory(Directory(path));
      if (!project.hasPubspec) {
        return FlutterProject.unavailable(
          path,
          ProjectLoadError.missingPubspec,
        );
      }
      if (!project.isFlutter) {
        return FlutterProject.unavailable(path, ProjectLoadError.notFlutter);
      }
      // Throws FormatException for an invalid version in the FVM config.
      // Fail here instead of while building the UI.
      project.pinnedVersion;
      return FlutterProject.fromProject(project);
    } catch (e) {
      // Catch errors too: invalid configs can throw TypeErrors
      return FlutterProject.unavailable(
        path,
        ProjectLoadError.unreadable,
        details: e.toString(),
      );
    }
  }

  /// Loads all projects.
  ///
  /// A project that can't be loaded (missing folder, invalid pubspec or
  /// config, offline drive) is returned as unavailable instead of being
  /// dropped, so a single broken entry can't hide the other projects and the
  /// user can still remove it.
  ///
  /// Disk access runs in a background isolate: checking a folder on a
  /// disconnected network drive can block until the OS times out, which would
  /// otherwise freeze the app.
  static Future<List<FlutterProject>> load() {
    final paths = ProjectsService.paths;
    return Isolate.run(() => paths.map(loadProject).toList());
  }

  /// Loads a single project in a background isolate, see [load]
  static Future<FlutterProject> loadProjectInBackground(String path) {
    return Isolate.run(() => loadProject(path));
  }
}
