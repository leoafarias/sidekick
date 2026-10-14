import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:fvm/fvm.dart';
// ignore: implementation_imports
import 'package:fvm/src/services/flutter_service.dart';
// ignore: implementation_imports
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
// ignore: implementation_imports
import 'package:fvm/src/workflows/setup_flutter.workflow.dart';
// ignore: implementation_imports
import 'package:fvm/src/workflows/use_version.workflow.dart';
import 'package:i18next/i18next.dart';
import 'package:sidekick/src/modules/common/utils/helpers.dart';

import '../../modules/common/dto/release.dto.dart';
import '../../modules/common/utils/navigator_key.dart';
import '../../modules/common/utils/notify.dart';
import '../projects/project.dto.dart';
import '../projects/projects.provider.dart';
import '../settings/settings.dto.dart';
import '../settings/settings.provider.dart';
import 'dialogs/force_upgrade_dialog.dart';
import 'fvm.provider.dart';

class FvmQueue {
  QueueItem? activeItem;
  final Queue<QueueItem> queue;
  FvmQueue({
    required this.activeItem,
    required this.queue,
  });

  bool get isEmpty {
    return queue.isEmpty;
  }

  QueueItem? get next {
    activeItem = queue.removeFirst();
    return activeItem;
  }

  FvmQueue update() {
    return FvmQueue(activeItem: activeItem, queue: queue);
  }
}

class QueueItem {
  final ReleaseDto version;
  final QueueAction action;
  QueueItem({required this.version, required this.action});
}

enum QueueAction {
  setupOnly,
  install,
  installAndSetup,
  channelUpgrade,
  channelForceUpgrade,
  remove,
  setGlobal,
}

/// Releases Provider
final fvmQueueProvider = StateNotifierProvider<FvmQueueState, FvmQueue>((ref) {
  return FvmQueueState(ref: ref);
});

/// State of the FVM Queue
class FvmQueueState extends StateNotifier<FvmQueue> {
  /// Constructor
  FvmQueueState({
    required this.ref,
  }) : super(FvmQueue(activeItem: null, queue: Queue()));

  /// Provider ref to be used later
  final Ref ref;

  late I18Next i18next;

  /// Retrieve Sidekick Settings
  SidekickSettings get settings {
    return ref.read(settingsProvider).sidekick;
  }

  ///  Adds install action to queue
  void install(
    BuildContext context,
    ReleaseDto version, {
    bool? skipSetup,
  }) async {
    skipSetup ??= settings.skipSetup;
    final action =
        skipSetup ? QueueAction.install : QueueAction.installAndSetup;

    await _addToQueue(context, version, action: action);
  }

  /// Adds setup action to queue
  void setup(BuildContext context, ReleaseDto version) {
    _addToQueue(context, version, action: QueueAction.setupOnly);
  }

  /// adds upgrade action to queue
  void upgrade(BuildContext context, ReleaseDto version) {
    _addToQueue(context, version, action: QueueAction.channelUpgrade);
  }

  /// adds force upgrade action to queue
  void forceUpgrade(BuildContext context, ReleaseDto version) {
    _addToQueue(context, version, action: QueueAction.channelForceUpgrade);
  }

  /// Adds remove action to queue
  void remove(BuildContext context, ReleaseDto version) {
    _addToQueue(context, version, action: QueueAction.remove);
  }

  /// Adds set global action to queue
  void setGlobal(BuildContext context, ReleaseDto version) {
    _addToQueue(context, version, action: QueueAction.setGlobal);
  }

