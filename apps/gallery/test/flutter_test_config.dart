// Real bundled typefaces keep Linux golden rendering deterministic.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const families = {
    'Bricolage Grotesque': ['BricolageGrotesque[opsz,wdth,wght].ttf'],
    'Atkinson Hyperlegible Next': [
      'AtkinsonHyperlegibleNext[wght].ttf',
      'AtkinsonHyperlegibleNext-Italic[wght].ttf',
    ],
    'Fragment Mono': ['FragmentMono-Regular.ttf', 'FragmentMono-Italic.ttf'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
  await testMain();
}
