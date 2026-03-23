import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AlwaysUseBracesFix extends ResolvedCorrectionProducer {
  static const _addBracesKind = FixKind(
    'dart.fix.add_braces',
    DartFixKindPriority.inFile,
    'Add braces',
  );

  AlwaysUseBracesFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _addBracesKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Find the statement that needs braces
    Statement? targetStatement;
    AstNode? current = node;

    // Walk up the tree to find the parent control structure
    while (current != null) {
      final parent = current.parent;
      if (parent is IfStatement) {
        if (parent.thenStatement == current && current is! Block) {
          targetStatement = parent.thenStatement;
          break;
        } else if (parent.elseStatement == current && current is! Block) {
          targetStatement = parent.elseStatement;
          break;
        }
      } else if (parent is ForStatement) {
        if (parent.body == current && current is! Block) {
          targetStatement = parent.body;
          break;
        }
      } else if (parent is WhileStatement) {
        if (parent.body == current && current is! Block) {
          targetStatement = parent.body;
          break;
        }
      } else if (parent is DoStatement) {
        if (parent.body == current && current is! Block) {
          targetStatement = parent.body;
          break;
        }
      }

      current = parent;
    }

    if (targetStatement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      final statementText = unitResult.content.substring(
        targetStatement!.offset,
        targetStatement.end,
      );

      // Add one level of indentation for the statement inside braces
      final indent = unitResult.content.substring(
        unitResult.content.lastIndexOf('\n', targetStatement.offset) + 1,
        targetStatement.offset,
      );

      builder.addSimpleReplacement(
        SourceRange(
          targetStatement.offset,
          targetStatement.end - targetStatement.offset,
        ),
        '{${utils.endOfLine}$indent  $statementText${utils.endOfLine}$indent}',
      );
    });
  }
}
