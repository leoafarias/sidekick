import 'package:flutter/material.dart';

import '../../components/mdi_icons.dart';
import 'ide_launcher.dart';

/// Icon for a launcher. Brand logos are not bundled, so these are the
/// closest Material Design Icons.
IconData ideIconData(IdeLauncher launcher) {
  return switch (launcher.id) {
    'VSCode' ||
    'VSCodeInsiders' ||
    'VSCodium' =>
      MdiIcons.microsoftVisualStudioCode,
    'Cursor' => MdiIcons.cursorDefaultOutline,
    'Windsurf' => MdiIcons.weatherWindy,
    'Zed' => MdiIcons.alphaZBox,
    'Antigravity' => MdiIcons.orbit,
    'AndroidStudio' => MdiIcons.androidStudio,
    'IntelliJ' => MdiIcons.alphaIBox,
    'SublimeText' => MdiIcons.alphaSBox,
    'XCode' => MdiIcons.hammerWrench,
    'Claude' => MdiIcons.asterisk,
    'ClaudeCode' => MdiIcons.console,
    'Codex' => MdiIcons.robotOutline,
    'T3Code' => MdiIcons.alphaTBox,
    'Paseo' => MdiIcons.alphaPCircle,
    _ => Icons.code_rounded,
  };
}

/// Icon widget for a launcher
Widget ideIcon(IdeLauncher launcher, {double? size}) {
  return Icon(ideIconData(launcher), size: size);
}
