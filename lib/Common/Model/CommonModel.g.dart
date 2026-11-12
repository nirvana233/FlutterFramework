// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CommonModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommonModel _$CommonModelFromJson(Map<String, dynamic> json) => CommonModel(
  code: (json['code'] as num?)?.toInt(),
  result: json['result'],
  msg: json['msg'] as String?,
  sysAt: (json['sysAt'] as num?)?.toInt(),
  cost: (json['cost'] as num?)?.toInt(),
  traceId: json['traceId'] as String?,
);

Map<String, dynamic> _$CommonModelToJson(CommonModel instance) => <String, dynamic>{
  'code': instance.code,
  'result': instance.result,
  'msg': instance.msg,
  'sysAt': instance.sysAt,
  'cost': instance.cost,
  'traceId': instance.traceId,
};
