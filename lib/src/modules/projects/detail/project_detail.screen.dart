import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:open_file/open_file.dart';

import '../../../components/atoms/typography.dart';
import '../../../components/mdi_icons.dart';
import '../../../components/organisms/screen.dart';
import '../../common/utils/helpers.dart';
import '../../ide/components/open_in_ide_button.dart';
import '../../settings/settings.provider.dart';
import '../project.dto.dart';
import 'components/assets_tab.dart';
import 'components/detail_widgets.dart';
import 'components/overview_tab.dart';
import 'components/packages_tab.dart';
import 'components/version_tab.dart';
import 'project_detail.provider.dart';
import 'project_details.dart';

/// Sections of the project detail view
enum ProjectDetailTab {
  /// Icon, description, Flutter version, platforms
  overview,

  /// Dependencies and their latest versions
  packages,

  /// Assets explorer
  assets,

  /// App version
  version,
}

/// Detail view of a project, shown inside the Projects section
class ProjectDetailScreen extends HookConsumerWidget {
  /// Constructor
  const ProjectDetailScreen(
    this.project, {
    this.initialTab = ProjectDetailTab.overview,
    super.key,
  });

  /// Project
  final FlutterProject project;

  /// Tab shown first
  final ProjectDetailTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(initialTab);
    final details = ref.watch(projectDetailsProvider(project.path));
    final settings = ref.watch(sidekickSettingsProvider);

    void close() => ref.read(selectedProjectProvider.notifier).state = null;

    Widget tabItem(ProjectDetailTab value, IconData icon, String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          dense: true,
          shape: const StadiumBorder(),
          selected: tab.value == value,
          selectedColor: Theme.of(context).colorScheme.secondary,
          selectedTileColor: Colors.white10,
          leading: Icon(icon, size: 20),
          title: Text(label),
          onTap: () => tab.value = value,
        ),
      );
    }

    Widget content(ProjectDetails details) {
      switch (tab.value) {
        case ProjectDetailTab.overview:
          return OverviewTab(project: project, details: details);
        case ProjectDetailTab.packages:
          return PackagesTab(details: details);
        case ProjectDetailTab.assets:
          return AssetsTab(details: details);
        case ProjectDetailTab.version:
          return VersionTab(details: details);
      }
    }

    final version = details.value?.rawVersion;

    return SkScreen(
      extendBody: false,
      leading: IconButton(
        tooltip: context.i18n('modules:projects.detail.back'),
        icon: const Icon(Icons.arrow_back),
        splashRadius: 20,
        onPressed: close,
      ),
      title: project.name,
      actions: [
        if (version != null) VersionChip(version),
        const SizedBox(width: 10),
        Tooltip(
          message: context.i18n('modules:projects.components.open'),
          child: IconButton(
            splashRadius: 20,
            icon: Icon(MdiIcons.folder, size: 20),
            onPressed: () => OpenFile.open(project.path),
          ),
        ),
        OpenInSelectedIdeButton(project.path, settings),
        OpenInIdeMenu(project.path, settings),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 190,
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                tabItem(
                  ProjectDetailTab.overview,
                  MdiIcons.informationOutline,
                  context.i18n('modules:projects.detail.overview'),
                ),
                tabItem(
                  ProjectDetailTab.packages,
                  Icons.inventory_2_outlined,
                  context.i18n('modules:projects.detail.packages'),
                ),
                tabItem(
                  ProjectDetailTab.assets,
                  Icons.photo_library_outlined,
                  context.i18n('modules:projects.detail.assets'),
                ),
                tabItem(
                  ProjectDetailTab.version,
                  Icons.label_outline,
                  context.i18n('modules:projects.detail.version'),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: details.when(
              data: content,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => DetailMessage(
                icon: Icons.error_outline,
                message: context.i18n(
                  'modules:projects.detail.couldNotReadPubspec',
                  variables: {'error': error.toString()},
                ),
                action: OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(projectDetailsProvider(project.path)),
                  child: Text(context.i18n('modules:projects.detail.retry')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Version label shown next to the project name
class VersionChip extends StatelessWidget {
  /// Constructor
  const VersionChip(this.version, {super.key});

  /// Version
  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Caption('v$version'),
    );
  }
}
