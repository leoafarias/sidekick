import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../components/mdi_icons.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../components/atoms/checkbox.dart';
import '../../components/atoms/refresh_button.dart';
import '../../components/atoms/typography.dart';
import '../../components/organisms/screen.dart';
import '../../modules/common/utils/notify.dart';
import '../settings/settings.provider.dart';
import 'components/project_list_item.dart';
import 'components/projects_empty.dart';
import 'projects.provider.dart';

/// Projects screen
class ProjectsScreen extends HookConsumerWidget {
  /// Constructor
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(projectsProvider.notifier);
    final projects = ref.watch(projectsProvider);
    final settings = ref.watch(settingsProvider);

    final filteredProjects = useState(projects);
    final projectsScrollController = ScrollController();

    Future<void> onRefresh() async {
      await ref.read(projectsProvider.notifier).load();
      notify(
        // ignore: use_build_context_synchronously
        context.i18n('modules:projects.projectsRefreshed'),
      );
    }

    Future<void> handleChooseDirectory() async {
      final directoryPath = await selector.getDirectoryPath(
        confirmButtonText: context.i18n('modules:projects.choose'),
      );
      if (directoryPath == null) {
        // Operation was canceled by the user.
        return;
      }
      // ignore: use_build_context_synchronously
      await notifier.addProject(context, directoryPath);
    }

    useEffect(() {
      if (settings.sidekick.onlyProjectsWithFvm) {
        filteredProjects.value =
            projects.where((p) => p.pinnedVersion != null).toList();
      } else {
        filteredProjects.value = [...projects];
      }
      return;
    }, [projects, settings.sidekick]);

    return SkScreen(
      title: context.i18n('modules:projects.projects'),
      actions: [
        Caption(
          context.i18n(
            'modules:projects.projectsProjects',
            variables: {
              'projects': projects.length,
            },
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: context.i18n(
            'modules:projects.onlyDisplayProjectsThatHaveVersionsPinned',
          ),
          child: SkCheckBox(
            label: context.i18n('modules:projects.fvmOnly'),
            value: settings.sidekick.onlyProjectsWithFvm,
            onChanged: (value) {
              settings.sidekick.onlyProjectsWithFvm = value;
              ref.read(settingsProvider.notifier).save(settings);
            },
          ),
        ),
        const SizedBox(width: 10),
        RefreshButton(
          onPressed: onRefresh,
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: handleChooseDirectory,
          icon: Icon(MdiIcons.plus),
          label: Text(context.i18n('modules:projects.addProject')),
        ),
      ],
      child: projects.isEmpty
          ? const EmptyProjects()
          : CupertinoScrollbar(
              controller: projectsScrollController,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: ResponsiveGridList(
                    controller: projectsScrollController,
                    desiredItemWidth: 290,
                    minSpacing: 0,
                    children: filteredProjects.value.map((project) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10, right: 10),
                        child: ProjectListItem(
                          project,
                          versionSelect: true,
                          key: Key(project.projectDir.path),
                        ),
                      );
                    }).toList()),
              ),
            ),
    );
  }
}
