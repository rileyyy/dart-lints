import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:dart_lints/always_use_braces/always_use_braces_visitor.dart';
import 'package:test/test.dart';

void main() {
  test('reports if statement without braces', () {
    const code = '''
void main() {
  if (true) print('hello');
}
''';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });

  test('reports for statement without braces', () {
    const code = '''
void main() {
  for (var i = 0; i < 10; i++) print(i);
}
''';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });

  test('reports while statement without braces', () {
    const code = '''
void main() {
  var i = 0;
  while (i < 10) i++;
}
''';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });

  test('reports do-while statement without braces', () {
    const code = '''
void main() {
  var i = 0;
  do i++; while (i < 10);
}
''';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });

  test('reports else statement without braces', () {
    const code = '''
void main() {
  if (true) {
    print('true');
  } else print('false');
}
''';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });

  test('does not report if statement with braces', () {
    const code = '''
void main() {
  if (true) {
    print('hello');
  }
}
''';

    final errors = _collectErrors(code);
    expect(errors, isEmpty);
  });

  test('does not report for statement with braces', () {
    const code = '''
void main() {
  for (var i = 0; i < 10; i++) {
    print(i);
  }
}
''';

    final errors = _collectErrors(code);
    expect(errors, isEmpty);
  });

  test('does not report while statement with braces', () {
    const code = '''
void main() {
  var i = 0;
  while (i < 10) {
    i++;
  }
}
''';

    final errors = _collectErrors(code);
    expect(errors, isEmpty);
  });

  test('does not report do-while statement with braces', () {
    const code = '''
void main() {
  var i = 0;
  do {
    i++;
  } while (i < 10);
}
''';

    final errors = _collectErrors(code);
    expect(errors, isEmpty);
  });

  test('does not report else if without braces (chained if)', () {
    const code = '''
void main() {
  if (true) {
    print('true');
  } else if (false) {
    print('false');
  }
}
''';

    final errors = _collectErrors(code);
    expect(errors, isEmpty);
  });

  test('reports nested if without braces', () {
    const code = '''
void main() {
  if (true) {
    if (false) print('nested');
  }
}
''';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });

  test('reports single-line if on same line', () {
    const code = 'void main() { if (true) print("test"); }';

    final errors = _collectErrors(code);
    expect(errors, isNotEmpty);
  });
}

List<String> _collectErrors(String code) {
  final result = parseString(content: code);
  final errors = <String>[];
  final visitor = AlwaysUseBracesVisitor(
    onError: (token) => errors.add(token.lexeme),
  );

  result.unit.accept(visitor);
  return errors;
}
