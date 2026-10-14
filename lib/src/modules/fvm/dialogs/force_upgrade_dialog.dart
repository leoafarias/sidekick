import 'package:flutter/material.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../../components/atoms/typography.dart';

/// Asks to force upgrade [versionName] after Flutter refused to upgrade it.
/// Returns true if the user confirmed.
Future<bool> showForceUpgradeDialog(
  BuildContext context,
  String versionName,
  String message,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Heading(
          context.i18n(
            'modules:fvm.dialogs.couldNotUpgradeVersionname',
            variables: {'versionName': versionName},
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Text(
                context.i18n('modules:fvm.dialogs.forceUpgradeDiscardsChanges'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.i18n('modules:fvm.dialogs.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.i18n('modules:fvm.dialogs.forceUpgrade')),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
