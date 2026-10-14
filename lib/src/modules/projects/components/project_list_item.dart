import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';
import 'package:sidekick/src/modules/settings/settings.provider.dart';

import '../../../components/atoms/typography.dart';
import '../../../components/molecules/version_install_button.dart';
import '../../ide/components/open_in_ide_button.dart';
import '../../releases/releases.provider.dart';
import '../../sandbox/sandbox.screen.dart';
import '../detail/project_detail.provider.dart';
import '../project.dto.dart';
import 'project_actions.dart';
import 'project_release_select.dart';

/// Project list item
class ProjectListItem extends ConsumerWidget {
  /// Constructor
  const ProjectListItem(
    this.project, {
    this.versionSelect = false,
    super.key,
  });

  /// Flutter project
  final FlutterProject project;

  /// Show version selector
  final bool versionSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (project.invalid) return UnavailableProjectItem(project);

    final cachedVersions = ref.watch(releasesStateProvider).all;

    final version = ref.watch(getVersionProvider(project.pinnedVersion?.nameWithAlias));

    final needInstall = version != null && project.pinnedVersion != null;

    final sidekickSettings = ref.watch(settingsProvider).sidekick;

    void openProjectPlayground() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SandboxScreen(
            project: project,
          ),
        ),
      );
    }

    void openDetail() {
      ref.read(selectedProjectProvider.notifier).state = project.path;
    }

    return SizedBox(
      height: 170,
      child: Center(
        child: Card(
          child: Column(
            children: [
              // if (project.iconPath != null) Text(project.iconPath!),
              ListTile(
                leading: SizedBox(
                  width: 20,
                  height: 20,
                  child: project.cachedIcon != null
                      ? project.cachedIcon!
                      : FutureBuilder(
                          future: project.icon,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Icon(Icons.error);
                            } else if (snapshot.hasData) {
                              return snapshot.data as Widget;
                            } else {
                              return const Icon(Icons.image_not_supported);
                            }
                          }),
                ),
                title: Subheading(project.name),
                trailing: ProjectActions(project),
                onTap: openDetail,
              ),
              const Divider(height: 0, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Flexible(
                      child: Column(
                        children: [
                          Paragraph(
                            project.description,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Divider(thickness: 1, height: 0),
              Row(
                children: [
                  const SizedBox(width: 10),
                  Tooltip(
                    message: context.i18n('modules:projects.detail.manage'),
                    child: IconButton(
                      iconSize: 20,
                      splashRadius: 20,
                      icon: Icon(MdiIcons.tune),
                      onPressed: openDetail,
                    ),
                  ),
                  Tooltip(
                    message: context.i18n(
                        'modules:projects.components.openTerminalPlayground'),
                    child: IconButton(
                      iconSize: 20,
                      splashRadius: 20,
                      icon: Icon(MdiIcons.consoleLine),
                      onPressed: openProjectPlayground,
                    ),
                  ),
                  OpenInSelectedIdeButton(project.path, sidekickSettings),
                  OpenInIdeMenu(project.path, sidekickSettings),
                  const Spacer(),
                  versionSelect
                      ? Row(
                          children: [
                            needInstall
                                ? VersionInstallButton(
                                    version,
                                  )
                                : const SizedBox(
                                    height: 0,
                                    width: 0,
                                  ),
                            ProjectReleaseSelect(
                              project: project,
                              releases: cachedVersions,
                            )
                          ],
                        )
                      : Container(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// Message for a project that could not be loaded
String projectLoadErrorMessage(BuildContext context, FlutterProject project) {
  switch (project.loadError) {
    case ProjectLoadError.notFound:
      return context.i18n('modules:projects.components.folderNotFound');
    case ProjectLoadError.missingPubspec:
      return context.i18n('modules:projects.components.pubspecNotFound');
    case ProjectLoadError.notFlutter:
      return context.i18n('modules:projects.notAFlutterProject');
    case ProjectLoadError.unreadable:
    case null:
      return context.i18n(
        'modules:projects.couldNotReadProject',
        variables: {'error': project.loadErrorDetails ?? ''},
      );
  }
}

/// Card for a stored project that could not be loaded.
///
/// Keeps the project visible so the user knows why it is missing and can
/// remove it, instead of the project silently disappearing.
class UnavailableProjectItem extends ConsumerWidget {
  /// Constructor
  const UnavailableProjectItem(this.project, {super.key});

  /// Project that could not be loaded
  final FlutterProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorColor = Theme.of(context).colorScheme.error;
    return SizedBox(
      height: 170,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.folder_off_outlined, color: errorColor),
              title: Subheading(project.name),
              trailing: ProjectActions(project),
            ),
            const Divider(height: 0, thickness: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectLoadErrorMessage(context, project),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: errorColor),
                    ),
                    const SizedBox(height: 5),
                    Tooltip(
                      message: project.path,
                      child: Paragraph(
                        project.path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
