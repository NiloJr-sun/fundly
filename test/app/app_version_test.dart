import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/app/app_version.dart';

void main() {
  test('the shown version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: (\S+)\+(\d+)$',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(appVersion, version.group(1));
    expect(appBuild, int.parse(version.group(2)!));
    expect(appVersionText, 'Version $appVersion ($appBuild)');
  });
}
