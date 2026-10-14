import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:i18next/i18next.dart';
import 'package:sidekick/i18n/language_manager.dart';

import '../ide/ide_launcher.dart';
import 'settings.utils.dart';

/// All Settings
class AllSettings {
  SidekickSettings sidekick;
  FlutterSettings flutter;

  AllSettings({
    required this.flutter,
    required this.sidekick,
  });

  static AllSettings create({
    SidekickSettings? sidekick,
    FlutterSettings? flutter,
  }) {
    return AllSettings(
      flutter: flutter ?? FlutterSettings(),
      sidekick: sidekick ?? SidekickSettings(),
    );
  }

  AllSettings copy() => AllSettings(
        sidekick: SidekickSettings.fromJson(sidekick.toJson()),
        flutter: FlutterSettings.fromMap(flutter.toMap()),
      );
}

/// i18next options for the app.
///
/// Interpolated values are not HTML-escaped: strings are shown in Text
/// widgets, so escaping would render `&quot;` or `&gt;` instead of quotes or
/// `>` (for example in errors, paths and version constraints).
const kI18NextOptions = I18NextOptions(escapeValue: false);

/// Sidekick settings
class SidekickSettings {
  /// Constructor
  SidekickSettings({
    this.onlyProjectsWithFvm = false,
    this.skipSetup = false,
    this.projectPaths = const [],
    this.themeMode = SettingsThemeMode.system,
    this.locale,
    this.ide,
    this.customIdeLocation,
  }) : localizationsDelegate = I18NextLocalizationDelegate(
          locales: languageManager.supportedLocales.toList(),
          dataSource: AssetBundleLocalizationDataSource(
            bundlePath: 'localizations',
          ),
          options: kI18NextOptions,
        );

  /// Storage key
  static const key = 'settings_key';

  bool onlyProjectsWithFvm;

  /// Skip Flutter setup after installing a version
  bool skipSetup;
  List<String> projectPaths;
  String themeMode;
  I18NextLocalizationDelegate localizationsDelegate;
  Locale? locale;
  String? ide;
  String? customIdeLocation;

  factory SidekickSettings.fromJson(String str) =>
      SidekickSettings.fromMap(json.decode(str));

  factory SidekickSettings.fromMap(Map<String, dynamic> json) {
    final language = json['i18Locale'];
    final locale = language != null
        ? Locale.fromSubtags(
            languageCode: (language as String).split('-')[0],
            countryCode: language.split('-')[1])
        : null;

    return SidekickSettings(
      projectPaths: (json['projectPaths'] as List<dynamic>).cast<String>(),
      onlyProjectsWithFvm: json['onlyProjectsWithFvm'] as bool? ?? false,
      skipSetup: json['skipSetup'] as bool? ?? false,
      themeMode: json['themeMode'] as String? ?? SettingsThemeMode.system,
      locale: locale,
      // Older versions stored the `SupportedIDE` enum name, or 'none'
      ide: migrateIdeId(json['ide'] as String?),
      customIdeLocation: json['customIdeLocation'],
    );
  }

  /// Converts Master Secret to Json
  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() {
    return {
      'projectPaths': projectPaths,
      'onlyProjectsWithFvm': onlyProjectsWithFvm,
      'skipSetup': skipSetup,
      'themeMode': themeMode,
      'i18Locale': locale?.toLanguageTag() ??
          languageManager.supportedLocales.first.toLanguageTag(),
      'ide': ide,
      'customIdeLocation': customIdeLocation,
    };
  }
}

class SidekickSettingsAdapter extends TypeAdapter<SidekickSettings> {
  @override
  int get typeId => 1; // this is unique, no other Adapter can have the same id.

  @override
  SidekickSettings read(BinaryReader reader) {
    // FIXME: Check why subtype does not match
    final value = Map<String, dynamic>.from(reader.readMap());
    return SidekickSettings.fromMap(value);
  }

  @override
  void write(BinaryWriter writer, SidekickSettings obj) {
    writer.writeMap(obj.toMap());
  }
}

/// Flutter settings
class FlutterSettings {
  /// Constructor
  FlutterSettings({
    this.analytics = true,
    this.linux = false,
    this.macos = false,
    this.windows = false,
    this.web = false,
  });

  /// Analytics enabled
  bool analytics;

  /// MacOS enabled
  bool macos;

  /// Linux enabled
  bool linux;

  /// Windows enabled
  bool windows;

  /// Web enabled
  bool web;

  /// Flutter settings from map
  factory FlutterSettings.fromMap(Map<String, bool> map) {
    return FlutterSettings(
      analytics: map['analytics'] ?? false,
      macos: map['macos'] ?? false,
      windows: map['windows'] ?? false,
      linux: map['linux'] ?? false,
      web: map['web'] ?? false,
    );
  }

  /// Flutter settings to map
  Map<String, bool> toMap() {
    return {
      'analytics': analytics,
      'macos': macos,
      'linux': linux,
      'windows': windows,
      'web': web,
    };
  }
}
