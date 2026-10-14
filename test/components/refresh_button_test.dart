import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidekick/src/components/atoms/refresh_button.dart';

import '../helpers/app.dart';

void main() {
  testWidgets('stops spinning when the refresh fails', (tester) async {
    var calls = 0;
    await pumpTestApp(
      tester,
      Scaffold(
        body: RefreshButton(
          onPressed: () async {
            calls++;
            throw Exception('load failed');
          },
        ),
      ),
    );

    await tester.tap(find.byType(RefreshButton));
    await tester.pump();
    expect(tester.takeException(), isA<Exception>());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Can be pressed again
    await tester.tap(find.byType(RefreshButton));
    await tester.pump();
    tester.takeException();
    expect(calls, 2);
  });
}
