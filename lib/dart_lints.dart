import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:dart_lints/blank_line_after_brace/blank_line_after_brace_rule.dart';

class DartLints extends Plugin {
  @override
  String get name => 'DartLints';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(BlankLineAfterBraceRule());
  }
}