  /// Runs queue
  void runQueue() async {
    try {
      final queue = state.queue;
      final activeItem = state.activeItem;
      // No need to run if empty
      if (queue.isEmpty) return;
      // If currently installing a version
      if (activeItem != null) return;
      // Gets next item of the queue
      final item = state.next;

      if (item == null) return;
      // Update queue
      state = state.update();

      final version = FlutterVersion.parse(item.version.name);
      final cacheService = fvmContext.get<CacheService>();

      // Run through actions
      switch (item.action) {
        case QueueAction.install:
          await _install(version);
          notify(
            i18next.t(
              'modules:fvm.versionItemversionnameHasBeenInstalled',
              variables: {
                'itemVersionName': item.version.name,
              },
            ),
          );
          break;
        case QueueAction.setupOnly:
          await _setup(cacheService.getVersion(version));
          notify(
            i18next.t(
              'modules:fvm.versionItemversionnameHasFinishedSetup',
              variables: {
                'itemVersionName': item.version.name,
              },
            ),
          );
          break;
        case QueueAction.installAndSetup:
          await _setup(await _install(version));
          notify(
            i18next.t(
              'modules:fvm.versionItemversionnameHasBeenInstalled',
              variables: {
                'itemVersionName': item.version.name,
              },
            ),
          );
          break;
        case QueueAction.channelUpgrade:
        case QueueAction.channelForceUpgrade:
          final force = item.action == QueueAction.channelForceUpgrade;
          try {
            // Throw so a failed upgrade surfaces Flutter's message
            await fvmContext.get<FlutterService>().run(
                  'flutter',
                  ['upgrade', if (force) '--force'],
                  item.version.cache!,
                  throwOnError: true,
                );
          } on ProcessException catch (e) {
            // Flutter suggests --force only when forcing would fix it,
            // e.g. when the SDK checkout has local changes
            if (force || !e.message.contains('--force')) rethrow;
            _suggestForceUpgrade(item.version, e.message);
            break;
          }
          notify(
            i18next.t(
              'modules:fvm.channelItemversionnameHasBeenUpgraded',
              variables: {
                'itemVersionName': item.version.name,
              },
            ),
          );
          break;
        case QueueAction.remove:
          await cacheService.remove(version);
          notify(
            i18next.t(
              'modules:fvm.versionItemversionnameHasBeenRemoved',
              variables: {
                'itemVersionName': item.version.name,
              },
            ),
          );
          break;
        case QueueAction.setGlobal:
          cacheService.setGlobal(item.version.cache!);
          notify(
            i18next.t(
              'modules:fvm.versionItemversionnameHasBeenSetAsGlobal',
              variables: {
                'itemVersionName': item.version.name,
              },
            ),
          );
          break;
        // ignore: unreachable_switch_default
        default:
          break;
      }
    } on Exception catch (e) {
      notifyError(e.toString());
    }

    // Set active item to null
    state.activeItem = null;
    // Run update on cache
    await ref.read(fvmCacheProvider.notifier).reloadState();
    // Update queue
    state = state.update();

    // Run queue again
    runQueue();
  }

  /// Pins a releae to a project
  Future<void> pinVersion(
    BuildContext context,
    FlutterProject project,
    String version,
  ) async {
    i18next = context.i18next;
    final cacheVersion = await _install(FlutterVersion.parse(version));
    await fvmContext.get<UseVersionWorkflow>()(
      version: cacheVersion,
      project: project,
      force: true,
      skipSetup: settings.skipSetup,
      skipPubGet: true,
    );
    await ref.read(projectsProvider.notifier).reload(project);
    notify(
      i18next.t(
        'modules:fvm.versionVersionPinnedToProjectname',
        variables: {
          'version': version,
          'projectName': project.name,
        },
      ),
    );
  }

  Future<void> _suggestForceUpgrade(
    ReleaseDto version,
    String message,
  ) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      notifyError(message);
      return;
    }

    final confirmed = await showForceUpgradeDialog(
      context,
      version.name,
      message,
    );
    if (confirmed && context.mounted) forceUpgrade(context, version);
  }

  Future<CacheFlutterVersion> _install(FlutterVersion version) {
    return fvmContext.get<EnsureCacheWorkflow>()(version, shouldInstall: true);
  }

  Future<void> _setup(CacheFlutterVersion? version) async {
    if (version == null) {
      throw Exception('Cannot setup version that is not in cache');
    }
    await fvmContext.get<SetupFlutterWorkflow>()(version);
  }

  Future<void> _addToQueue(
    BuildContext context,
    ReleaseDto version, {
    required QueueAction action,
  }) async {
    i18next = context.i18next;
    state.queue.add(QueueItem(version: version, action: action));
    state = state.update();
    runQueue();
  }
}
