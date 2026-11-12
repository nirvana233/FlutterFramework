import 'package:flutter/widgets.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';
import 'package:flutter_framework/Util/Common/NetworkImageUtil.dart';

/// 内存压力管理器
/// 监听系统内存压力事件，在内存不足时主动清理缓存
/// 主要用于解决华为等内存管理激进的设备上的 OOM 问题
class MemoryPressureMgr extends WidgetsBindingObserver {
  // 单例实例
  static final MemoryPressureMgr _instance = MemoryPressureMgr._internal();
  static MemoryPressureMgr get instance => _instance;

  MemoryPressureMgr._internal();

  bool _isInitialized = false;

  /// 初始化内存压力监听
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);
    // logD('MemoryPressureMgr: 内存压力监听已启动');
  }

  /// 释放资源
  void dispose() {
    if (!_isInitialized) return;
    _isInitialized = false;

    WidgetsBinding.instance.removeObserver(this);
    logD('MemoryPressureMgr: 内存压力监听已停止');
  }

  /// 系统内存压力回调
  /// 当系统内存紧张时，Flutter 会调用此方法
  @override
  void didHaveMemoryPressure() {
    // _cleanupMemory();
  }

  /// 清理内存
  /// 可以在任何需要释放内存的时候调用
  Future<void> _cleanupMemory() async {
    try {
      // 1. 清理 Flutter 图片内存缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      logD('MemoryPressureMgr: Flutter 图片内存缓存已清理');

      // 2. 清理网络图片磁盘缓存（异步执行，不阻塞主线程）
      await NetworkImageUtil.clearCache();

      logD('MemoryPressureMgr: 内存清理完成');
    } catch (e) {
      logE('MemoryPressureMgr: memory cleanup failed $e');
    }
  }

  /// 手动触发内存清理（供外部调用）
  Future<void> manualCleanup() async {
    logD('MemoryPressureMgr: 手动触发内存清理');
    await _cleanupMemory();
  }

  /// 设置图片缓存限制
  /// 建议在应用启动时调用，限制内存中缓存的图片数量和大小
  static void configureImageCache({
    int maximumSize = 100, // 最多缓存 100 张图片
    int maximumSizeBytes = 100 * 1024 * 1024, // 最多 100MB
  }) {
    PaintingBinding.instance.imageCache.maximumSize = maximumSize;
    PaintingBinding.instance.imageCache.maximumSizeBytes = maximumSizeBytes;
    logD(
      'MemoryPressureMgr: 图片缓存限制已配置 - 数量: $maximumSize, 大小: ${maximumSizeBytes ~/ (1024 * 1024)}MB',
    );
  }
}
