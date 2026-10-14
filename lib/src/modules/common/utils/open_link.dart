import 'dart:io';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> openLink(String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    throw "Error";
  }
}

Future<void> openPath(String url) async {
  if (Platform.isWindows) {
    await Process.start('start', [url]);
  } else if (Platform.isMacOS) {
    await Process.start('open', [url]);
  } else if (Platform.isLinux) {
    await Process.start('xdg-open', [url]);
  }
}

Future<void> openCustom(
  String path, {
  String? customLocation,
}) async {
  if (customLocation == null) {
    return await openPath(path);
  }
  if (Platform.isMacOS) {
    await Process.run(
      "open",
      ["-a", customLocation, path],
      runInShell: true,
    );
  } else {
    await Process.run(
      customLocation,
      [path],
      runInShell: true,
    );
  }
}
