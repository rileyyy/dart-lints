import 'dart:io';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:dart_lints/always_use_braces/always_use_braces_fix.dart';
import 'package:dart_lints/always_use_braces/always_use_braces_rule.dart';
import 'package:dart_lints/always_use_braces/always_use_braces_visitor.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync(
      'always_use_braces_fix_test_',
    );
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Future<(ResolvedUnitResult, ResolvedLibraryResult)> analyze(
    String code,
  ) async {
    final file = File('${tempDir.path}/test.dart')..writeAsStringSync(code);
    final normalizedPath = file.resolveSymbolicLinksSync();

    final session = AnalysisContextCollection(
      includedPaths: [tempDir.resolveSymbolicLinksSync()],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    ).contextFor(normalizedPath).currentSession;

    final unitResult = await session.getResolvedUnit(normalizedPath);
    final libraryResult = await session.getResolvedLibraryContaining(
      normalizedPath,
    );

    return (
      unitResult as ResolvedUnitResult,
      libraryResult as ResolvedLibraryResult,
    );
  }

  int? findErrorOffset(String code) {
    int? offset;
    final visitor = AlwaysUseBracesVisitor(
      onError: (token) => offset ??= token.offset,
    );

    parseString(content: code).unit.accept(visitor);
    return offset;
  }

  Future<String?> applyFix(String code) async {
    final offset = findErrorOffset(code);
    if (offset == null) return null;

    final (unitResult, libraryResult) = await analyze(code);

    final source = FileSource(
      PhysicalResourceProvider.INSTANCE.getFile(unitResult.path),
    );

    final diagnostic = Diagnostic.forValues(
      source: source,
      offset: offset,
      length: 1,
      diagnosticCode: AlwaysUseBracesRule.code,
      message: AlwaysUseBracesRule.code.problemMessage,
    );

    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      diagnostic: diagnostic,
      selectionOffset: offset,
      selectionLength: 1,
    );

    final builder = ChangeBuilder(session: unitResult.session);
    await AlwaysUseBracesFix(context: context).compute(builder);

    final edits = builder.sourceChange.edits;
    if (edits.isEmpty) return null;

    return SourceEdit.applySequence(code, edits.first.edits);
  }

  test('adds braces to single-line if statement', () async {
    const code = '''
void main() {
  if (true) print('hello');
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('if (true) {'));
    expect(result, contains("  print('hello');"));
    expect(result, contains('}'));
  });

  test('adds braces to multi-line if statement', () async {
    const code = '''
void main() {
  if (true)
    print('hello');
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('if (true) {'));
    expect(result, contains("  print('hello');"));
  });

  test('adds braces to else statement', () async {
    const code = '''
void main() {
  if (true) {
    print('true');
  } else print('false');
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('} else {'));
    expect(result, contains("  print('false');"));
  });

  test('adds braces to for loop', () async {
    const code = '''
void main() {
  for (var i = 0; i < 10; i++) print(i);
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('for (var i = 0; i < 10; i++) {'));
    expect(result, contains('  print(i);'));
  });

  test('adds braces to while loop', () async {
    const code = '''
void main() {
  var i = 0;
  while (i < 10) i++;
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('while (i < 10) {'));
    expect(result, contains('  i++;'));
  });

  test('adds braces to do-while loop', () async {
    const code = '''
void main() {
  var i = 0;
  do i++; while (i < 10);
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('do {'));
    expect(result, contains('  i++;'));
    expect(result, contains('} while (i < 10);'));
  });

  test('preserves indentation correctly', () async {
    const code = '''
void main() {
  if (condition) {
    if (nested) print('nested');
  }
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('if (nested) {'));
    expect(result, contains("      print('nested');"));
  });

  test('handles statement with semicolon', () async {
    const code = '''
void main() {
  if (true) return;
}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('if (true) {'));
    expect(result, contains('  return;'));
    expect(result, contains('}'));
  });

  test('fix metadata is correct', () async {
    final (unitResult, libraryResult) = await analyze('''
void main() {
  if (true) print('test');
}
''');

    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      diagnostic: null,
    );

    final fix = AlwaysUseBracesFix(context: context);
    expect(fix.fixKind.id, 'dart.fix.add_braces');
    expect(fix.fixKind.message, 'Add braces');
    expect(fix.applicability, CorrectionApplicability.acrossFiles);
  });

  test('does not apply fix when statement already has braces', () {
    const code = '''
void main() {
  if (true) {
    print('hello');
  }
}
''';

    final offset = findErrorOffset(code);
    expect(offset, isNull);
  });
}
