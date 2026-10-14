import 'dart:io';

import 'package:path/path.dart' as p;

import 'ide_launcher.dart';

/// Result of running a helper process during detection
class IdeProcessResult {
  const IdeProcessResult(this.exitCode, this.stdout);

  final int exitCode;
  final String stdout;
}

/// Everything detection reads from the machine, so it can be faked in tests
abstract class IdeEnvironment {
  HostPlatform get platform;

  /// Environment variables (PATH, HOME, LOCALAPPDATA...)
  Map<String, String> get variables;

  Future<bool> fileExists(String path);

  Future<bool> directoryExists(String path);

  /// Names of the entries in [path], empty if it does not exist
  Future<List<String>> listDirectory(String path);

  /// Runs a helper (`mdfind`, `reg`, `xdg-mime`). Must not throw.
  Future<IdeProcessResult> run(String executable, List<String> arguments);
}

/// [IdeEnvironment] backed by `dart:io`
class LocalIdeEnvironment implements IdeEnvironment {
  const LocalIdeEnvironment();

  @override
  HostPlatform get platform {
    if (Platform.isMacOS) return HostPlatform.macos;
    if (Platform.isWindows) return HostPlatform.windows;
    return HostPlatform.linux;
  }

  @override
  Map<String, String> get variables => Platform.environment;

  @override
  Future<bool> fileExists(String path) => File(path).exists();

  @override
  Future<bool> directoryExists(String path) => Directory(path).exists();

  @override
  Future<List<String>> listDirectory(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return const [];
      return await dir
          .list(followLinks: false)
          .map((entity) => p.basename(entity.path))
          .toList();
    } on FileSystemException {
      return const [];
    }
  }

  @override
  Future<IdeProcessResult> run(
      String executable, List<String> arguments) async {
    try {
      final result = await Process.run(executable, arguments)
          .timeout(const Duration(seconds: 5));
      return IdeProcessResult(result.exitCode, result.stdout.toString());
    } on Exception {
      return const IdeProcessResult(-1, '');
    }
  }
}
