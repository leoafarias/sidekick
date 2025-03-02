import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path/path.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';
import 'package:sidekick/src/modules/settings/settings.provider.dart';
import 'package:sidekick/src/modules/settings/settings.utils.dart';

import '../../../components/atoms/typography.dart';
import '../../../components/molecules/version_install_button.dart';
import '../../releases/releases.provider.dart';
import '../../sandbox/sandbox.screen.dart';
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
    final cachedVersions = ref.watch(releasesStateProvider).all;

    final version = ref.watch(getVersionProvider(project.pinnedVersion));

    final needInstall = version != null && project.pinnedVersion != null;

    final sidekickSettings = ref.watch(settingsProvider).sidekick;

    final ideName = sidekickSettings.ide;

    final ide = ideName != null
        ? supportedIDEs.firstWhere((element) => element.name == ideName)
        : null;

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

    void openIde() {
      ide?.launch(
        project.projectDir.absolute.path,
        customLocation: sidekickSettings.customIdeLocation,
      );
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
                  child: project.icon,
                ),
                title: Subheading(project.name),
                trailing: ProjectActions(project),
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
                    message: context.i18n(
                        'modules:projects.components.openTerminalPlayground'),
                    child: IconButton(
                      iconSize: 20,
                      splashRadius: 20,
                      icon: const Icon(MdiIcons.consoleLine),
                      onPressed: openProjectPlayground,
                    ),
                  ),
                  if (ideName != null)
                    Tooltip(
                      message: context.i18n(
                        'modules:projects.components.openIde',
                        variables: {
                          'ideName': ide?.name,
                        },
                      ),
                      child: IconButton(
                        iconSize: 20,
                        splashRadius: 20,
                        icon: ide?.icon ?? const Icon(MdiIcons.alphaPBox),
                        onPressed: openIde,
                      ),
                    ),
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
