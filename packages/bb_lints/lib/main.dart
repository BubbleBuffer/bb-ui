// The bb_lints analyzer plugin. Enable it in analysis_options.yaml; see
// README.md.

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/fixes.dart';
import 'src/rules.dart';

final plugin = BbLintsPlugin();

class BbLintsPlugin extends Plugin {
  @override
  String get name => 'bb_lints';

  @override
  void register(PluginRegistry registry) {
    for (final rule in warningRules) {
      registry.registerWarningRule(rule);
    }
    for (final rule in lintRules) {
      registry.registerLintRule(rule);
    }
    registerFixes(registry);
  }
}
