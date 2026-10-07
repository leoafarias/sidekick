// Get path of the directory to find
// Look recursively to all records and get if they have an FVM config
// If they do have fvm config get pubspec, and project name
// Get information about the config and match with the release
// Allow to change the version on a project
// When deleting a version notify that a project has that version attached to it
// ignore_for_file: top_level_function_literal_block

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:fvm/fvm.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../modules/common/utils/notify.dart';
import 'project.dto.dart';
import 'projects.service.dart';

/// Projects per release
final projectsPerVersionProvider = Provider((ref) {
  final list = <String, List<Project>>{};
  final projects = ref.watch(projectsProvider);

  if (projects.isEmpty) {
    return list;
  }

  for (final project in projects) {
    final version = project.pinnedVersion ?? 'NONE';
    final versionProjects = list[version];
    if (versionProjects != null) {
      versionProjects.add(project);
    } else {
      list[version] = [project];
    }
  }

  return list;
});

/// Projects provider
final projectsProvider =
    StateNotifierProvider<ProjectsStateNotifier, List<FlutterProject>>(
  (_) => ProjectsStateNotifier(),
);

/// Projects state
class ProjectsStateNotifier extends StateNotifier<List<FlutterProject>> {
  /// Constructor
  ProjectsStateNotifier() : super(<FlutterProject>[]) {
    load();
  }

  /// Pins a release to project
  Future<void> pinRelease(FlutterProject project, String version) async {
    await FVMClient.pinVersion(project, version);
    await reload(project);
  }

  /// Triggers a full project reload. Adds a 1 second delay on update
  /// if [withDelay] is true for better UI feedback
  Future<void> load() async {
    final projects = await ProjectsService.load();
    state = projects.toList();
  }

  /// Reloads one project
  Future<void> reload(FlutterProject project) async {
    final index = state.indexWhere((item) => item == project);
    // Update project
    state[index] = project;

    /// Notify state
    state = [...state];
  }

  /// Adds a project
  Future<void> addProject(BuildContext context, String path) async {
    final project = await FVMClient.getProjectByDirectory(Directory(path));
    if (project.isFlutterProject) {
      final ref = ProjectRef(name: path.split('/').last, path: path);
      await ProjectsService.box.put(path, ref);
      await load();
    } else {
      // ignore: use_build_context_synchronously
      notify(context.i18n('modules:projects.notAFlutterProject'));
    }
  }

  /// Removes a project
  void removeProject(Directory projectDir) {
    ProjectsService.box.delete(projectDir.path);
    load();
  }
}
