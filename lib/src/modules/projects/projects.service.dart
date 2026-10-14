import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:hive/hive.dart';

import 'project.dto.dart';

/// Projects service
class ProjectsService {
  /// Constructor
  const ProjectsService._();

  /// Storage key
  static const _key = 'projects_service_box';

  /// Storage box
  static late Box<ProjectRef> box;

  /// Initializes the service
  static Future<void> init() async {
    box = await Hive.openBox<ProjectRef>(_key);
  }

  /// Loads all projects
  static Future<Iterable<FlutterProject>> load() async {
    /// Return if its empty
    if (box.isEmpty) return <FlutterProject>[];

    /// Get stored project directory
    final directories = box.values.map((p) => Directory(p.path)).toList();

    /// Return flutter projects
    final flutterProjects = <FlutterProject>[];
    for (final directory in directories) {
      // Go get info for each project
      final Project project;
      try {
        project = Project.loadFromDirectory(directory);
      } on Exception {
        // Skip projects with an unreadable pubspec or config
        continue;
      }

      if (project.hasPubspec) {
        /// Check if its flutter project
        if (project.isFlutter) {
          flutterProjects.add(FlutterProject.fromProject(project));
        }
      } else {
        /// If it does not exist should be removed
        await box.delete(project.path);
      }
    }

    return flutterProjects;
  }
}
