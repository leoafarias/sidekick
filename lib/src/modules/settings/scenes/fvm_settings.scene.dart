import 'package:flutter/material.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../settings.dto.dart';

/// Fvm Settings Scene
class FvmSettingsScene extends StatelessWidget {
  /// Constructor
  const FvmSettingsScene(
    this.settings,
    this.onSave, {
    super.key,
  });

  /// Settings
  final AllSettings settings;

  /// Save handler
  final Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      child: ListView(
        children: [
          Text('FVM', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text(context
                .i18n('modules:settings.scenes.skipSetupFlutterOnInstall')),
            subtitle: Text(
              context.i18n(
                      'modules:settings.scenes.thisWillOnlyCloneFlutterAndNotInstall') +
                  context.i18n(
                      'modules:settings.scenes.dependenciesAfterANewVersionIsInstalled'),
            ),
            value: settings.sidekick.skipSetup,
            onChanged: (value) {
              settings.sidekick.skipSetup = value;
              onSave();
            },
          ),
        ],
      ),
    );
  }
}
