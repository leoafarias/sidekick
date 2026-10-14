import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../components/atoms/typography.dart';
import '../../../components/mdi_icons.dart';
import '../../common/utils/helpers.dart';
import '../../common/utils/notify.dart';
import '../../settings/settings.dto.dart';
import '../ide.provider.dart';
import '../ide_detector.dart';
import '../ide_icons.dart';
import '../ide_opener.dart';

/// Opens [folder] in [ide] and reports failures with a toast
Future<void> openFolderInIde(
  BuildContext context,
  WidgetRef ref,
  DetectedIde ide,
  String folder,
) async {
  final errorMessage = context.i18n(
    'modules:projects.components.couldNotOpenIde',
    variables: {'ideName': ide.name},
  );
  try {
    await openInIde(ide, folder, env: ref.read(ideEnvironmentProvider));
  } on Exception {
    notifyError(errorMessage);
  }
}

/// Quick button for the IDE selected in settings. Hidden when none is
/// selected or the selected one is not installed.
class OpenInSelectedIdeButton extends ConsumerWidget {
  /// Constructor
  const OpenInSelectedIdeButton(this.folder, this.settings, {super.key});

  /// Folder to open
  final String folder;

  /// Settings with the selected IDE
  final SidekickSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidekick = settings;
    final detected = ref.watch(ideDetectionProvider).value ?? const [];
    final ide = resolveSelectedIde(
      sidekick.ide,
      detected,
      customLocation: sidekick.customIdeLocation,
    );
    if (ide == null) return const SizedBox.shrink();

    return Tooltip(
      message: context.i18n(
        'modules:projects.components.openIde',
        variables: {'ideName': ide.name},
      ),
      child: IconButton(
        iconSize: 20,
        splashRadius: 20,
        icon: ideIcon(ide.launcher),
        onPressed: () => openFolderInIde(context, ref, ide, folder),
      ),
    );
  }
}

/// Menu value of the "detect again" entry
const _refreshAction = 'refresh';

/// "Open in" menu listing every installed launcher
class OpenInIdeMenu extends ConsumerWidget {
  /// Constructor
  const OpenInIdeMenu(this.folder, this.settings, {super.key});

  /// Folder to open
  final String folder;

  /// Settings with the custom IDE location
  final SidekickSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidekick = settings;
    final detection = ref.watch(ideDetectionProvider);
    final custom = customIde(sidekick.customIdeLocation);
    final launchers = [
      ...?detection.value,
      if (custom != null) custom,
    ];

    Widget renderItem(Widget icon, String label) {
      return Row(
        children: [
          IconTheme.merge(data: const IconThemeData(size: 15), child: icon),
          const SizedBox(width: 10),
          Flexible(child: Caption(label)),
        ],
      );
    }

    return PopupMenuButton<Object>(
      tooltip: context.i18n('modules:projects.components.openIn'),
      icon: Icon(MdiIcons.openInNew, size: 20),
      splashRadius: 20,
      onSelected: (ide) {
        if (ide is DetectedIde) {
          openFolderInIde(context, ref, ide, folder);
        } else {
          ref.read(ideDetectionProvider.notifier).refresh();
        }
      },
      itemBuilder: (context) {
        return [
          if (launchers.isEmpty)
            PopupMenuItem(
              enabled: false,
              child: Caption(
                detection.isLoading
                    ? context.i18n('modules:settings.scenes.detectingIdes')
                    : context.i18n('modules:projects.components.noIdesFound'),
              ),
            ),
          ...launchers.map(
            (ide) => PopupMenuItem<Object>(
              value: ide,
              child: renderItem(
                ideIcon(ide.launcher),
                ide.launcher.isCustom
                    ? context.i18n('modules:settings.scenes.ideCustom')
                    : ide.name,
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<Object>(
            value: _refreshAction,
            child: renderItem(
              Icon(MdiIcons.refresh),
              context.i18n('modules:settings.scenes.detectIdesAgain'),
            ),
          ),
        ];
      },
    );
  }
}
