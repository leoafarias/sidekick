// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import '../../components/mdi_icons.dart';
import 'package:sidekick/src/modules/common/utils/open_link.dart';

class SettingsThemeMode {
  static const light = 'light';
  static const dark = 'dark';
  static const system = 'system';
  const SettingsThemeMode();
}

ThemeMode getThemeMode(String themeMode) {
  if (themeMode == SettingsThemeMode.light) {
    return ThemeMode.light;
  } else if (themeMode == SettingsThemeMode.dark) {
    return ThemeMode.dark;
  } else {
    return ThemeMode.system;
  }
}

typedef LaunchFunction = Future<void> Function(
  String projectPath, {
  String? customLocation,
});

enum SupportedIDE {
  VSCode,
  XCode,
  Custom,
}

class IDE {
  final String name;
  final LaunchFunction launch;
  final Widget icon;

  IDE(
    SupportedIDE ideName,
    this.icon,
    this.launch,
  ) : name = ideName.name;
}

final supportedIDEs = [
  IDE(
    SupportedIDE.VSCode,
    Icon(MdiIcons.microsoftVisualStudioCode),
    openVsCode,
  ),
  IDE(SupportedIDE.XCode, Icon(MdiIcons.appleSafari), openXcode),
  IDE(SupportedIDE.Custom, const Icon(Icons.code_rounded), openCustom),
];
