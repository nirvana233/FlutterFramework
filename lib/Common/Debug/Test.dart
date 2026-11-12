// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';

/// 调试沙盒：悬浮 Test 按钮的点击入口，临时验证代码写在 [test] 里，用完清空即可
class Test {
  static int index = 0;

  static void test(BuildContext context) async {
    logD('Test.test index: ${index++}');
  }
}
