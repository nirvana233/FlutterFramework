// ignore_for_file: constant_identifier_names

/// 弹窗类型枚举（PopupQueueMgr 排队使用）
/// 枚举顺序决定优先级，越靠前优先级越高；新增业务弹窗按优先级插入
enum PopupType {
  VersionUpdateDialog, // 版本更新弹窗
  PermissionDialog, // 权限弹窗
  ConfirmBottomSheet, // 通用确认底部弹窗
}

/// 弹窗类型扩展方法
extension PopupTypeExtension on PopupType {
  /// 获取优先级数值（基于枚举索引）
  int get priority => index;
}
