// ignore_for_file: top_level_function_literal_block
import 'dart:async';
import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:fvm/fvm.dart' hide getDirectorySize;
// ignore: implementation_imports
import 'package:fvm/src/services/logger_service.dart';
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

/// FVM context shared by the app
final fvmContext = FvmContext.create(
  debugLabel: 'sidekick',
  skipInput: true,
  generatorsOverride: {Logger: _ConsoleLogger.new},
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
