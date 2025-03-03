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
    // Define a list of search rules, sorted by priority
    List<LookupRule> lookupRules = [
      LookupRule(
          ['sidekick', 'icon']), // Highest priority: pubspec.yaml sidekick.icon
      LookupRule([
        'flutter_launcher_icons',
        'image_path'
      ]), // pubspec.yaml  flutter_launcher_icons.image_path
      LookupRule(['flutter_launcher_icons', 'image_path'],
          fileName: "flutter_launcher_icons.yaml"),
      LookupRule(['flutter_launcher_icons', 'image_path'],
          regexPattern: r'^flutter_launcher_icons-(.*).yaml$'),
      // You can add multiple levels of nested search rules, for example
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
            // TODO: Determine whether the path is a local path or a network path
            File imgFile = File(join(projectDir.path, currentMap));
            if (imgFile.existsSync()) {
              return Image.file(imgFile);
            }
          }
        } catch (e) {
          // Handle possible exceptions when parsing YAML files
          print('Error parsing YAML file ${lookUpFile.path}: $e');
        }
      }
    }

    // Traverse the project assets directory to find the logo file
    List<File> findImageFiles = findLogoImages(join(projectDir.path, "assets"));
    if (findImageFiles.isNotEmpty) {
      return Image.file(findImageFiles.first);
    }

    return FlutterLogo();
  }

  /// Define the file extension of the logo image
  static List<String> imageExtensions = ['.png', '.jpg', '.jpeg'];

  /// Get the file that may be the logo in the project assets path
  /// Traverse the directory and search for image files whose names contain logo
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

  /// Synchronously retrieve YAML files based on file name or regular expression
  List<File> getYamlFilesSync(String directoryPath,
      {String? fileName, String? regexPattern}) {
    final directory = Directory(directoryPath);
    final yamlFiles = <File>[];

    // Check if a directory exists
    if (directory.existsSync()) {
      // Synchronously traverse all entities (files and subdirectories) in a directory
      final entities = directory.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          // Get the file name
          final currentFileName =
              entity.path.split(Platform.pathSeparator).last;

          bool isMatch = false;
          if (fileName != null) {
            // Matching by file name
            isMatch = currentFileName == fileName &&
                currentFileName.endsWith('.yaml');
          } else if (regexPattern != null) {
            // Matching by regular expression
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

/// Search rule class, supports multi-level keys, default fileName is pubspec
class LookupRule {
  final String? fileName;
  final String? regexPattern;
  final List<String> keys;

  LookupRule(this.keys, {this.fileName, this.regexPattern});
}
