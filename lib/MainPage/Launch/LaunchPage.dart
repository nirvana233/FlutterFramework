import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Base/BaseFulWidget.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/Common/Debug/TestMgr.dart';
import 'package:flutter_framework/Common/Manager/AppMgr.dart';
import 'package:flutter_framework/MainPage/Launch/LaunchViewModel.dart';
import 'package:flutter_framework/Util/Common/ApiConfig.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Util/Const.dart';
import 'package:flutter_framework/Util/NetWorkManager/NetWorkManagerUtil.dart';
import 'package:get/get.dart';

/// 启动闪屏页：初始化网络 → 拉取动态域名 → 设备分级 → 进入主页
class LaunchPage extends BaseFulWidget {
  LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void initState() {
    super.initState();
    hideSystemStatusBar();
    _init();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        TestMgr.instance.showTestBtn(context);
      }
    });
  }

  Future<void> _init() async {
    try {
      // 立即用 baseUrl 初始化 Dio，不等待 getDomain
      await NetWorkManagerUtil.instance.initDio(baseUrl);

      // 后台获取服务器域名，成功后更新 baseUrl
      AppMgr.instance.getDomain().then((domain) {
        if (isAvailable(domain)) {
          NetWorkManagerUtil.instance.updateBaseUrl(domain);
        }
      });

      // 最少等待1秒（保证 splash 展示时间）
      const minWaitMs = 1000;
      await Future.delayed(const Duration(milliseconds: minWaitMs));
      await _checkDevice();
      // DeepLink 等可能已在异步初始化期间替换 LaunchPage，失效页面不能再次跳转。
      if (!_canFinishLaunchNavigation) {
        return;
      }
      await LaunchViewModel.instance.launchEnd();
    } catch (e) {
      logE('LaunchPage._init failed: $e');
      await _fallbackAfterInitFailed();
    }
  }

  Future<void> _fallbackAfterInitFailed() async {
    // 正常导航完成后，即使旧初始化报错也不能重新接管路由。
    if (!_canFinishLaunchNavigation) {
      return;
    }
    try {
      await LaunchViewModel.instance.launchEnd();
    } catch (e) {
      logE('LaunchPage fallback launchEnd failed: $e');
    }
  }

  bool get _canFinishLaunchNavigation => mounted && (ModalRoute.of(context)?.isCurrent ?? false);

  /// 按设备分级配置图片内存缓存上限
  Future<void> _checkDevice() async {
    bool isLowDevice = await DeviceUtil.instance.isLowDevice();
    if (GetPlatform.isIOS) {
      isLowDevice = false;
    }
    if (isLowDevice) {
      PaintingBinding.instance.imageCache.maximumSize = 500;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;
    } else {
      PaintingBinding.instance.imageCache.maximumSize = 250;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    DeviceUtil.instance.setContext(context);
  }

  // ===== 闪屏 UI：新项目替换为品牌闪屏图（与原生 LaunchScreen 保持一致） =====
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: getAppFigmaColors.colorBgElementB100,
      child: Center(
        child: Text(
          appName,
          style: TextStyle(
            color: getAppFigmaColors.colorTextPrimaryB20,
            fontSize: FigmaVariables.fontSize24,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
