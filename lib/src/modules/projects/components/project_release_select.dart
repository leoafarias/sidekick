import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../../components/atoms/typography.dart';
import '../../../modules/common/dto/release.dto.dart';
import '../../fvm/fvm_queue.provider.dart';
import '../project.dto.dart';

/// Select project release
class ProjectReleaseSelect extends ConsumerWidget {
  /// Constructor
  const ProjectReleaseSelect({
    required this.project,
    required this.releases,
    super.key,
  });

  /// Project
  final FlutterProject project;

  /// Releases
  final List<ReleaseDto> releases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
        tooltip: context.i18n(
          'modules:projects.components.selectAFlutterSdkVersion',
        ),

        // elevation: 1,
        padding: EdgeInsets.zero,
        onSelected: (version) async {
          await ref
              .read(fvmQueueProvider.notifier)
              .pinVersion(context, project, version);
        },
        itemBuilder: (context) {
          return releases
              .map(
                (version) => PopupMenuItem(
                  value: version.name,
                  child: Text(
                    version.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
              .toList();
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
          constraints: const BoxConstraints(
            maxWidth: 165,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              project.pinnedVersion != null
                  ? Caption(project.pinnedVersion!)
                  : Caption(
                      context.i18n('modules:projects.choose'),
                    ),
              // const SizedBox(width: 20),
              Icon(MdiIcons.menuDown),
            ],
          ),
        ));
  }
}
