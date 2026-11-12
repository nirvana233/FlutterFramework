import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Extension/ColorUtil.dart';
import 'package:get/get.dart';

/// 通知权限弹窗
/// 提供友好的通知权限请求界面，包含价值说明和平台适配
class PermissionDialog extends StatefulWidget {
  /// 确认回调 - 参数为是否成功获取权限
  final Function()? onConfirm;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 自定义标题
  final String? title;

  /// 自定义描述文本
  final String? description;

  /// 自定义确认按钮文本
  final String? confirmText;

  /// 自定义取消按钮文本
  final String? cancelText;

  const PermissionDialog({
    super.key,
    this.onConfirm,
    this.onCancel,
    this.title,
    this.description,
    this.confirmText,
    this.cancelText,
  });

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  // final bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ColorsUtil.appThemeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 32,
              color: ColorsUtil.appThemeColor,
            ),
          ),

          const SizedBox(height: 20),

          // 标题
          Text(
            widget.title ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F1F2F),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // 描述
          Text(
            widget.description ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7E839D),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // 按钮组
          Column(
            children: [
              // 确认按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsUtil.appThemeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.confirmText ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 取消按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _handleCancel,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFF7E839D),
                    side: const BorderSide(
                      color: Color(0xFFE5E5EA),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.cancelText ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7E839D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理取消按钮点击
  void _handleCancel() {
    widget.onCancel?.call();
    Get.back();
  }

  /// 关闭弹窗并执行回调
  void _handleConfirm() {
    widget.onConfirm?.call();
    Get.back();
  }
}
