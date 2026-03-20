import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:dart_lints/blank_line_after_brace/blank_line_visitor.dart';
import 'package:test/test.dart';

void main() {
  test('reports when no blank line after brace', () {
    const code = '''
void a() {
  print('a');
}
void b() {}
''';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });

  test('does not report when blank line exists', () {
    const code = '''
void a() {
  print('a');
}

void b() {}
''';

    final errors = _collectErrors(code);
    expect(errors, isEmpty);
  });

  test('does not report when next token is }', () {
    const code = '''
void a() {
  if (true) {
    print('x');
  }
}
''';

    final errors = _collectErrors(code);
    expect(errors, isEmpty);
  });
}

List<String> _collectErrors(String code) {
  final result = parseString(content: code);
  final errors = <String>[];
  final visitor = BlankLineVisitor(onError: (token) => errors.add(token.lexeme));

  void walk(AstNode node) {
    if (node is Block) visitor.visitBlock(node);
    for (final child in node.childEntities.whereType<AstNode>()) {
      walk(child);
    }
  }

  walk(result.unit);
  return errors;
}
