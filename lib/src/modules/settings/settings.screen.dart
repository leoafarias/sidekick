import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sidekick/generated/l10n.dart';

import '../../modules/common/utils/helpers.dart';
import '../../modules/common/utils/notify.dart';
import 'scenes/flutter_settings.scene.dart';
import 'scenes/fvm_settings.scene.dart';
import 'scenes/general_settings.scene.dart';
import 'settings.provider.dart';

/// TODO: Unify the nav sections information
/// Nav sections
enum NavSection {
  /// General
  general,

  /// FVM
  fvm,

  /// Flutter
  flutter,
}


const _sectionIcons = [
  MdiIcons.tune,
  MdiIcons.layers,
  MdiIcons.console,
];

/// Settings screen
class SettingsScreen extends HookWidget {
  /// Constructor
  const SettingsScreen({
    this.section = NavSection.general,
    key,
  }) : super(key: key);

  /// Current nav section
  final NavSection section;
  @override
  Widget build(BuildContext context) {
    final provider = useProvider(settingsProvider.notifier);
    final settings = useProvider(settingsProvider);

    final currentSection = useState(section.index);

    final controller = usePageController(initialPage: section.index);

    final _sections = [S.current.general, 'FVM', 'Flutter'];

    void changeSection(int idx) {
      currentSection.value = idx;
      controller.jumpToPage(idx);
    }

    if (settings.sidekick == null) {
      return Container();
    }

    Future<void> handleSave() async {
      try {
        await provider.save(settings);
        notify(S.of(context).settingsHaveBeenSaved);
      } on Exception catch (e) {
        notifyError(S.of(context).couldNotSaveSettings);
        notifyError(e.toString());
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: const [
          CloseButton(),
          SizedBox(width: 10),
        ],
      ),
      body: Container(
        child: Row(
          children: [
            const SizedBox(width: 50),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListView(
                  children: _sections.mapIndexed(
                    (section, idx) {
                      return ListTile(
                        leading: Icon(
                          _sectionIcons[idx],
                          size: 20,
                        ),
                        title: Text(
                          section,
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                        selectedTileColor: Theme.of(context).hoverColor,
                        selected: currentSection.value == idx,
                        onTap: () => changeSection(idx),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(width: 60),
            Expanded(
              flex: 3,
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                controller: controller,
                children: [
                  SettingsSectionGeneral(settings, handleSave),
                  FvmSettingsScene(settings, handleSave),
                  SettingsSectionFlutter(settings, handleSave),
                ],
              ),
            ),
            const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }
}
