import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fvm/fvm.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../components/atoms/typography.dart';
import '../../modules/common/dto/release.dto.dart';
import '../releases/releases.provider.dart';
import 'components/sandbox_terminal.dart';
import 'sandbox.provider.dart';

/// Sandbox screen
class SandboxScreen extends HookConsumerWidget {
  /// Constructor
  const SandboxScreen({
    required this.project,
    super.key,
  });

  /// Project
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releases = ref.watch(releasesStateProvider);
    final terminal = ref.watch(sandboxProvider.notifier);
    final processing = ref.watch(sandboxProvider).processing;

    final selectedRelease = useState<ReleaseDto?>(null);
    final sandboxScrollController = ScrollController();

    useEffect(() {
      if (selectedRelease.value == null && releases.all.isNotEmpty) {
        selectedRelease.value = releases.all[0];
      }
      return;
    }, []);

    return Scaffold(
      // backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.playBox),
            const SizedBox(width: 10),
            Subheading(context.i18n('modules:sandbox.playground')),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        flexibleSpace: MoveWindow(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Colors.red, Colors.blue],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 15,
            splashRadius: 15,
            onPressed: () {
              terminal.clearConsole();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  title: Text(context.i18n('modules:releases.releases')),
                  subtitle: Text(
                    context.i18n(
                      'modules:sandbox.releasesVersions',
                      variables: {
                        'releases': releases.all.length,
                      },
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoScrollbar(
                    controller: sandboxScrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ListView(
                        controller: sandboxScrollController,
                        children: releases.all.map(
                          (version) {
                            if (version.name == selectedRelease.value?.name) {
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    selectedRelease.value = version;
                                  },
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(version.name),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: TextButton(
                                onPressed: () {
                                  selectedRelease.value = version;
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(version.name),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(
            width: 0,
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  dense: true,
                  title: Text(project.name ?? ''),
                  subtitle: Text(project.projectDir.path),
                  trailing: processing
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepOrange,
                            side: const BorderSide(
                              color: Colors.deepOrange,
                            ),
                          ),
                          onPressed: () {
                            terminal.endProcess();
                          },
                          child: Text(
                            context.i18n('modules:fvm.dialogs.cancel'),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: null,
                          child: Text(
                            context.i18n('modules:sandbox.notRunning'),
                          ),
                        ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: selectedRelease.value != null
                      ? SandboxTerminal(
                          project: project,
                          release: selectedRelease.value!,
                        )
                      : Container(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
