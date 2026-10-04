import 'package:flutter/material.dart';
import '../../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../../components/atoms/empty_dataset.dart';

/// Empty project screen
class EmptyProjects extends StatelessWidget {
  /// Constructor
  const EmptyProjects({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyDataset(
      icon: Icon(MdiIcons.folder),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.i18n(
                  'modules:projects.components.noFlutterProjectsHaveBeenAddedYet'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              context.i18n(
                  'modules:projects.components.addYourFlutterProjectProjectsInformationWillBeDisplayedHere'),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
