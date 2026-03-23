import 'dart:io';

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:dart_lints/blank_line_after_brace/blank_line_after_brace_fix.dart';
import 'package:dart_lints/blank_line_after_brace/blank_line_after_brace_rule.dart';
import 'package:dart_lints/blank_line_after_brace/blank_line_visitor.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('blank_line_fix_test_');
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
    final visitor = BlankLineVisitor(
      onError: (token) => offset ??= token.offset,
    );
    final unit = parseString(content: code).unit;
    void walk(AstNode node) {
      if (node is Block) visitor.visitBlock(node);
      for (final child in node.childEntities.whereType<AstNode>()) {
        walk(child);
      }
    }

    walk(unit);
    return offset;
  }

  Future<String?> applyFix(String code) async {
    final offset = findErrorOffset(code);
    if (offset == null) return null;

    final (unitResult, libraryResult) = await analyze(code);

    final resourceProvider = PhysicalResourceProvider.INSTANCE;
    final source = FileSource(resourceProvider.getFile(unitResult.path));

    final diagnostic = Diagnostic.forValues(
      source: source,
      offset: offset,
      length: 1,
      diagnosticCode: BlankLineAfterBraceRule.code,
      message: BlankLineAfterBraceRule.code.problemMessage,
    );

    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      diagnostic: diagnostic,
      selectionOffset: offset,
      selectionLength: 1,
    );

    final fix = BlankLineAfterBraceFix(context: context);
    final builder = ChangeBuilder(session: unitResult.session);
    await fix.compute(builder);

    final edits = builder.sourceChange.edits;
    if (edits.isEmpty) return null;

    return SourceEdit.applySequence(code, edits.first.edits);
  }

  test('inserts a blank line after the closing brace', () async {
    const code = '''
void a() {
  print('a');
}
void b() {}
''';

    final result = await applyFix(code);
    expect(result, isNotNull);
    expect(result, contains('}\n\n'));
  });

  test('fix is a no-op when no diagnostic offset is present', () async {
    final (unitResult, libraryResult) = await analyze('void a() {}\n');

    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      diagnostic: null,
    );

    final fix = BlankLineAfterBraceFix(context: context);
    final builder = ChangeBuilder(session: unitResult.session);
    await fix.compute(builder);

    expect(builder.sourceChange.edits, isEmpty);
  });

  test('inserted newline produces exactly one blank line', () async {
    const code = "void a() {\n  print('a');\n}\nvoid b() {}\n";

    final result = await applyFix(code);
    expect(result, isNotNull);
    // The fix inserts exactly one extra newline so the diff is just one '\n'.
    final fixedLines = result!.split('\n');
    final original = code.split('\n');
    expect(fixedLines.length, original.length + 1);
  });

  test('fix metadata is correct', () async {
    final (unitResult, libraryResult) = await analyze('void a() {}\n');

    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      diagnostic: null,
    );

    final fix = BlankLineAfterBraceFix(context: context);
    expect(fix.fixKind.id, 'dart.fix.blankline');
    expect(fix.fixKind.message, 'Add an empty line');
    expect(fix.applicability, CorrectionApplicability.acrossFiles);
  });
}
