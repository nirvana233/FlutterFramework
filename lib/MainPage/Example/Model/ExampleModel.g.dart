// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ExampleModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExampleModel _$ExampleModelFromJson(Map<String, dynamic> json) => ExampleModel(
  code: (json['code'] as num?)?.toInt(),
  result: json['result'] == null
      ? null
      : ExampleResult.fromJson(json['result'] as Map<String, dynamic>),
  msg: json['msg'] as String?,
  sysAt: (json['sysAt'] as num?)?.toInt(),
  cost: (json['cost'] as num?)?.toInt(),
  traceId: json['traceId'] as String?,
);

Map<String, dynamic> _$ExampleModelToJson(ExampleModel instance) => <String, dynamic>{
  'code': instance.code,
  'result': instance.result,
  'msg': instance.msg,
  'sysAt': instance.sysAt,
  'cost': instance.cost,
  'traceId': instance.traceId,
};

ExampleResult _$ExampleResultFromJson(Map<String, dynamic> json) => ExampleResult(
  total: (json['total'] as num?)?.toInt(),
  list: (json['list'] as List<dynamic>?)
      ?.map((e) => ExampleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ExampleResultToJson(ExampleResult instance) => <String, dynamic>{
  'total': instance.total,
  'list': instance.list,
};

ExampleItem _$ExampleItemFromJson(Map<String, dynamic> json) => ExampleItem(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String?,
  desc: json['desc'] as String?,
  cover: json['cover'] as String?,
);

Map<String, dynamic> _$ExampleItemToJson(ExampleItem instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'desc': instance.desc,
  'cover': instance.cover,
};
