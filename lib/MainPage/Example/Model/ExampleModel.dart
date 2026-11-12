import 'package:json_annotation/json_annotation.dart';

part 'ExampleModel.g.dart';

/// 示例列表接口响应（外层包装字段固定：code / result / msg / sysAt / cost / traceId）
@JsonSerializable()
class ExampleModel {
  int? code;
  ExampleResult? result;
  String? msg;
  int? sysAt;
  int? cost;
  String? traceId;

  ExampleModel({this.code, this.result, this.msg, this.sysAt, this.cost, this.traceId});

  factory ExampleModel.fromJson(Map<String, dynamic> json) => _$ExampleModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExampleModelToJson(this);
}

/// 分页数据
@JsonSerializable()
class ExampleResult {
  int? total;
  List<ExampleItem>? list;

  ExampleResult({this.total, this.list});

  factory ExampleResult.fromJson(Map<String, dynamic> json) => _$ExampleResultFromJson(json);
  Map<String, dynamic> toJson() => _$ExampleResultToJson(this);
}

/// 列表子项
@JsonSerializable()
class ExampleItem {
  int? id;
  String? title;
  String? desc;
  String? cover;

  ExampleItem({this.id, this.title, this.desc, this.cover});

  factory ExampleItem.fromJson(Map<String, dynamic> json) => _$ExampleItemFromJson(json);
  Map<String, dynamic> toJson() => _$ExampleItemToJson(this);
}
