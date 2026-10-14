import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:fvm/fvm.dart';
import 'package:hive/hive.dart';

import 'project_icon.dart';

/// Why a stored project could not be loaded
enum ProjectLoadError {
  /// The project folder doesn't exist or is not reachable
  notFound,

  /// The folder has no pubspec.yaml
  missingPubspec,

  /// The pubspec.yaml doesn't depend on Flutter
  notFlutter,

  /// pubspec.yaml or the FVM config could not be read or parsed
  unreadable,
}

/// Flutter project
class FlutterProject extends Project {
  /// Project constructor
  FlutterProject._({
    required super.config,
    required super.path,
    required super.pubspec,
    this.loadError,
    this.loadErrorDetails,
  });

  /// Create Flutter project from project
  factory FlutterProject.fromProject(Project project) {
    return FlutterProject._(
      config: project.config,
      path: project.path,
      pubspec: project.pubspec,
    );
  }

  /// A stored project that could not be loaded
  factory FlutterProject.unavailable(
    String path,
    ProjectLoadError error, {
    String? details,
  }) {
    return FlutterProject._(
      config: null,
      path: path,
      pubspec: null,
      loadError: error,
      loadErrorDetails: details,
    );
  }

  /// Why the project could not be loaded, null if it loaded fine
  final ProjectLoadError? loadError;

  /// Error message for [ProjectLoadError.unreadable]
  final String? loadErrorDetails;

  /// If the project could not be loaded
  bool get invalid => loadError != null;

  /// Project description
  String get description {
    return pubspec?.description ?? '';
  }

  // Icons by project path. Kept across reloads, which rebuild every
  // project, so the lookup doesn't scan each project again.
  static final _iconCache = <String, Widget>{};

  // Image files of the cached icons, to evict them from Flutter's image
  // cache, which is keyed by file path
  static final _iconFiles = <String, File>{};

  static const _iconCacheWidth = 128;

  /// Clears the cached icon of [path], or of every project
  static void clearIconCache([String? path]) {
    final paths = path == null ? [..._iconCache.keys] : [path];
    for (final path in paths) {
      _iconCache.remove(path);
      final file = _iconFiles.remove(path);
      if (file != null) {
        ResizeImage(FileImage(file), width: _iconCacheWidth).evict();
      }
    }
  }

  /// Icon if it was already resolved
  Widget? get cachedIcon => _iconCache[path];

  /// Project icon
  Future<Widget> get icon async {
    final cached = _iconCache[path];
    if (cached != null) return cached;

    final file = invalid ? null : await findProjectIcon(path);
    final icon = file != null
        ? Image.file(
            file,
            cacheWidth: _iconCacheWidth,
            errorBuilder: (_, __, ___) => const FlutterLogo(),
          )
        : const FlutterLogo();
    _iconCache[path] = icon;
    if (file != null) _iconFiles[path] = file;
    return icon;
  }
}

/// Ref to project path
class ProjectRef {
  /// Constructor
  const ProjectRef({
    required this.name,
    required this.path,
  });

  /// Project name
  final String name;

  /// Project path
  final String path;

  /// Creates a project path from map
  factory ProjectRef.fromMap(Map<String, String> map) {
    return ProjectRef(
      name: map['name'] ?? '',
      path: map['path'] ?? '',
    );
  }

  /// Returns project path as a map
  Map<String, String> toMap() {
    return {
      'name': name,
      'path': path,
    };
  }
}

/// Project path adapter
class ProjectPathAdapter extends TypeAdapter<ProjectRef> {
  @override
  int get typeId => 2; // this is unique, no other Adapter can have the same id.

  @override
  ProjectRef read(BinaryReader reader) {
    final value = Map<String, String>.from(reader.readMap());
    return ProjectRef.fromMap(value);
  }

  @override
  void write(BinaryWriter writer, ProjectRef obj) {
    writer.writeMap(obj.toMap());
  }
}
