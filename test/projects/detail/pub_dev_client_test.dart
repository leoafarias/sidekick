import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick/src/modules/projects/detail/pub_dev_client.dart';

void main() {
  test('returns the latest version', () async {
    late http.Request request;
    final client = PubDevClient(MockClient((req) async {
      request = req;
      return http.Response(
        jsonEncode({
          'name': 'http',
          'latest': {'version': '1.2.2'},
          'versions': [],
        }),
        200,
      );
    }));

    expect(await client.latestVersion('http'), Version.parse('1.2.2'));
    expect(request.url.toString(), 'https://pub.dev/api/packages/http');
    expect(request.headers['Accept'], 'application/vnd.pub.v2+json');
  });

  Matcher throwsPubDev(PubDevErrorKind kind) => throwsA(
        isA<PubDevException>().having((e) => e.kind, 'kind', kind),
      );

  test('reports unknown packages', () {
    final client =
        PubDevClient(MockClient((_) async => http.Response('{}', 404)));

    expect(
        client.latestVersion('nope'), throwsPubDev(PubDevErrorKind.notFound));
  });

  test('reports offline, server errors and bad responses as unavailable',
      () async {
    final offline = PubDevClient(MockClient((_) async {
      throw const SocketException('Failed host lookup: pub.dev');
    }));
    final serverError =
        PubDevClient(MockClient((_) async => http.Response('oops', 500)));
    final badJson =
        PubDevClient(MockClient((_) async => http.Response('<html>', 200)));

    for (final client in [offline, serverError, badJson]) {
      await expectLater(
        client.latestVersion('http'),
        throwsPubDev(PubDevErrorKind.unavailable),
      );
    }
  });

  test('times out', () async {
    final hanging = Completer<http.Response>();
    final client = PubDevClient(
      MockClient((_) => hanging.future),
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      client.latestVersion('http'),
      throwsPubDev(PubDevErrorKind.unavailable),
    );
  });

  test('limits concurrent requests', () async {
    var active = 0;
    var maxActive = 0;
    final client = PubDevClient(
      MockClient((_) async {
        active++;
        maxActive = active > maxActive ? active : maxActive;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return http.Response('{"latest": {"version": "1.0.0"}}', 200);
      }),
      maxConcurrentRequests: 2,
    );

    await Future.wait(
        [for (var i = 0; i < 8; i++) client.latestVersion('p$i')]);

    expect(maxActive, 2);
  });
}
