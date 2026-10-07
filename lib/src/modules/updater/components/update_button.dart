import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../../components/atoms/typography.dart';
import '../updater.provider.dart';

/// Sidekick update button
class SkUpdateButton extends HookConsumerWidget {
  /// Constructor
  const SkUpdateButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updater = ref.watch(updaterProvider.notifier);
    final updateInfo = ref.watch(updaterProvider);

    /// Return empty if its not installed or does not need update
    if (!updateInfo.ready) {
      return const SizedBox(height: 0, width: 0);
    }

    final isMounted = context.mounted;

    void showUpdateDialog() {
      // flutter defined function
      showDialog(
        context: context,
        builder: (context) {
          // return object of type Dialog
          return AlertDialog(
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            buttonPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            title: Row(
              children: [
                Icon(MdiIcons.alertDecagram),
                const SizedBox(width: 10),
                Heading(
                    context.i18n('modules:updater.components.updateAvailable')),
              ],
            ),
            content: Paragraph(
              context.i18n(
                'modules:updater.components.sidekickVersionUpdateinfolatestIsNowAvailable',
                variables: {
                  'updateInfoLatest': updateInfo.latest,
                },
              ),
            ),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(context.i18n('modules:updater.components.later')),
              ),
              ElevatedButton(
                onPressed: () async {
                  await updater.openInstaller(context);
                  // ignore: use_build_context_synchronously
                  if (isMounted) Navigator.of(context).pop();
                },
                child:
                    Text(context.i18n('modules:updater.components.updateNow')),
              ),
            ],
          );
        },
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ActionChip(
          onPressed: showUpdateDialog,
          label: Text(
            context.i18n('modules:updater.components.updateAvailable'),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
