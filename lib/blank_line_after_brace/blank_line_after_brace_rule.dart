import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/error/error.dart';

import 'package:dart_lints/blank_line_after_brace/blank_line_visitor.dart';

class BlankLineAfterBraceRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'blank_line_after_closing_brace',
    'Require a blank line after a closing curly brace.',
    correctionMessage: 'Add a blank line after the curly brace to improve readability.',
    severity: DiagnosticSeverity.INFO,
  );

  BlankLineAfterBraceRule() : super(name: code.lowerCaseName, description: code.problemMessage);

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    var visitor = BlankLineVisitor(this, context);
    registry.addAwaitExpression(this, visitor);
  }
}
