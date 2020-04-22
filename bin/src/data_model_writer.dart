import 'package:recase/recase.dart';

import 'model/item_type/array_type.dart';
import 'model/model.dart';
import 'util/type_checker.dart';

class DataModelWriter {
  final String projectName;
  final Model jsonModel;

  const DataModelWriter(this.projectName, this.jsonModel);

  String write() {
    final sb = StringBuffer();

    final containsRequiredFields =
        jsonModel.fields.where((item) => item.required).toList().isNotEmpty;
    if (containsRequiredFields) {
      sb.writeln("import 'package:flutter/material.dart';");
    }

    sb.writeln("import 'package:json_annotation/json_annotation.dart';");

    jsonModel.fields.forEach((field) {
      if (!TypeChecker.isKnownDartType(field.type.name)) {
        final reCaseFieldName = ReCase(field.type.name);
        String import;
        if (field.path == null) {
          import =
              "import 'package:$projectName/model/${reCaseFieldName.snakeCase}.dart';";
        } else {
          import =
              "import 'package:$projectName/model/${field.path}/${reCaseFieldName.snakeCase}.dart';";
        }
        if (!sb.toString().contains(import)) {
          sb.writeln(import);
        }
      }
    });

    sb
      ..writeln()
      ..writeln("part '${jsonModel.fileName}.g.dart';")
      ..writeln()
      ..writeln('@JsonSerializable()')
      ..writeln('class ${jsonModel.name} {');

    jsonModel.fields.sort((a, b) {
      final b1 = a.required ? 1 : 0;
      final b2 = b.required ? 1 : 0;
      return b2 - b1;
    });

    jsonModel.fields.forEach((key) {
      sb.write("  @JsonKey(name: '${key.serializedName}'");
      if (key.required) {
        sb.write(', required: true');
      } else {
        sb.write(', nullable: true');
      }

      if (key.ignore) {
        sb.write(', ignore: true');
      }
      sb.writeln(')');
      if (key.ignore) {
        sb.write('  ');
      } else {
        sb.write('  final ');
      }
      if (key.type is ArrayType) {
        sb.writeln('List<${key.type.name}> ${key.name};');
      } else {
        sb.writeln('${key.type.name} ${key.name};');
      }
    });

    sb..writeln()..writeln('  ${jsonModel.name}({');

    jsonModel.fields.forEach((key) {
      if (key.required) {
        sb.writeln('    @required this.${key.name},');
      } else {
        sb.writeln('    this.${key.name},');
      }
    });
    sb
      ..writeln('  });')
      ..writeln()
      ..writeln(
          '  factory ${jsonModel.name}.fromJson(Map<String, dynamic> json) => _\$${jsonModel.name}FromJson(json);')
      ..writeln()
      ..writeln(
          '  Map<String, dynamic> toJson() => _\$${jsonModel.name}ToJson(this);')
      ..writeln()
      ..writeln('}');
    return sb.toString();
  }
}
