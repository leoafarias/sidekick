// ignore_for_file: top_level_function_literal_block
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:fvm/fvm.dart' hide getDirectorySize;
// ignore: implementation_imports
import 'package:fvm/src/services/logger_service.dart';
// ignore: implementation_imports
import 'package:fvm/src/services/process_service.dart';
import 'package:watcher/watcher.dart';

import '../../modules/common/dto/release.dto.dart';
import '../../modules/common/utils/debounce.dart';
import '../../modules/common/utils/dir_stat.dart';
import '../projects/projects.provider.dart';
import '../releases/releases.provider.dart';

/// Lines logged by FVM, streamed to the console
final _fvmOutput = StreamController<String>.broadcast();

/// FVM logger that also forwards output to the Sidekick console
class _ConsoleLogger extends Logger {
  _ConsoleLogger(super.context);

  @override
  void info([String message = '']) {
    super.info(message);
    _fvmOutput.add('$message\n');
  }

  @override
  void warn([String message = '']) {
    super.warn(message);
    _fvmOutput.add('$message\n');
  }

  @override
  void err([String message = '']) {
    super.err(message);
    _fvmOutput.add('$message\n');
  }

  @override
  void write(String message) {
    super.write(message);
    _fvmOutput.add(message);
  }
}

/// FVM process runner that streams echoed output to the Sidekick console.
///
/// FVM echoes output by inheriting stdio, which a desktop app has no
/// terminal for, so the output is piped to the console instead and also
/// collected for error messages.
class _ConsoleProcessService extends ProcessService {
  const _ConsoleProcessService(super.context);

  static const _gitScopedEnvVars = {
    'GIT_ALTERNATE_OBJECT_DIRECTORIES',
    'GIT_CONFIG',
    'GIT_CONFIG_PARAMETERS',
    'GIT_CONFIG_COUNT',
    'GIT_OBJECT_DIRECTORY',
    'GIT_DIR',
    'GIT_WORK_TREE',
    'GIT_IMPLICIT_WORK_TREE',
    'GIT_GRAFT_FILE',
    'GIT_INDEX_FILE',
    'GIT_NO_REPLACE_OBJECTS',
    'GIT_REPLACE_REF_BASE',
    'GIT_PREFIX',
    'GIT_SHALLOW_FILE',
    'GIT_COMMON_DIR',
  };

