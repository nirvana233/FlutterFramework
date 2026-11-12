import 'package:flutter_framework/Util/Common/DeviceUtil.dart';

/// 宽屏设备（平板）尺寸放大：`16.sc`
extension IntScaleExtension on int {
  double get sc {
    if (isWideDevice) {
      return (this * 1.5);
    } else {
      return (this * 1.0);
    }
  }
}

extension DoubleScaleExtension on double {
  double get sc {
    if (isWideDevice) {
      return this * 1.5;
    } else {
      return this * 1.0;
    }
  }
}

extension StringExtension on String {
  /// 将字符串的首字母转换为小写
  String get firstLetterLowerCase {
    if (isEmpty) return this;
    return this[0].toLowerCase() + substring(1);
  }
}
