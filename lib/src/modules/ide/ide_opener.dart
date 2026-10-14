import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'ide_detector.dart';
import 'ide_environment.dart';
import 'ide_launch_plan.dart';
import 'ide_launcher.dart';

/// Opens [folder] in [ide]. Throws if it could not be launched.
Future<void> openInIde(
  DetectedIde ide,
  String folder, {
  IdeEnvironment env = const LocalIdeEnvironment(),
}) async {
  final plan = await buildLaunchPlan(ide, folder, env);

  // CLIs like `code` are shell scripts that may need tools from the user's
  // PATH, which a GUI app does not inherit.
  final detector = IdeDetector(env);
  final environment = {
    'PATH': detector.searchDirectories
        .join(env.platform == HostPlatform.windows ? ';' : ':'),
  };

  if (await _run(plan.command, environment)) return;

  final startApp = plan.startApp;
  if (startApp != null && await _run(startApp, environment)) {
    // Wait for the app to start accepting folders
    for (var attempt = 0; attempt < 15; attempt++) {
      await Future.delayed(const Duration(seconds: 1));
      if (await _run(plan.command, environment)) return;
    }
  }

  throw Exception('Could not open $folder in ${ide.name}');
}

Future<bool> _run(
  IdeLaunchCommand command,
  Map<String, String> environment,
) async {
  if (command.isUrl) {
    return launchUrl(Uri.parse(command.url!));
  }
  try {
    if (command.waitForExit) {
      final result = await Process.run(
        command.executable!,
        command.arguments,
        runInShell: command.runInShell,
        environment: environment,
      );
      return result.exitCode == 0;
    }
    await Process.start(
      command.executable!,
      command.arguments,
      runInShell: command.runInShell,
      environment: environment,
      mode: ProcessStartMode.detached,
    );
    return true;
  } on ProcessException {
    return false;
  }
}
