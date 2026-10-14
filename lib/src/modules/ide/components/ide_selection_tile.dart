import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../components/mdi_icons.dart';
import '../../common/utils/helpers.dart';
import '../../settings/settings.dto.dart';
import '../ide.provider.dart';
import '../ide_icons.dart';
import '../ide_launcher.dart';

const _noneValue = 'none';

/// Settings entry to pick the IDE projects are opened with. Only installed
/// launchers are listed, plus a custom application.
class IdeSelectionTile extends HookConsumerWidget {
  /// Constructor
  const IdeSelectionTile(
    this.settings,
    this.onSave, {
    super.key,
  });

  /// Settings
  final AllSettings settings;

  /// On save handler
  final void Function() onSave;

  Widget _item(IdeLauncher launcher, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ideIcon(launcher, size: 20),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detection = ref.watch(ideDetectionProvider);
    final detected = detection.value ?? const [];

    // Detect again every time settings open, apps may have been installed
    useEffect(() {
      Future.microtask(
        () => ref.read(ideDetectionProvider.notifier).refresh(),
      );
      return null;
    }, const []);

    final sidekick = settings.sidekick;
    final selected = ideLauncherById(sidekick.ide);
    final customLauncher = ideLauncherById(customIdeId)!;

    final isMissing = selected != null &&
        !selected.isCustom &&
        !detected.any((ide) => ide.id == selected.id);
    // Only claim it is missing once detection finished
    final showMissing = isMissing && !detection.isLoading;

    final customLocation = sidekick.customIdeLocation;
    final customLabel = customLocation != null && customLocation.isNotEmpty
        ? '${context.i18n('modules:settings.scenes.ideCustom')} '
            '(${p.basenameWithoutExtension(customLocation)})'
        : context.i18n('modules:settings.scenes.ideCustom');

    return ListTile(
      title: Text(
        context.i18n('modules:settings.scenes.ideSelection'),
      ),
      subtitle: showMissing
          ? Text(
              context.i18n(
                'modules:settings.scenes.ideNotFoundDescription',
                variables: {'ideName': selected.name},
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          : Text(
              context.i18n(
                  'modules:settings.scenes.whatIdeDoYouWantToOpenYourProjectsWith'),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detection.isLoading)
            Tooltip(
              message: context.i18n('modules:settings.scenes.detectingIdes'),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: context.i18n('modules:settings.scenes.detectIdesAgain'),
              iconSize: 20,
              splashRadius: 20,
              icon: Icon(MdiIcons.refresh),
              onPressed: () =>
                  ref.read(ideDetectionProvider.notifier).refresh(),
            ),
          DropdownButton<String>(
            underline: Container(),
            isDense: true,
            value: selected?.id ?? _noneValue,
            items: [
              DropdownMenuItem(
                value: _noneValue,
                child: Text(context.i18n('modules:settings.scenes.ideNone')),
              ),
              ...detected.map(
                (ide) => DropdownMenuItem(
                  value: ide.id,
                  child: _item(ide.launcher, ide.name),
                ),
              ),
              // Keep the saved value selectable so it is not lost
              if (isMissing)
                DropdownMenuItem(
                  value: selected.id,
                  child: _item(
                    selected,
                    showMissing
                        ? context.i18n(
                            'modules:settings.scenes.ideNotFound',
                            variables: {'ideName': selected.name},
                          )
                        : selected.name,
                  ),
                ),
              DropdownMenuItem(
                value: customIdeId,
                child: _item(customLauncher, customLabel),
              ),
            ],
            onChanged: (value) async {
              if (value == customIdeId) {
                final file = await openFile();
                if (file == null) return;
                sidekick.customIdeLocation = file.path;
              }
              sidekick.ide = value == _noneValue ? null : value;
              onSave();
            },
          ),
        ],
      ),
    );
  }
}
