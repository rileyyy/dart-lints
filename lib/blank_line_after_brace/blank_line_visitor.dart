import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class BlankLineVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  BlankLineVisitor(this.rule, this.context);

  @override
  void visitBlock(Block node) {
    super.visitBlock(node);

    final rightBracket = node.rightBracket;
    final next = rightBracket.next;

    if (next == null) return;

    // Ignore if next token is another '}'
    if (next.lexeme == '}') return;

    final compilationUnit = node.root as CompilationUnit;
    final lineInfo = compilationUnit.lineInfo;
    final currentLine = lineInfo.getLocation(rightBracket.offset).lineNumber;
    final nextLine = lineInfo.getLocation(next.offset).lineNumber;

    final lineDiff = nextLine - currentLine;

    // We want at least one blank line => difference >= 2
    if (lineDiff < 2) {
      rule.reportAtToken(rightBracket);
    }
  }
}
