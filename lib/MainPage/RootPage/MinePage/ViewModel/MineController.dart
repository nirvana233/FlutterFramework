import 'package:flutter_framework/Common/Manager/AppThemeMgr.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';
import 'package:flutter_framework/Util/Common/NetworkImageUtil.dart';
import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:flutter_framework/Util/NetWorkManager/NetWorkManagerUtil.dart';
import 'package:flutter_framework/Util/SheetAndAlter/Toast.dart';
import 'package:get/get.dart';

/// 我的 / 设置页状态
class MineController extends GetxController {
  /// 版本号文案（含 build 号，测试服带 test 标记）
  final RxString version = ''.obs;

  /// 震动开关
  final RxBool isVibrationEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    isVibrationEnabled.value = PreferenceUtil.instance.getEnableVibration() == 1;
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    version.value = await DeviceUtil.getVersion();
  }

  void setDarkMode(bool value) {
    AppThemeMgr.instance.setDarkMode(value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    isVibrationEnabled.value = value;
    await PreferenceUtil.instance.setEnableVibration(value ? 1 : 0);
    if (value) VibrationMgr.instance.selection();
  }

  /// 清除图片缓存（内存 + 磁盘）
  Future<void> clearCache() async {
    await NetworkImageUtil.clearCache();
    await NetWorkManagerUtil.instance.clearImageCache();
    showToast('clear_cache_success'.tr);
  }
}
