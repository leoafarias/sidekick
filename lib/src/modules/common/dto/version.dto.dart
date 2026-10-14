import 'package:fvm/fvm.dart';

import 'release.dto.dart';

/// Release version dto
class VersionDto extends ReleaseDto {
  /// Constructor
  VersionDto({
    required super.name,
    required FlutterSdkRelease super.release,
    required super.needSetup,
    required super.cache,
    required super.isGlobal,
  });
}
