import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:sidekick/modules/compression/models/image_asset.model.dart';
import 'package:sidekick/utils/scan_directory.dart';
import 'package:sidekick/utils/squash.dart';

Future<List<ImageAsset>> scanForImages(Directory directory) async {
  final files = await scanDirectoryForCondition(
    condition: _checkIsValidImage,
    rootDir: directory,
  );

  final mappedList = files.map((file) async {
    final stat = await file.stat();
    return ImageAsset(file, stat);
  }).toList();

  return Future.wait(mappedList);
}

const _extensionList = [
  '.jpg',
  '.JPG',
  '.jpeg',
  '.JPEG',
  '.gif',
  '.GIF',
  '.png',
  '.PNG',
];

bool _checkIsValidImage(FileSystemEntity entity) {
  final ext = p.extension(entity.path);
  if (!entity.path.contains('/build/')) {
    return _extensionList.contains(ext);
  } else {
    return false;
  }
}

final pool = Pool(
  Platform.numberOfProcessors,
  timeout: const Duration(seconds: 30),
);

Future<ImageAsset> compressImageAsset(
  ImageAsset asset,
  Directory tempDir,
) async {
  final compressObj = SquashObject(
    imageFile: asset.file,
    path: tempDir.path,
    quality: 80, //first compress quality, default 80
    step: 6, //compress quality step, bigger faster
  );
  // Use a pool for isolates
  final file = await pool.withResource(() => Squash.compressImage(compressObj));
  // Get file stat
  final fileStat = await file.stat();
  // Create image asset
  return ImageAsset(file, fileStat);
}