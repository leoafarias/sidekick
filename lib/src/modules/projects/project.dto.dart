import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:fvm/fvm.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';

/// Flutter project
class FlutterProject extends Project {
  /// Project constructor
  @override
  // ignore: overridden_fields
  final String name;
  FlutterProject._({
    required this.name,
    required super.config,
    required super.projectDir,
    required this.pubspec,
    this.invalid = false,
  }) : super(
          name: name,
          isFlutterProject: true,
        );

  /// If a project does not have pubspec
  final bool invalid;

  /// Create Flutter project from project
  factory FlutterProject.fromProject(Project project, Pubspec pubspec) {
    return FlutterProject._(
      name: project.name ?? pubspec.name,
      config: project.config,
      projectDir: project.projectDir,
      pubspec: pubspec,
    );
  }

  /// Create Flutter project from project
  factory FlutterProject.fromInvalidProject(Project project) {
    return FlutterProject._(
      name: project.name ?? '',
      config: project.config,
      projectDir: project.projectDir,
      pubspec: null,
      invalid: true,
    );
  }

  /// Pubspec
  final Pubspec? pubspec;

  /// Project description
  String get description {
    return pubspec?.description ?? '';
  }

  /// Project icon path
  Widget get icon {
    // 定义查找规则列表，按照优先级排列
    List<LookupRule> lookupRules = [
      LookupRule(['sidekick', 'icon']), // 优先级最高 pubspec.yaml sidekick.icon
      LookupRule([
        'flutter_launcher_icons',
        'image_path'
      ]), // pubspec.yaml  flutter_launcher_icons.image_path
      LookupRule(['flutter_launcher_icons', 'image_path'],
          fileName: "flutter_launcher_icons.yaml"),
      LookupRule(['flutter_launcher_icons', 'image_path'],
          regexPattern: r'^flutter_launcher_icons-(.*).yaml$'),
      // 可以添加多级嵌套的查找规则，例如
      // LookupRule(['deeply', 'nested', 'key']),
    ];

    for (LookupRule rule in lookupRules) {
      List<File> yamlFiles = [];
      if (rule.fileName != null || rule.regexPattern != null) {
        yamlFiles =
            getYamlFilesSync(projectDir.path, regexPattern: rule.regexPattern);
      } else {
        // 当 rule.fileName 和 rule.regexPattern 都为 null 时，使用 pubspec.yaml
        File pubspecFile = File(join(projectDir.path, 'pubspec.yaml'));
        if (pubspecFile.existsSync()) {
          yamlFiles.add(pubspecFile);
        }
      }

      for (File lookUpFile in yamlFiles) {
        try {
          YamlMap yamlMap = loadYaml(lookUpFile.readAsStringSync());
          dynamic currentMap = yamlMap;
          bool found = true;
          for (String key in rule.keys) {
            if (currentMap is YamlMap && currentMap.containsKey(key)) {
              currentMap = currentMap[key];
            } else {
              found = false;
              break;
            }
          }
          if (found && currentMap is String) {
            // 判断路径是否是本地路径 或者是网络路径
            File imgFile = File(join(projectDir.path, currentMap));
            if (imgFile.existsSync()) {
              return Image.file(imgFile);
            }
          }
        } catch (e) {
          // 处理解析 YAML 文件时可能出现的异常
          print('解析 YAML 文件 ${lookUpFile.path} 时出错: $e');
        }
      }
    }

    // fallback 遍历项目assets目录 查找logo文件
    List<File> findImageFiles = findLogoImages(join(projectDir.path, "assets"));
    if (findImageFiles.isNotEmpty) {
      return Image.file(findImageFiles.first);
    }

    return FlutterLogo();
  }

  /// 定义常见图片文件扩展名
  static List<String> imageExtensions = ['.png', '.jpg', '.jpeg'];

