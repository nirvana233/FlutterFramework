import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Toast.dart';
import 'package:json_annotation/json_annotation.dart';

part 'CommonModel.g.dart';

@JsonSerializable()
class CommonModel {
  int? code;
  dynamic result;
  String? msg;
  int? sysAt;
  int? cost;
  String? traceId;

  bool get isSuccess => code == 200;

  String get displayMsg {
    if (!isAvailable(code) && !isAvailable(msg)) {
      return '';
    }
    return "${msg ?? ''} [${code?.toString() ?? ''}]";
  }

  void showErrorToast() {
    if (!isAvailable(displayMsg)) {
      return;
    }
    showToast(displayMsg);
  }

  CommonModel({
    this.code,
    this.result,
    this.msg,
    this.sysAt,
    this.cost,
    this.traceId,
  });

  factory CommonModel.fromJson(Map<String, dynamic> json) => _$CommonModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommonModelToJson(this);
}
