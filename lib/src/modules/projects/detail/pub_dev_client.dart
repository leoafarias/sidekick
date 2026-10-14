import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pool/pool.dart';
import 'package:pub_semver/pub_semver.dart';

/// Why the latest version of a package is unknown
enum PubDevErrorKind {
  /// pub.dev could not be reached (offline, timeout, server error)
  unavailable,

  /// The package does not exist on pub.dev
  notFound,
}

/// Error while talking to pub.dev
class PubDevException implements Exception {
  /// Constructor
  const PubDevException(this.kind, this.message);

  /// Kind of error
  final PubDevErrorKind kind;

  /// Details
  final String message;

  @override
  String toString() => 'PubDevException($kind): $message';
}

/// Minimal client for the pub.dev API
class PubDevClient {
  /// Constructor. [client] is injectable for tests.
  PubDevClient(
    this._client, {
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 15),
    int maxConcurrentRequests = 6,
  })  : _baseUrl = baseUrl ?? Uri.parse('https://pub.dev'),
        _pool = Pool(maxConcurrentRequests);

  final http.Client _client;
  final Uri _baseUrl;
  final Pool _pool;

  /// Timeout for each request
  final Duration timeout;

  /// Returns the latest stable version of [package].
  ///
  /// Throws a [PubDevException] when the version can't be determined.
  Future<Version> latestVersion(String package) {
    return _pool.withResource(() async {
      final url = _baseUrl.replace(
        pathSegments: ['api', 'packages', package],
      );
      final http.Response response;
      try {
        response = await _client.get(
          url,
          headers: const {'Accept': 'application/vnd.pub.v2+json'},
        ).timeout(timeout);
      } on TimeoutException catch (e) {
        throw PubDevException(PubDevErrorKind.unavailable, e.toString());
      } on Exception catch (e) {
        // SocketException, http.ClientException, HandshakeException...
        throw PubDevException(PubDevErrorKind.unavailable, e.toString());
      }

      if (response.statusCode == 404) {
        throw PubDevException(PubDevErrorKind.notFound, package);
      }
      if (response.statusCode != 200) {
        throw PubDevException(
          PubDevErrorKind.unavailable,
          'HTTP ${response.statusCode}',
        );
      }

      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final latest = json['latest'] as Map<String, dynamic>;
        return Version.parse(latest['version'] as String);
      } catch (e) {
        throw PubDevException(
          PubDevErrorKind.unavailable,
          'Unexpected response: $e',
        );
      }
    });
  }

  /// Closes the underlying client
  void close() => _client.close();
}
