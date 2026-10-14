import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/src/modules/projects/components/project_actions.dart';
import 'package:sidekick/src/modules/projects/components/project_list_item.dart';
import 'package:sidekick/src/modules/projects/project.dto.dart';

import '../helpers/app.dart';

void main() {
  testWidgets('shows why a stored project could not be loaded', (tester) async {
    final project = FlutterProject.unavailable(
      '/Volumes/USB/my_app',
      ProjectLoadError.notFound,
    );

    setWindowSize(tester, const Size(340, 200));
    await pumpTestApp(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(10),
          child: ProjectListItem(project, versionSelect: true),
        ),
      ),
    );
    await takeScreenshot(tester, 'project_unavailable_card');

    expect(find.text('my_app'), findsOneWidget);
    expect(find.text('Project folder not found'), findsOneWidget);
    expect(find.text('/Volumes/USB/my_app'), findsOneWidget);
    // Can still be removed through the actions menu
    await tester.tap(find.byType(ProjectActions));
    await tester.pumpAndSettle();
    expect(find.text('Remove'), findsOneWidget);
  });
}
