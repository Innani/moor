import 'package:analyzer/dart/element/element.dart';
import 'package:sally_generator/src/model/specified_table.dart';

class SpecifiedDatabase {
  final ClassElement fromClass;
  final List<SpecifiedTable> tables;

  SpecifiedDatabase(this.fromClass, this.tables);
}
