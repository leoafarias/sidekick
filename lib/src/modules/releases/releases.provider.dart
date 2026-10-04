// ignore_for_file: top_level_function_literal_block
import "package:system_info2/system_info2.dart";

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:fvm/fvm.dart';

import '../../modules/common/dto/channel.dto.dart';
import '../../modules/common/dto/master.dto.dart';
import '../../modules/common/dto/release.dto.dart';
import '../../modules/common/dto/version.dto.dart';
import '../common/constants.dart';
import '../common/utils/sdk_version.dart';
import '../fvm/fvm.provider.dart';

class AppReleasesState {
  bool fetching;

  MasterDto? _master;
  final List<ChannelDto> _channels = [];
  final List<VersionDto> _versions = [];

  Map<String, ReleaseDto> _allMap = {};

  bool hasGlobal;

  List<ReleaseDto> _allCached = [];

  final arch = SysInfo.kernelArchitecture;

  AppReleasesState({
    this.fetching = true,
    this.hasGlobal = false,
  });

  /// Returns all releases and channels
  Map<String, ReleaseDto> get allMap {
    return _allMap;
  }

  /// Returns all releases and channels that are cached
  List<ReleaseDto> get all {
    // Only get unique cached releases
    // Some releases replicate across channels
    // They can only be installed once and conflict
    return _allCached;
  }

  void generateMap() {
    final releases = [..._channels, ..._versions];
    if (_master != null) {
      // Master goes first
      releases.insert(0, _master!);
    }
    _allMap = {for (var release in releases) release.name: release};

    /// Returns all releases and channels that are cached
    _allCached = allMap.entries
        .where((entry) => entry.value.isCached)
        .map((entry) => entry.value)
        .toList();
  }

  List<VersionDto> get versions {
    return _versions;
  }

  List<ChannelDto> get channels {
    return _channels;
  }

  MasterDto? get master {
    return _master;
  }

  void addChannel(ChannelDto channel) {
    _channels.add(channel);
  }

  /// Whether [archive] is built for the host architecture
  bool _isNativeArchive(String archive) {
    final isArm = arch == ProcessorArchitecture.arm64;
    return archive.contains('arm64') == isArm;
  }

  void addVersion(VersionDto version) {
    // The same version can be published for several architectures,
    // keep a single entry and prefer the one built for the host.
    final index = _versions.indexWhere((e) => e.name == version.name);
    if (index == -1) {
      _versions.add(version);
      return;
    }

    final existing = _versions[index].release;
    final candidate = version.release;

    if (existing != null &&
        candidate != null &&
        !_isNativeArchive(existing.archive) &&
        _isNativeArchive(candidate.archive)) {
      _versions[index] = version;
    }
  }

  void addMaster(MasterDto master) {
    _master = master;
  }
}

final _fetchFlutterReleases = FutureProvider<FlutterReleases>(
  (_) => FVMClient.getFlutterReleases(),
);

final releasesStateProvider = Provider<AppReleasesState>((ref) {
  // Filter only version that are valid releases
  FlutterReleases? payload;
  ref.watch(_fetchFlutterReleases).whenData((value) => payload = value);

  // Watch this state change for refresh
  ref.watch(fvmCacheProvider);
  final installedVersions = ref.read(fvmCacheProvider.notifier);

//Creates empty releases state
  final releasesState = AppReleasesState();
  // Return empty state if not loaded
  if (payload == null) {
    return releasesState;
  }

  final flutterReleases = payload!.releases;
  final flutterChannels = payload!.channels;

  releasesState.fetching = false;

  final globalVersion = FVMClient.getGlobalVersionSync();
  releasesState.hasGlobal = globalVersion != null;

  //  MASTER: Set Master separetely because workflow is very different
  final masterCache = installedVersions.getChannel(kMasterChannel);
  String? masterVersion;
  if (masterCache != null) {
    masterVersion = getSdkVersionSync(masterCache);
  }

  releasesState.addMaster(MasterDto(
    name: kMasterChannel,
    cache: masterCache,
    needSetup: masterVersion == null,
    sdkVersion: masterVersion ?? '0.0.0',
    isGlobal: globalVersion == kMasterChannel,
  ));

  // CHANNELS: Loop through available channels NOT including master
  for (var name in kReleaseChannels) {
    final latestRelease = flutterChannels[name];
    final channelCache = installedVersions.getChannel(name);

    // Get sdk version
    String? sdkVersion;
    Release? currentRelease;

    if (channelCache != null) {
      sdkVersion = getSdkVersionSync(channelCache);
      if (sdkVersion != null) {
        currentRelease = payload!.getReleaseFromVersion(sdkVersion);
      }
    }

    final channelDto = ChannelDto(
      name: name,
      cache: channelCache,
      needSetup: sdkVersion == null,
      sdkVersion: sdkVersion,
      // Get version for the channel
      currentRelease: currentRelease,
      release: latestRelease,
      isGlobal: globalVersion == name,
    );

    releasesState.addChannel(channelDto);
  }

  // VERSIONS loop to create versions
  for (final item in flutterReleases) {
    // Check if version is found in installed versions
    final cacheVersion = installedVersions.getVersion(item.version);
    String? sdkVersion;

    if (cacheVersion != null) {
      sdkVersion = getSdkVersionSync(cacheVersion);
    }

    final version = VersionDto(
      name: item.version,
      release: item,
      cache: cacheVersion,
      needSetup: sdkVersion == null,
      isGlobal: globalVersion == item.version,
    );

    releasesState.addVersion(version);
  }

  releasesState.generateMap();

  return releasesState;
});

final getVersionProvider = Provider.family<ReleaseDto?, String?>(
  (ref, versionName) {
    final state = ref.read(releasesStateProvider);
    return state.allMap[versionName];
  },
);

enum Filter {
  beta,
  stable,
  all,
}

extension FilterExtension on Filter {
  /// Name of the channel
  String get name {
    final self = this;
    return self.toString().split('.').last;
  }
}

/// Returns a [Channel] from [name]
Filter filterFromName(String name) {
  switch (name) {
    case 'stable':
      return Filter.stable;
    case 'beta':
      return Filter.beta;
    case 'all':
      return Filter.all;
    default:
      throw Exception('Unknown filter $name');
  }
}

final filterProvider = StateProvider<Filter>((_) => Filter.all);

final filterableReleasesProvider = Provider((ref) {
  final filter = ref.watch(filterProvider);
  final releases = ref.watch(releasesStateProvider);

  if (filter == Filter.all) {
    return releases.versions;
  }

  final versions = releases.versions.where((version) {
    if (version.isChannel && version.name == filter.name) {
      return true;
    }

    if (!version.isChannel && version.release?.channelName == filter.name) {
      return true;
    }

    return false;
  });

  return versions.toList();
});
