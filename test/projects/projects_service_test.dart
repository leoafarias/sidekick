import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:sidekick/src/modules/projects/project.dto.dart';
import 'package:sidekick/src/modules/projects/projects.service.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory temp;
  late String hivePath;
  late String projectsRoot;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ProjectPathAdapter());
    }
  });

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('sidekick_projects_test');
    hivePath = p.join(temp.path, 'hive');
    projectsRoot = p.join(temp.path, 'projects');
    Directory(hivePath).createSync(recursive: true);
    Hive.init(hivePath);
  });

  tearDown(() async {
    await ProjectsService.close();
    await Hive.close();
    temp.deleteSync(recursive: true);
  });

  group('path helpers', () {
    test('Windows paths compare case and separator insensitive', () {
      final windows = p.windows;
      expect(
        isSameProjectPath(r'C:\Users\Dev\My App', 'c:/users/dev/my app/',
            context: windows),
        isTrue,
      );
      expect(
        isSameProjectPath(r'C:\Users\Dev\app', r'C:\Users\Dev\app2',
            context: windows),
        isFalse,
      );
    });

    test('POSIX paths compare case sensitive', () {
      expect(
        isSameProjectPath('/Users/dev/App', '/Users/dev/app', context: p.posix),
        isFalse,
      );
    });

    test('normalizes separators, dots and trailing separators', () {
      expect(
        normalizeProjectPath(r'C:\Users\dev\tmp\..\app\', context: p.windows),
        r'C:\Users\dev\app',
      );
      expect(
        normalizeProjectPath('/Users/dev/./app/', context: p.posix),
        '/Users/dev/app',
      );
    });
  });

  group('storage', () {
    test('adds a project once, even through a different spelling', () async {
      await ProjectsService.init();
      final path = createFlutterApp(projectsRoot);

      expect(await ProjectsService.add(path), isTrue);
      expect(await ProjectsService.add('$path${p.separator}'), isFalse);
      expect(
        await ProjectsService.add(p.join(path, '..', p.basename(path))),
        isFalse,
      );
      expect(ProjectsService.paths, [path]);
    });

    test('stores paths that do not fit in a Hive key', () async {
      await ProjectsService.init();
      // 169 characters but more than 255 UTF-8 bytes: Hive 2.2.3 used to
      // write a corrupt box when this was used as a key.
      final name = 'Compañía ${'ñ' * 120}';
      final path = createFlutterApp(projectsRoot, name: name);
      expect(path.length, lessThan(255 + temp.path.length));

      expect(await ProjectsService.add(path), isTrue);

      // Reopen the box from disk
      await ProjectsService.close();
      await ProjectsService.init();

      expect(ProjectsService.paths, [path]);
      final projects = await ProjectsService.load();
      expect(projects.single.invalid, isFalse);
    });

    test('removes a project', () async {
      await ProjectsService.init();
      final a = createFlutterApp(projectsRoot, name: 'a');
      final b = createFlutterApp(projectsRoot, name: 'b');
      await ProjectsService.add(a);
      await ProjectsService.add(b);

      await ProjectsService.remove('$a${p.separator}');

      expect(ProjectsService.paths, [b]);
    });
  });

  group('load', () {
    test('a broken project does not hide the others', () async {
      await ProjectsService.init();
      final good = createFlutterApp(projectsRoot, name: 'good');
      final badPubspec = createFlutterApp(
        projectsRoot,
        name: 'bad_pubspec',
        pubspec: 'name: bad_pubspec\nversion: not-a-version\n'
            'dependencies:\n  flutter:\n    sdk: flutter\n',
      );
      // A JSON list makes FVM throw a TypeError, which is not an Exception
      final badConfig =
          createFlutterApp(projectsRoot, name: 'bad_config', fvmrc: '[]');
      final badVersion = createFlutterApp(
        projectsRoot,
        name: 'bad_version',
        fvmrc: '{"flutter": "3.24.0@nightly"}',
      );
      final dartOnly = p.join(projectsRoot, 'dart_only');
      writeFile(dartOnly, 'pubspec.yaml', 'name: dart_only\n');
      final noPubspec = p.join(projectsRoot, 'no_pubspec');
      Directory(noPubspec).createSync(recursive: true);
      final missing = p.join(projectsRoot, 'missing');

      for (final path in [
        good,
        badPubspec,
        badConfig,
        badVersion,
        dartOnly,
        noPubspec,
        missing,
      ]) {
        await ProjectsService.add(path);
      }

      final projects = await ProjectsService.load();
      final byName = {for (final p in projects) p.name: p};

      expect(projects, hasLength(7));
      expect(byName['good']!.invalid, isFalse);
      expect(byName['good']!.pinnedVersion?.name, '3.24.0');
      expect(byName['bad_pubspec']!.loadError, ProjectLoadError.unreadable);
      expect(byName['bad_config']!.loadError, ProjectLoadError.unreadable);
      expect(byName['bad_version']!.loadError, ProjectLoadError.unreadable);
      expect(byName['dart_only']!.loadError, ProjectLoadError.notFlutter);
      expect(byName['no_pubspec']!.loadError, ProjectLoadError.missingPubspec);
      expect(byName['missing']!.loadError, ProjectLoadError.notFound);
    });

    test('keeps projects whose folder is temporarily missing', () async {
      await ProjectsService.init();
      final path = createFlutterApp(projectsRoot);
      await ProjectsService.add(path);
      final moved = '$path.moved';
      Directory(path).renameSync(moved);

      expect((await ProjectsService.load()).single.loadError,
          ProjectLoadError.notFound);
      // Still stored, so it comes back once the folder is reachable again
      Directory(moved).renameSync(path);
      expect((await ProjectsService.load()).single.invalid, isFalse);
    });

    test('reads the legacy .fvm/fvm_config.json', () async {
      await ProjectsService.init();
      final path = createFlutterApp(projectsRoot, fvmrc: null);
      writeFile(path, '.fvm/fvm_config.json', '{"flutterSdkVersion": "beta"}');

      final project = ProjectsService.loadProject(path);

      expect(project.pinnedVersion?.name, 'beta');
    });
  });

  group('legacy storage', () {
    test('migrates projects keyed by path', () async {
      final a = createFlutterApp(projectsRoot, name: 'a');
      final b = createFlutterApp(projectsRoot, name: 'b');
      final legacy = await Hive.openBox<ProjectRef>('projects_service_box');
      await legacy.put(a, ProjectRef(name: a.split('/').last, path: a));
      await legacy.put(b, ProjectRef(name: 'b', path: b));
      // Duplicate spelling from older versions
      await legacy.put('$b/', ProjectRef(name: 'b', path: '$b/'));
      await legacy.close();

      await ProjectsService.init();

      expect(ProjectsService.paths, [a, b]);
      expect(await Hive.boxExists('projects_service_box'), isFalse);
    });

    test('starts even if the legacy box is corrupted', () async {
      // Written by Hive 2.2.3 without asserts (as in release builds) with a
      // path key over 255 UTF-8 bytes. Opening it throws a HiveError.
      final legacyFile = File(p.join(hivePath, 'projects_service_box.hive'));
      File('test/fixtures/corrupted_projects_box.hive').copySync(
        legacyFile.path,
      );

      await ProjectsService.init();

      expect(ProjectsService.paths, isEmpty);
      final path = createFlutterApp(projectsRoot);
      expect(await ProjectsService.add(path), isTrue);
      expect(ProjectsService.paths, [path]);
      // The unreadable file is kept untouched
      expect(legacyFile.existsSync(), isTrue);
    });
  });
}
