import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Popup/ConfirmMgr.dart';
import 'package:flutter_framework/Common/Widget/Button/ButtonBigRed.dart';
import 'package:flutter_framework/Common/Widget/CommonAppbar.dart';
import 'package:flutter_framework/Common/Widget/SmartSafeArea.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Toast.dart';
import 'package:get/get.dart';

/// 示例详情页：演示命名路由传参（arguments）+ 通用确认弹窗 + Toast
class ExampleDetailPage extends StatefulWidget {
  const ExampleDetailPage({super.key, this.arguments});

  final dynamic arguments;

  @override
  State<ExampleDetailPage> createState() => _ExampleDetailPageState();
}

class _ExampleDetailPageState extends State<ExampleDetailPage> {
  Map<String, dynamic> arguments = {};

  int get _id => arguments['id'] as int? ?? 0;

  String? get _title => arguments['title'] as String?;

  @override
  void initState() {
    super.initState();
    if (widget.arguments is Map) {
      arguments = Map<String, dynamic>.from(widget.arguments as Map);
    }
  }

  /// 弹出确认弹窗，确认后 Toast 提示
  void _onConfirmTap() {
    ConfirmMgr.instance.showConfirmNew(
      title: 'example_confirm_title'.tr,
      message: 'example_confirm_message'.tr,
      confirmText: 'confirm'.tr,
      cancelText: 'cancel'.tr,
      isDestructive: false,
      onConfirm: () => showToast('example_confirm_done'.tr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colors = getAppFigmaColors;
      return Scaffold(
        backgroundColor: colors.colorBgElementB96,
        appBar: CommonAppbar(title: _title ?? 'example_detail_title'.tr),
        body: SmartSafeArea(
          top: false,
          child: Padding(
            padding: FigmaVariables.padding16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== 路由参数展示 =====
                Text(
                  'example_detail_id'.trParams({'param1': '$_id'}),
                  style: TextStyle(
                    color: colors.colorTextPrimaryB20,
                    fontSize: FigmaVariables.fontSize16,
                  ),
                ),
                const Spacer(),
                // ===== 操作按钮 =====
                ButtonBigRed(content: 'example_confirm_title'.tr, onTap: _onConfirmTap),
              ],
            ),
          ),
        ),
      );
    });
  }
}
