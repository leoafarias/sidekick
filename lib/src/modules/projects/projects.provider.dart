// Get path of the directory to find
// Look recursively to all records and get if they have an FVM config
// If they do have fvm config get pubspec, and project name
// Get information about the config and match with the release
// Allow to change the version on a project
// When deleting a version notify that a project has that version attached to it
// ignore_for_file: top_level_function_literal_block

import 'dart:async';

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
    if (project.invalid) continue;
    final version = project.pinnedVersion?.nameWithAlias ?? 'NONE';
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

  /// Reloads all projects from storage and disk
  Future<void> load() async {
    try {
      final projects = await ProjectsService.load();
      if (mounted) state = projects;
    } catch (e, stackTrace) {
      debugPrint('Could not load projects: $e\n$stackTrace');
      notifyError(e.toString());
    }
  }

  /// Reloads one project
  Future<void> reload(FlutterProject project) => reloadPath(project.path);

  /// Reloads the project at [path] from disk
  Future<void> reloadPath(String path) async {
    final index = state.indexWhere(
      (item) => isSameProjectPath(item.path, path),
    );
    if (index == -1) return;

    final updated = [...state];
    updated[index] = ProjectsService.loadProject(state[index].path);
    state = updated;
  }

  /// Adds a project
  Future<void> addProject(BuildContext context, String path) async {
    final i18next = context.i18next;
    final project = ProjectsService.loadProject(path);

    switch (project.loadError) {
      case null:
        break;
      case ProjectLoadError.missingPubspec:
      case ProjectLoadError.notFlutter:
        notify(i18next.t('modules:projects.notAFlutterProject'));
        return;
      case ProjectLoadError.notFound:
      case ProjectLoadError.unreadable:
        notifyError(
          i18next.t(
            'modules:projects.couldNotReadProject',
            variables: {'error': project.loadErrorDetails ?? path},
          ),
        );
        return;
    }

    try {
      final added = await ProjectsService.add(path);
      if (!added) {
        notify(i18next.t('modules:projects.projectAlreadyAdded'));
      }
    } catch (e) {
      notifyError(e.toString());
    }
    await load();
  }

  /// Removes a project
  Future<void> removeProject(String path) async {
    await ProjectsService.remove(path);
    await load();
  }
}
