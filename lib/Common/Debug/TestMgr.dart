// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Debug/Test.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_framework/Common/Debug/GM/GMPage.dart';
import 'package:get/get.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TestMgr {
  static final TestMgr instance = TestMgr._internal();
  TestMgr._internal();

  OverlayEntry? _overlayEntry;
  double _dragX = 0; // 初始X位置，将在showTestBtn中设置为右上角
  double _dragY = 30; // 初始Y位置，将在showTestBtn中设置

  /// 单个调试按钮高度
  static const double _btnItemHeight = 28.0;

  /// 按钮之间间距
  static const double _btnGap = 10.0;

  /// 按钮宽度
  static const double _btnWidth = 50.0;

  void showTestBtn(BuildContext context) {
    if (!isTestClient) return;
    // 在页面初始化时添加悬浮按钮
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showTest(context);
    });
  }

  void showTest(BuildContext context) {
    if (_overlayEntry != null) return;
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // 当前展示的按钮列表（与下方 Column children 保持一致）
    final buttons = <({TestBtnType type, VoidCallback onPressed})>[
      (
        type: TestBtnType.Test,
        onPressed: () {
          logD("Test按钮被点击了！ logD");
          Test.test(context);
        },
      ),
      (
        type: TestBtnType.Log,
        onPressed: () {
          Get.to(() => TalkerScreen(talker: talker!, isLogsExpanded: false));
        },
      ),
      (
        type: TestBtnType.GM,
        onPressed: () {
          logD("GM按钮被点击了！");
          Get.to(() => const GMPage());
        },
      ),
    ];
    final buttonHeight = _stackHeight(buttons.length);

    // 右上角距右边 12，Y 避开导航栏
    _dragX = screenSize.width - _btnWidth - 12;
    _dragY = safeArea.top + kToolbarHeight;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: _dragY,
          left: _dragX,
          child: GestureDetector(
            onPanUpdate: (details) {
              _dragX += details.delta.dx;
              _dragY += details.delta.dy;

              final screenSize = MediaQuery.of(context).size;
              final safeArea = MediaQuery.of(context).padding;

              _dragX = _dragX.clamp(0, screenSize.width - _btnWidth);
              _dragY = _dragY.clamp(
                safeArea.top,
                screenSize.height - safeArea.bottom - buttonHeight,
              );

              _overlayEntry?.markNeedsBuild();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(height: _btnGap, width: _btnWidth),
                    _buildTestBtn(buttons[i].type, buttons[i].onPressed),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 按按钮数量计算整列高度：n 个按钮 + (n-1) 个间距
  static double _stackHeight(int count) {
    if (count <= 0) return 0;
    return count * _btnItemHeight + (count - 1) * _btnGap;
  }

  void removeTestBtn() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  Widget _buildTestBtn(TestBtnType text, Function() onPressed) {
    return TextButton(
      style: TextButton.styleFrom(
        fixedSize: const Size(_btnWidth, _btnItemHeight),
        visualDensity: VisualDensity.compact,
        minimumSize: Size.zero,
        backgroundColor: const Color.fromARGB(180, 0, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onPressed: () async {
        VibrationMgr.instance.heavy();
        onPressed();
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text.name,
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 16,
            height: 0.8,
          ),
        ),
      ),
    );
  }
}

enum TestBtnType { Log, Test, GM }
