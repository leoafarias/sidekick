import 'package:fvm/fvm.dart';

import 'release.dto.dart';

/// Releae channel dto
class ChannelDto extends ReleaseDto {
  /// Latest releae of a channel
  final FlutterSdkRelease? currentRelease;

  /// SDK Version
  final String? sdkVersion;

  /// Constructor
  ChannelDto({
    required super.name,
    required super.release,
    required super.cache,
    required super.needSetup,
    required this.sdkVersion,
    required this.currentRelease,
    required super.isGlobal,
  }) : super(
          isChannel: true,
        );
}