  @override
  Future<ProcessResult> run(
    String command, {
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
    bool echoOutput = false,
    bool runInShell = true,
  }) async {
    if (!echoOutput) {
      return super.run(
        command,
        args: args,
        workingDirectory: workingDirectory,
        environment: environment,
        throwOnError: throwOnError,
        runInShell: runInShell,
      );
    }

    // Same environment handling as FVM: keep git, flutter and dart from
    // picking up the git repository of the parent process
    final name = command.split(RegExp(r'[/\\]')).last.split('.').first;
    final scrubGitEnv = const {'git', 'flutter', 'dart'}.contains(
      name.toLowerCase(),
    );
    final effectiveEnvironment = scrubGitEnv
        ? ({...context.environment, ...?environment}
          ..removeWhere((key, _) => _gitScopedEnvVars.contains(key)))
        : environment;

    _fvmOutput.add('\$ $command ${args.join(' ')}\n');
    final process = await Process.start(
      command,
      args,
      workingDirectory: workingDirectory,
      environment: effectiveEnvironment,
      includeParentEnvironment: !scrubGitEnv,
      runInShell: runInShell,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    Future<void> pipe(Stream<List<int>> stream, StringBuffer buffer) {
      return stream.transform(utf8.decoder).forEach((chunk) {
        buffer.write(chunk);
        _fvmOutput.add(chunk);
      });
    }

    await Future.wait([
      pipe(process.stdout, stdoutBuffer),
      pipe(process.stderr, stderrBuffer),
    ]);
    final exitCode = await process.exitCode;

    final result = ProcessResult(
      process.pid,
      exitCode,
      stdoutBuffer.toString(),
      stderrBuffer.toString(),
    );
    if (throwOnError && exitCode != 0) {
      final output = result.stderr.toString().trim().isNotEmpty
          ? result.stderr.toString().trim()
          : result.stdout.toString().trim();
      throw ProcessException(command, args, output, exitCode);
    }

    return result;
  }
}

/// FVM context shared by the app
final fvmContext = FvmContext.create(
  debugLabel: 'sidekick',
  skipInput: true,
  // Verbose makes FVM echo git clone output while installing
  logLevel: Level.verbose,
  generatorsOverride: {
    Logger: _ConsoleLogger.new,
    ProcessService: _ConsoleProcessService.new,
  },
);

/// Cache provider
final cacheSizeProvider =
    StateProvider<DirectorySizeInfo>((_) => DirectorySizeInfo());

/// Unused

final unusedReleaseSizeProvider = FutureProvider((ref) {
  final unused = ref.watch(unusedVersionProvider);
  // Get all directories
  final directories = unused.map(
    (version) => version.cache == null ? null : Directory(version.cache!.directory),
  );
  return getDirectoriesSize(directories.nonNulls);
});

/// Provider that shows
final unusedVersionProvider = Provider((ref) {
  final unusedVersions = <ReleaseDto>[];

  /// Cannot use fvmCacheProvider to use remove action
  final releases = ref.watch(releasesStateProvider);

  final projects = ref.watch(projectsPerVersionProvider);
  for (var version in releases.all) {
    // If its not in project and its not global
    if (projects[version.name] == null && version.isGlobal == false) {
      unusedVersions.add(version);
    }
  }

  return unusedVersions;
});

/// Releases  InfoProvider
final fvmCacheProvider =
    StateNotifierProvider<FvmCacheProvider, List<CacheFlutterVersion>>((ref) {
  return FvmCacheProvider(ref: ref);
});

class FvmCacheProvider extends StateNotifier<List<CacheFlutterVersion>> {
  FvmCacheProvider({
    required this.ref,
  }) : super([]) {
    reloadState();

    // Load State again while listening to directory
    directoryWatcher = Watcher(
      fvmContext.versionsCachePath,
    ).events.listen((event) {
      if (event.type == ChangeType.ADD || event.type == ChangeType.REMOVE) {
        _debouncer.run(reloadState);
      }
    });
  }

  final Ref ref;
  List<CacheFlutterVersion> channels = [];
  List<CacheFlutterVersion> versions = [];
  List<CacheFlutterVersion> all = [];
  String lastChangeHash = '';

  late StreamSubscription<WatchEvent> directoryWatcher;
  final _debouncer = Debouncer(const Duration(seconds: 20));

  Future<void> _setTotalCacheSize() async {
    final stat = await getDirectorySize(Directory(fvmContext.versionsCachePath));
    ref.read(cacheSizeProvider.notifier).state = stat;
  }

  Future<void> reloadState() async {
    // Cancel debounce to avoid running twice with no new state change
    _debouncer.cancel();
    final localVersions = await fvmContext.get<CacheService>().getAllVersions();
    state = localVersions;

    channels = localVersions.where((item) => item.isChannel).toList();
    versions = localVersions.where((item) => item.isChannel == false).toList();
    all = [...channels, ...versions];
    await _setTotalCacheSize();
  }

  CacheFlutterVersion? getChannel(String name) {
    if (channels.isNotEmpty) {
      return channels.where((c) => c.name == name).firstOrNull;
    } else {
      return null;
    }
  }

  CacheFlutterVersion? getVersion(String name) {
    if (versions.isNotEmpty) {
      return versions.where((v) => v.name == name).firstOrNull;
    } else {
      return null;
    }
  }

  @override
  void dispose() {
    directoryWatcher.cancel();
    super.dispose();
  }
}

final fvmStdoutProvider = _fvmOutput.stream;
