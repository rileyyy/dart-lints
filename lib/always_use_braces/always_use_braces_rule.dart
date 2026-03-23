import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/error/error.dart';
import 'package:dart_lints/always_use_braces/always_use_braces_visitor.dart';

class AlwaysUseBracesRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'always_use_braces',
    'Always use braces for control statements',
    correctionMessage: 'Wrap the statement in braces.',
    severity: DiagnosticSeverity.INFO,
  );

  AlwaysUseBracesRule()
    : super(name: code.lowerCaseName, description: code.problemMessage);

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = AlwaysUseBracesVisitor(onError: reportAtToken);
    registry
      ..addIfStatement(this, visitor)
      ..addForStatement(this, visitor)
      ..addWhileStatement(this, visitor)
      ..addDoStatement(this, visitor);
  }
}
