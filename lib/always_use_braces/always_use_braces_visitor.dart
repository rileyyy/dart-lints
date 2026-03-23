import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class AlwaysUseBracesVisitor extends RecursiveAstVisitor<void> {
  AlwaysUseBracesVisitor({required this.onError});

  final void Function(Token) onError;

  @override
  void visitIfStatement(IfStatement node) {
    super.visitIfStatement(node);

    // Check the 'then' statement
    final thenStatement = node.thenStatement;
    if (thenStatement is! Block) {
      onError(thenStatement.beginToken);
    }

    // Check the 'else' statement if it exists
    final elseStatement = node.elseStatement;
    if (elseStatement != null &&
        elseStatement is! Block &&
        elseStatement is! IfStatement) {
      onError(elseStatement.beginToken);
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    super.visitForStatement(node);

    final body = node.body;
    if (body is! Block) {
      onError(body.beginToken);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    super.visitWhileStatement(node);

    final body = node.body;
    if (body is! Block) {
      onError(body.beginToken);
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    super.visitDoStatement(node);

    final body = node.body;
    if (body is! Block) {
      onError(body.beginToken);
    }
  }
}
