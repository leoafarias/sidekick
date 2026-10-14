// ignore_for_file: unawaited_futures

import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sidekick/i18n/language_manager.dart';
import 'package:sidekick/src/modules/common/utils/migrate_files.dart';
import 'package:window_manager/window_manager.dart';

import 'src/modules/common/app_shell.dart';
import 'src/modules/common/constants.dart';
import 'src/modules/projects/project.dto.dart';
import 'src/modules/projects/projects.service.dart';
import 'src/modules/common/utils/navigator_key.dart';
import 'src/modules/settings/settings.dto.dart';
import 'src/modules/settings/settings.service.dart';
import 'src/modules/settings/settings.utils.dart';
import 'src/screens/error_db_screen.dart';
import 'src/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  // Transparency compatibility for windows & linux
  await Window.initialize();

  Hive.registerAdapter(SidekickSettingsAdapter());
  Hive.registerAdapter(ProjectPathAdapter());
  final hiveDir = await getApplicationSupportDirectory();

  // This should only be necessary on the first run after 0.1.1, as DB location has changed.
  await checkMigration(hiveDir);

  await Hive.initFlutter(hiveDir.absolute.path);

  try {
    await SettingsService.init();
    await ProjectsService.init();
  } on FileSystemException {
    //print('There was an issue opening the DB');
  }

  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    //print('Sidekick is not supported on your platform');
    exit(0);
  }

  runApp(const ProviderScope(child: FvmApp()));

  const initialSize = Size(800, 500);
  windowManager.setMinimumSize(initialSize);
  windowManager.setSize(initialSize);
  if (!Platform.isMacOS) windowManager.setAsFrameless();

  doWhenWindowReady(() {
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

/// Fvm App
class FvmApp extends StatelessWidget {
  const FvmApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (SettingsService.box == null) {
      return const ErrorDBScreen();
    }

    return ValueListenableBuilder<Box<SidekickSettings>>(
      valueListenable: SettingsService.box!.listenable(),
      builder: (context, box, widget) {
        final settings = SettingsService.read();
        return OKToast(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: [
              settings.localizationsDelegate,
              ...GlobalMaterialLocalizations.delegates,
              GlobalWidgetsLocalizations.delegate,
              ...GlobalCupertinoLocalizations.delegates,
            ],
            locale: settings.locale ?? languageManager.supportedLocales.first,
            supportedLocales: languageManager.supportedLocales,
            localeResolutionCallback: (
              Locale? locale,
              Iterable<Locale> supportedLocales,
            ) {
              if (locale == null) {
                if (settings.locale != null) {
                  return settings.locale;
                }
                return supportedLocales.first;
              }
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode ||
                    supportedLocale.countryCode == locale.countryCode) {
                  if (settings.locale != null) {
                    return settings.locale;
                  }
                  return supportedLocale;
                }
              }
              if (settings.locale != null) {
                return settings.locale;
              }
              return supportedLocales.first;
            },
            title: kAppTitle,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: getThemeMode(settings.themeMode),
            home: const AppShell(),
          ),
        );
      },
    );
  }
}
