import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../../components/atoms/typography.dart';
import '../../../modules/common/dto/release.dto.dart';
import '../../selected_detail/selected_detail.provider.dart';
import '../dialogs/fvm_delete_dialog.dart';
import '../fvm_queue.provider.dart';

/// Possible actions for installed release
enum FvmReleaseActionOptions {
  /// Remove release
  remove,

  /// View details
  detail,

  /// Set as global
  global,

  /// Upgrade
  upgrade,
}

/// Displays actions for a cached release
class FvmReleaseActions extends ConsumerWidget {
  /// Constructor
  const FvmReleaseActions(
    this.release, {
    super.key,
  });

  /// Release
  final ReleaseDto release;

  /// Render menu button
  Widget renderMenuButton({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 10),
        Caption(label),
      ],
    );
  }

  /// Renders menu options
  List<PopupMenuEntry<FvmReleaseActionOptions>> renderMenuOptions(
      BuildContext context) {
    final menus = <PopupMenuEntry<FvmReleaseActionOptions>>[
      PopupMenuItem(
        value: FvmReleaseActionOptions.global,
        child: renderMenuButton(
          label: context.i18n('modules:fvm.components.setAsGlobal'),
          icon: MdiIcons.earth,
        ),
      ),
      PopupMenuItem(
        value: FvmReleaseActionOptions.detail,
        child: renderMenuButton(
          label: context.i18n('modules:pubPackages.components.details'),
          icon: MdiIcons.information,
        ),
      ),
      PopupMenuItem(
        value: FvmReleaseActionOptions.remove,
        child: renderMenuButton(
          label: context.i18n('modules:projects.components.remove'),
          icon: MdiIcons.delete,
        ),
      ),
    ];

    // Only display upgrade if option is channel
    if (release.isChannel) {
      menus.insert(
        0,
        PopupMenuItem(
          value: FvmReleaseActionOptions.upgrade,
          child: renderMenuButton(
            label: context.i18n('modules:fvm.components.upgrade'),
            icon: MdiIcons.update,
          ),
        ),
      );
    }

    return menus;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<FvmReleaseActionOptions>(
      onSelected: (result) {
        if (result == FvmReleaseActionOptions.remove) {
          showDeleteDialog(context, item: release, onDelete: () {
            ref.read(fvmQueueProvider.notifier).remove(context, release);
          });
        }

        if (result == FvmReleaseActionOptions.detail) {
          ref.read(selectedDetailProvider.notifier).state = SelectedDetail(
            release: release,
          );
        }

        if (result == FvmReleaseActionOptions.global) {
          ref.read(fvmQueueProvider.notifier).setGlobal(context, release);
        }

        if (result == FvmReleaseActionOptions.upgrade) {
          ref.read(fvmQueueProvider.notifier).upgrade(context, release);
        }
      },
      itemBuilder: (context) {
        return renderMenuOptions(context);
      },
      child: Icon(MdiIcons.dotsVertical),
    );
  }
}
