import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Popup/PopupType.dart';
import 'package:flutter_framework/Util/Common/LogUtil.dart';

/// 弹窗队列项
class PopupQueueItem {
  final PopupType id;
  final Future<void> Function() showPopup; // 确保返回 Future<void>
  final int priority;
  final VoidCallback? onComplete;

  PopupQueueItem({
    required this.id,
    required this.showPopup,
    this.onComplete,
    required this.priority,
  });
}

/// 弹窗队列管理器
class PopupQueueMgr {
  static PopupQueueMgr? _instance;
  PopupQueueMgr._internal();
  static PopupQueueMgr get instance => _instance ??= PopupQueueMgr._internal();

  final _queue = <PopupQueueItem>[];
  bool _isProcessing = false;
  PopupQueueItem? _currentPopup;

  /// 添加弹窗到队列；[replacePending] 仅替换尚未开始展示的同 ID 条目。
  void addPopup({
    required PopupType id,
    required Future<void> Function() showPopup, // 确保返回 Future<void>
    VoidCallback? onComplete,
    bool replacePending = false,
  }) {
    // 检查是否已存在相同ID的弹窗
    final existingIndex = _queue.indexWhere((item) => item.id == id);
    if (existingIndex != -1 &&
        (!replacePending || identical(_queue[existingIndex], _currentPopup))) {
      // logD('PopupQueueMgr: 弹窗 $id 已存在于队列中，跳过添加');
      return;
    }

    final priority = id.priority;
    final item = PopupQueueItem(
      id: id,
      showPopup: showPopup,
      onComplete: onComplete,
      priority: priority,
    );

    if (existingIndex != -1) {
      _queue[existingIndex] = item;
      return;
    }

    _insertByPriority(item);

    // logD('PopupQueueMgr: 添加弹窗 $id (优先级: $priority)');
    // logD(_getQueueSummary());

    // 如果当前没有处理弹窗，开始处理
    if (!_isProcessing) {
      _processQueue();
    }
  }

  /// 按优先级插入弹窗
  void _insertByPriority(PopupQueueItem item) {
    int insertIndex = 0;
    for (int i = 0; i < _queue.length; i++) {
      if (item.priority < _queue[i].priority) {
        insertIndex = i;
        break;
      }
      insertIndex = i + 1;
    }
    _queue.insert(insertIndex, item);
  }

  /// 处理队列
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      // logD('PopupQueueMgr: _processQueue - 队列为空或正在处理中，跳过');
      return;
    }

    _isProcessing = true;
    // logD('PopupQueueMgr: 开始处理队列, 当前队列长度: ${_queue.length}');
    printQueueSummary();

    while (_queue.isNotEmpty) {
      final item = _queue.first;
      _currentPopup = item;
      // logD('PopupQueueMgr: 正在处理弹窗: ${item.id} (优先级: ${item.priority})');

      try {
        // 执行显示弹窗的函数，并等待它完成
        await item.showPopup();
        // logD('PopupQueueMgr: 弹窗 ${item.id} 已关闭');
      } catch (e, s) {
        logE('PopupQueueMgr: Show popup ${item.id} error: $e\n$s');
        // 即使出错也继续处理下一个
      }
      _currentPopup = null;

      // 展示期间新入队的高优先级项可能排到前面，按实例移除本次已处理项。
      _queue.remove(item);

      // logD('PopupQueueMgr: 弹窗 ${item.id} 已从队列移除, 剩余: ${_queue.length}');
      printQueueSummary();

      // 执行完成回调
      item.onComplete?.call();
    }

    _isProcessing = false;
    // logD('PopupQueueMgr: 队列处理完成');
  }

  /// 打印当前队列的摘要信息
  void printQueueSummary() {
    if (_queue.isEmpty) {
      // logD('PopupQueueMgr: 队列为空');
      return;
    }
    final summary = _queue
        .map((item) {
          final description = item.id.name;
          return '${item.id}(${item.priority}-$description)';
        })
        .join(' -> ');
    // logD('PopupQueueMgr: 当前队列: $summary');
  }

  /// 手动标记当前弹窗已关闭
  void markCurrentPopupClosed() {
    // This method is no longer needed as we are waiting for the Future directly.
    // Keeping it for now, but it will not be called by the new _processQueue.
    // logD('PopupQueueMgr: markCurrentPopupClosed - This method is no longer needed.');
  }

  /// 清空队列
  void clearQueue() {
    _queue.clear();
    _isProcessing = false;
    // logD('PopupQueueMgr: 队列已清空');
  }

  /// 获取队列摘要信息
  String _getQueueSummary() {
    if (_queue.isEmpty) return '队列为空';

    final summary = _queue
        .map((item) {
          final description = item.id.name;
          return '${item.id}(${item.priority}-$description)';
        })
        .join(' -> ');

    return '队列: $summary';
  }

  // 调试用的getter
  bool get isProcessing => _isProcessing;
  int get queueLength => _queue.length;
  List<PopupType> get queueIds => _queue.map((item) => item.id).toList();

  void dispose() {
    // _checkTimer is removed, so nothing to do here for now.
  }
}
