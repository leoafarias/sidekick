import 'package:path/path.dart' as p;

import 'ide_detector.dart';
import 'ide_environment.dart';
import 'ide_launcher.dart';

/// A process to start or a deep link to open
class IdeLaunchCommand {
  const IdeLaunchCommand.process(
    String this.executable,
    this.arguments, {
    this.runInShell = false,
    this.waitForExit = false,
  }) : url = null;

  const IdeLaunchCommand.url(String this.url)
      : executable = null,
        arguments = const [],
        runInShell = false,
        waitForExit = false;

  final String? executable;
  final List<String> arguments;
  final String? url;

  /// Needed for `.cmd`/`.bat` scripts on Windows
  final bool runInShell;

  /// Wait for the process and treat a non-zero exit code as a failure,
  /// otherwise it is started detached so it outlives Sidekick.
  final bool waitForExit;

  bool get isUrl => url != null;

  @override
  String toString() => isUrl ? url! : [executable, ...arguments].join(' ');
}

/// How to open a folder in a detected launcher
class IdeLaunchPlan {
  const IdeLaunchPlan(this.command, {this.startApp});

  final IdeLaunchCommand command;

  /// Started when [command] fails, after which [command] is retried. T3 Code
  /// can only open a folder while its desktop app is running.
  final IdeLaunchCommand? startApp;
}

bool _isWindowsScript(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.cmd') || lower.endsWith('.bat');
}

IdeLaunchCommand _runWith(String executable, List<String> arguments,
    {bool waitForExit = false}) {
  return IdeLaunchCommand.process(
    executable,
    arguments,
    runInShell: _isWindowsScript(executable),
    waitForExit: waitForExit,
  );
}

/// Opens [folder] with the platform's default handler
IdeLaunchCommand _openWithSystem(HostPlatform platform, String folder) {
  return switch (platform) {
    HostPlatform.macos => IdeLaunchCommand.process('open', [folder]),
    HostPlatform.windows => IdeLaunchCommand.process('explorer', [folder]),
    HostPlatform.linux => IdeLaunchCommand.process('xdg-open', [folder]),
  };
}

/// Works out how [ide] opens [folder]
Future<IdeLaunchPlan> buildLaunchPlan(
  DetectedIde ide,
  String folder,
  IdeEnvironment env,
) async {
  final launcher = ide.launcher;
  final executable = ide.executable;
  final appPath = ide.appPath;
  final platform = env.platform;

  switch (launcher.kind) {
    case IdeOpenKind.cli:
      if (executable != null) {
        return IdeLaunchPlan(_runWith(executable, [folder]));
      }
      if (appPath != null) {
        return IdeLaunchPlan(
          launcher.macAppOpenMode == MacAppOpenMode.arguments
              ? IdeLaunchCommand.process(
                  'open', ['-na', appPath, '--args', folder])
              : IdeLaunchCommand.process('open', ['-a', appPath, folder]),
        );
      }

    case IdeOpenKind.url:
      final encoded = Uri.encodeComponent(folder);
      return IdeLaunchPlan(
        IdeLaunchCommand.url(
            launcher.urlTemplate!.replaceAll('{path}', encoded)),
      );

    case IdeOpenKind.xcode:
      // Open the Runner workspace so pods and plugins are resolved
      var target = folder;
      for (final candidate in const [
        'ios/Runner.xcworkspace',
        'macos/Runner.xcworkspace',
        'ios/Runner.xcodeproj',
        'macos/Runner.xcodeproj',
      ]) {
        final path = p.join(folder, candidate);
        if (await env.directoryExists(path)) {
          target = path;
          break;
        }
      }
      return IdeLaunchPlan(
        IdeLaunchCommand.process('open', ['-a', appPath ?? 'Xcode', target]),
      );

    case IdeOpenKind.t3:
      return IdeLaunchPlan(
        _runWith(executable!, ['app', folder], waitForExit: true),
        startApp: appPath != null
            ? IdeLaunchCommand.process('open', ['-a', appPath])
            : null,
      );

    case IdeOpenKind.custom:
      if (executable == null || executable.isEmpty) {
        return IdeLaunchPlan(_openWithSystem(platform, folder));
      }
      if (platform == HostPlatform.macos) {
        return IdeLaunchPlan(
          IdeLaunchCommand.process('open', ['-a', executable, folder]),
        );
      }
      return IdeLaunchPlan(_runWith(executable, [folder]));
  }

  // A detected cli launcher always has an executable or an app
  return IdeLaunchPlan(_openWithSystem(platform, folder));
}
