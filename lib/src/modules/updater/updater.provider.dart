import 'package:flutter/material.dart';
import 'package:hooks_riverpod/legacy.dart';

import '../../modifiers.dart';
import 'updater.dto.dart';
import 'updater.service.dart';

/// Updater provider
final updaterProvider =
    StateNotifierProvider<UpdaterStateNotifier, SidekickUpdateInfo>(
        (_) => UpdaterStateNotifier());

/// Update state notifier
class UpdaterStateNotifier extends StateNotifier<SidekickUpdateInfo> {
  /// COnstructor
  UpdaterStateNotifier() : super(SidekickUpdateInfo.notReady()) {
    if (!isMSStore) checkLatest();
  }

  /// Check for latest release
  Future<void> checkLatest() async {
    final updateInfo = await UpdaterService.checkLatestRelease();

    // Offline or GitHub unreachable: keep the current state instead of
    // throwing from the notifier constructor.
    if (updateInfo == null) return;

    state = updateInfo;
    if (state.needUpdate && !state.isInstalled) {
      try {
        await download();
      } on UpdaterException catch (_) {
        // Asset not available for this platform; leave update as pending.
      }
    }
  }

  /// Download latest release
  Future<void> download() async {
    state = await UpdaterService.downloadRelease(state);
  }

  /// Opens installer
  Future<void> openInstaller(BuildContext context) async {
    await UpdaterService.openInstaller(context, state);
  }
}