  /// 获取项目路径下可能为logo的文件
  // 递归遍历目录，查找名称包含 logo 的图片文件
  List<File> findLogoImages(String directoryPath) {
    final Directory directory = Directory(directoryPath);
    final List<File> logoImages = [];

    if (directory.existsSync()) {
      final List<FileSystemEntity> entities =
          directory.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final String fileName =
              entity.path.split(Platform.pathSeparator).last;
          int dotIndex = fileName.lastIndexOf('.');
          String fileExtension = '';
          if (dotIndex != -1) {
            fileExtension = fileName.substring(dotIndex);
          }
          if (imageExtensions.contains(fileExtension.toLowerCase()) &&
              fileName.toLowerCase().contains('logo')) {
            logoImages.add(entity);
          }
        }
      }
    }

    return logoImages;
  }

  /// 根据文件名或正则表达式获取 YAML 文件
  Future<List<File>> getYamlFiles(String directoryPath,
      {String? fileName, String? regexPattern}) async {
    final directory = Directory(directoryPath);
    final yamlFiles = <File>[];

    // 检查目录是否存在
    if (await directory.exists()) {
      // 遍历目录中的所有实体（文件和子目录）
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          // 获取文件名
          final currentFileName =
              entity.path.split(Platform.pathSeparator).last;

          bool isMatch = false;
          if (fileName != null) {
            // 根据文件名匹配
            isMatch = currentFileName == fileName &&
                currentFileName.endsWith('.yaml');
          } else if (regexPattern != null) {
            // 根据正则表达式匹配
            final regex = RegExp(regexPattern);
            isMatch = regex.hasMatch(currentFileName) &&
                currentFileName.endsWith('.yaml');
          }

          if (isMatch) {
            yamlFiles.add(entity);
          }
        }
      }
    }

    return yamlFiles;
  }

  /// 根据文件名或正则表达式同步获取 YAML 文件
  List<File> getYamlFilesSync(String directoryPath,
      {String? fileName, String? regexPattern}) {
    final directory = Directory(directoryPath);
    final yamlFiles = <File>[];

    // 检查目录是否存在
    if (directory.existsSync()) {
      // 同步遍历目录中的所有实体（文件和子目录）
      final entities = directory.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          // 获取文件名
          final currentFileName =
              entity.path.split(Platform.pathSeparator).last;

          bool isMatch = false;
          if (fileName != null) {
            // 根据文件名匹配
            isMatch = currentFileName == fileName &&
                currentFileName.endsWith('.yaml');
          } else if (regexPattern != null) {
            // 根据正则表达式匹配
            final regex = RegExp(regexPattern);
            isMatch = regex.hasMatch(currentFileName) &&
                currentFileName.endsWith('.yaml');
          }

          if (isMatch) {
            yamlFiles.add(entity);
          }
        }
      }
    }

    return yamlFiles;
  }
}

/// Ref to project path
class ProjectRef {
  /// Constructor
  const ProjectRef({
    required this.name,
    required this.path,
  });

  /// Project name
  final String name;

  /// Project path
  final String path;

  /// Creates a project path from map
  factory ProjectRef.fromMap(Map<String, String> map) {
    return ProjectRef(
      name: map['name'] ?? '',
      path: map['path'] ?? '',
    );
  }

  /// Returns project path as a map
  Map<String, String> toMap() {
    return {
      'name': name,
      'path': path,
    };
  }
}

/// Project path adapter
class ProjectPathAdapter extends TypeAdapter<ProjectRef> {
  @override
  int get typeId => 2; // this is unique, no other Adapter can have the same id.

  @override
  ProjectRef read(BinaryReader reader) {
    final value = Map<String, String>.from(reader.readMap());
    return ProjectRef.fromMap(value);
  }

  @override
  void write(BinaryWriter writer, ProjectRef obj) {
    writer.writeMap(obj.toMap());
  }
}

/// 查找规则类，支持多级键  default is pubspec
class LookupRule {
  final String? fileName;
  final String? regexPattern;
  final List<String> keys;

  LookupRule(this.keys, {this.fileName, this.regexPattern});
}
