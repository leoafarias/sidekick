import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: implementation_imports
import 'package:fvm/src/utils/which.dart';
import '../../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../../components/atoms/copy_button.dart';
import '../../../components/atoms/typography.dart';
import '../../common/utils/open_link.dart';
import '../fvm.provider.dart';

Future<void> showGlobalInfoDialog(BuildContext context) async {
  final currentPath = which('flutter', binDir: true);
  final correctPath = fvmContext.globalCacheBinPath;
  final isSetup = currentPath == correctPath;

  // ignore: use_build_context_synchronously
  if (context.mounted) {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Heading(
              context.i18n('modules:fvm.dialogs.globalConfiguration'),
            ),
            actions: <Widget>[
              TextButton(
                style: ButtonStyle(
                    padding: WidgetStateProperty.resolveWith(
                  (states) => const EdgeInsets.all(20),
                )),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(context.i18n('modules:fvm.dialogs.ok')),
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Subheading(
                  context.i18n('modules:fvm.dialogs.flutterPathIsPointingOn'),
                ),
                // Caption('${currentPath}.\n\n'),
                Flexible(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: currentPath,
                          style: Theme.of(context).textTheme.bodySmall),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: IconButton(
                            icon: const Icon(Icons.copy, size: 14),
                            onPressed: () {
                              if (currentPath == null) return;
                              Clipboard.setData(
                                ClipboardData(text: currentPath),
                              );
                            }),
                      )
                    ]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),

                !isSetup
                    ? Column(
                        children: [
                          Subheading(
                            context.i18n(
                                    'modules:fvm.dialogs.changeThePathTo') +
                                context.i18n(
                                    'modules:fvm.dialogs.ifYouWantToFlutterSdkThroughFvm'),
                          ),
                          Row(
                            children: [
                              Caption(correctPath),
                              CopyButton(correctPath)
                            ],
                          )
                        ],
                      )
                    : Container(),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    final os = Platform.operatingSystem;
                    openLink(
                      'https://flutter.dev/docs/get-started/install/$os#update-your-path',
                    );
                  },
                  icon: Icon(MdiIcons.informationOutline),
                  label: Text(
                    context.i18n('modules:fvm.dialogs.howToUpdateYourPath'),
                  ),
                )
              ],
            ),
          );
        });
  }
}
