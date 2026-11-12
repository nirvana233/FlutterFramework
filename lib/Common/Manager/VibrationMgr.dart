import 'package:flutter_framework/Util/Common/PreferenceUtil.dart';
import 'package:gaimon/gaimon.dart';
import 'package:get/get_utils/src/platform/platform.dart';

//备注：Android源码有问题，改了的
class VibrationMgr {
  static VibrationMgr? _instance;
  VibrationMgr._();
  static VibrationMgr get instance => _instance ??= VibrationMgr._();

  bool canSupportsHaptic = false;
  bool hasAmplitudeControl = true;
  Future<void> init() async {
    canSupportsHaptic = await Gaimon.canSupportsHaptic;
    if (canSupportsHaptic) {
      if (GetPlatform.isAndroid) {
        hasAmplitudeControl = await Gaimon.hasAmplitudeControl;
      }
    } else {
      hasAmplitudeControl = false;
    }
  }

  bool get isSupported => canSupportsHaptic && PreferenceUtil.instance.getEnableVibration() == 1;

  void selection() {
    // logP("isSupported: $isSupported");
    // logP("canSupportsHaptic: $canSupportsHaptic");
    // logP("hasAmplitudeControl: $hasAmplitudeControl");
    // logP("PreferenceUtil.instance.getEnableVibration(): ${PreferenceUtil.instance.getEnableVibration()}");
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.selection();
    } else {
      Gaimon.patternFromWaveForm([0, 30], [], false);
    }
  }

  void error() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.error();
    } else {
      Gaimon.patternFromWaveForm([0, 100, 50, 100, 50, 100], [], false);
    }
  }

  void success() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.success();
    } else {
      Gaimon.patternFromWaveForm([0, 150, 80, 50], [], false);
    }
  }

  void warning() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.warning();
    } else {
      Gaimon.patternFromWaveForm([0, 120, 200, 120], [], false);
    }
  }

  void heavy() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.heavy();
    } else {
      Gaimon.patternFromWaveForm([0, 60, 30, 60, 30, 60], [], false);
    }
  }

  void medium() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.medium();
    } else {
      Gaimon.patternFromWaveForm([0, 40, 60, 40], [], false);
    }
  }

  void light() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.light();
    } else {
      Gaimon.patternFromWaveForm([0, 20, 40, 20], [], false);
    }
  }

  void rigid() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.rigid();
    } else {
      Gaimon.patternFromWaveForm([0, 200], [], false);
    }
  }

  void soft() {
    if (!isSupported) {
      return;
    }
    if (hasAmplitudeControl) {
      Gaimon.soft();
    } else {
      Gaimon.patternFromWaveForm([0, 75], [], false);
    }
  }

  void phoneCall() {
    if (!isSupported) {
      return;
    }
    if (GetPlatform.isAndroid) {
      if (hasAmplitudeControl) {
        Gaimon.patternFromWaveForm([0, 70, 90, 70], [0, 140, 0, 140], false);
      } else {
        Gaimon.patternFromWaveForm([0, 70, 90, 70], [], false);
      }
      return;
    }
    medium();
  }

  void patternFromData(String pattern) {
    if (!isSupported) {
      return;
    }
    Gaimon.patternFromData(pattern);
  }

  void vibrate(VibrationType type, {String? pattern}) {
    if (!isSupported) {
      return;
    }
    switch (type) {
      case VibrationType.selection:
        selection();
      case VibrationType.error:
        error();
      case VibrationType.success:
        success();
      case VibrationType.warning:
        warning();
      case VibrationType.heavy:
        heavy();
      case VibrationType.medium:
        medium();
      case VibrationType.light:
        light();
      case VibrationType.rigid:
        rigid();
      case VibrationType.soft:
        soft();
      case VibrationType.phoneCall:
        phoneCall();
      case VibrationType.pattern:
        if (pattern == null) {
          return;
        }
        patternFromData(pattern);
    }
  }
}

enum VibrationType {
  selection,
  error,
  success,
  warning,
  heavy,
  medium,
  light,
  rigid,
  soft,
  phoneCall,
  pattern,
}

/*
private fun vibratePattern(pattern: Pattern, result: Result) {
    try {
        // 路径 1: 对于支持振幅控制的现代安卓设备 (API 26+)，这是最佳体验
        // 这一部分保持不变
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && vibrator.hasAmplitudeControl()) {
            val effect = VibrationEffect.createWaveform(pattern.lengths, pattern.amplitudes, -1)
            vibrator.vibrate(effect)
        }
        // 路径 2: 对于不支持振幅控制的设备，分情况处理【这是修改的核心区域】
        else {
            // 对于现代安卓版本 (API 26+) 但不支持振幅控制的设备
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // 如果是单一时长的模式 (如 light, heavy, selection 等)
                if (pattern.lengths.size == 1) {
                    // 使用 createOneShot 创建单次震动，并使用默认强度
                    // 这会正确地执行一次指定时长的震动
                    val effect = VibrationEffect.createOneShot(pattern.lengths[0], VibrationEffect.DEFAULT_AMPLITUDE)
                    vibrator.vibrate(effect)
                }
                // 如果是复杂模式 (如 success, warning, error)
                else {
                    // 使用只带时序的 createWaveform，它会按 [关, 开, 关, 开...] 的模式执行
                    val effect = VibrationEffect.createWaveform(pattern.lengths, -1)
                    vibrator.vibrate(effect)
                }
            }
            // 路径 3: 对于非常老旧的安卓版本 (< API 26)
            else {
                // 如果是单一时长的模式
                if (pattern.lengths.size == 1) {
                    // 使用已被废弃但在此处完全适用的单次震动方法
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(pattern.lengths[0])
                }
                // 如果是复杂模式
                else {
                    // 使用唯一可用的旧版模式震动方法
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(pattern.lengths, -1)
                }
            }
        }
        result.success(null)
    } catch (e: Exception) {
        result.error("VIBRATION_ERROR", "Failed to vibrate", e.localizedMessage)
    }
}
*/
