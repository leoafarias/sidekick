import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:hive/hive.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

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

    // Go get info for each project
    final projects = await FVMClient.fetchProjects(directories);

    /// Check if its flutter project
    final projectsWithFlutter = projects.where((p) => p.isFlutterProject);

    /// Return flutter projects
    final flutterProjects = projectsWithFlutter.map((project) async {
      final pubspecFile = project.pubspecFile;

      if (await pubspecFile.exists()) {
        final yaml = await pubspecFile.readAsString();
        final pubspec = Pubspec.parse(yaml);

        return FlutterProject.fromProject(project, pubspec);
      } else {
        /// If it does not exist should be removed
        await box.delete(project.projectDir.path);
      }
    });

    final results = await Future.wait(flutterProjects);
    return results.nonNulls;
  }

  // /// Loads one project
  // static Future<FlutterProject> loadOne(String path) async {
  //   // Get project directory
  //   final directory = Directory(path);

  //   // Go get info for each project
  //   final project = await FVMClient.getProjectByDirectory(directory);

  //   /// Return flutter project

  //   final yaml = await project.pubspecFile.readAsString();
  //   final pubspec = Pubspec.parse(yaml);

  //   return FlutterProject.fromProject(project, pubspec);
  // }
}
