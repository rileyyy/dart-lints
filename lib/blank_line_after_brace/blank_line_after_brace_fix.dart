import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class BlankLineAfterBraceFix extends ResolvedCorrectionProducer {
  static const _addBlankLineKind = FixKind('dart.fix.blankline', DartFixKindPriority.inFile, 'Add an empty line');

  BlankLineAfterBraceFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.acrossFiles;

  @override
  FixKind get fixKind => _addBlankLineKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (diagnosticOffset == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(diagnosticOffset! + 1, (builder) {
        builder.write('\n');
      });
    });
  }
}
