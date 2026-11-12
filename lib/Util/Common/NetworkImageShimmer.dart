import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';

/// 为应用内网络图片加载占位共享同一个动画时钟。
/// 放在 App 根部后，所有 [NetworkImageLoadingShimmer] 只复用一个 ticker。
class NetworkImageShimmerScope extends StatefulWidget {
  final Widget child;

  const NetworkImageShimmerScope({
    super.key,
    required this.child,
  });

  @override
  State<NetworkImageShimmerScope> createState() => _NetworkImageShimmerScopeState();
}

class _NetworkImageShimmerScopeState extends State<NetworkImageShimmerScope>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 1400);

  late final AnimationController _animationController;
  late final _NetworkImageShimmerClock _clock;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _clock = _NetworkImageShimmerClock(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NetworkImageShimmerProvider(
      clock: _clock,
      child: widget.child,
    );
  }
}

class _NetworkImageShimmerClock {
  final AnimationController animation;
  int _activeLoaders = 0;

  _NetworkImageShimmerClock(this.animation);

  void acquire() {
    _activeLoaders += 1;
    if (_activeLoaders == 1) {
      animation.value = 0;
      animation.repeat();
    }
  }

  void release() {
    if (_activeLoaders == 0) return;
    _activeLoaders -= 1;
    if (_activeLoaders == 0) {
      animation.stop();
      animation.value = 0;
    }
  }
}

class _NetworkImageShimmerProvider extends InheritedWidget {
  final _NetworkImageShimmerClock clock;

  const _NetworkImageShimmerProvider({
    required this.clock,
    required super.child,
  });

  static _NetworkImageShimmerClock? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_NetworkImageShimmerProvider>()?.clock;
  }

  @override
  bool updateShouldNotify(_NetworkImageShimmerProvider oldWidget) {
    return clock != oldWidget.clock;
  }
}

/// 在网络图片真正等待一小段时间后，为原占位内容叠加扫光效果。
/// 动画值来自 [NetworkImageShimmerScope]，滚动和非活跃路由期间自动停用。
class NetworkImageLoadingShimmer extends StatefulWidget {
  final Widget child;

  const NetworkImageLoadingShimmer({
    super.key,
    required this.child,
  });

  @override
  State<NetworkImageLoadingShimmer> createState() => _NetworkImageLoadingShimmerState();
}

class _NetworkImageLoadingShimmerState extends State<NetworkImageLoadingShimmer> {
  static const Duration _startDelay = Duration(milliseconds: 120);

  Timer? _startTimer;
  _NetworkImageShimmerClock? _clock;
  ScrollPosition? _scrollPosition;
  bool _delayElapsed = false;
  bool _tickerModeEnabled = true;
  bool _isScrolling = false;
  bool _isRegistered = false;
  bool _registrationSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(_startDelay, _handleStartDelayElapsed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final nextClock = _NetworkImageShimmerProvider.maybeOf(context);
    if (_clock != nextClock) {
      _releaseClock();
      _clock = nextClock;
    }

    _tickerModeEnabled = TickerMode.of(context);
    _attachScrollPosition(Scrollable.maybeOf(context)?.position);
    _syncRegistration();
  }

  void _handleStartDelayElapsed() {
    if (!mounted) return;
    _delayElapsed = true;
    final wasRegistered = _isRegistered;
    _syncRegistration();
    if (wasRegistered != _isRegistered) {
      setState(() {});
    }
  }

  void _attachScrollPosition(ScrollPosition? position) {
    if (_scrollPosition == position) return;
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScrollingChanged);
    _scrollPosition = position;
    _isScrolling = position?.isScrollingNotifier.value ?? false;
    _scrollPosition?.isScrollingNotifier.addListener(_handleScrollingChanged);
  }

  void _handleScrollingChanged() {
    final isScrolling = _scrollPosition?.isScrollingNotifier.value ?? false;
    if (_isScrolling == isScrolling) return;

    _isScrolling = isScrolling;
    // isScrollingNotifier 会在 viewport layout 中更新（如 ballistic → idle）。
    // 监听里不能碰 widget 树或 RenderObject，全部延后到帧结束。
    _scheduleRegistrationSync();
  }

  void _scheduleRegistrationSync() {
    if (_registrationSyncScheduled) return;
    _registrationSyncScheduled = true;
    // addPostFrameCallback 不会自行请求新帧，滚动直接 idle 时需显式调度。
    SchedulerBinding.instance.scheduleFrame();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _registrationSyncScheduled = false;
      if (!mounted) return;

      final wasRegistered = _isRegistered;
      _syncRegistration();
      if (wasRegistered != _isRegistered) {
        setState(() {});
      }
    });
  }

  void _syncRegistration() {
    final shouldRegister = _delayElapsed && _tickerModeEnabled && !_isScrolling && _clock != null;
    if (_isRegistered == shouldRegister) return;

    if (shouldRegister) {
      _clock!.acquire();
      _isRegistered = true;
      return;
    }
    _releaseClock();
  }

  void _releaseClock() {
    if (!_isRegistered) return;
    _clock?.release();
    _isRegistered = false;
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScrollingChanged);
    _releaseClock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ===== 静态占位 =====
    final clock = _clock;
    if (!_isRegistered || clock == null) {
      return widget.child;
    }

    // ===== 加载扫光 =====
    final highlightColor = getAppFigmaColors.colorBgElementB100Light;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          // ===== 原占位内容 =====
          widget.child,
          // ===== 扫光覆盖层 =====
          CustomPaint(
            painter: _NetworkImageShimmerPainter(
              animation: clock.animation,
              highlightColor: highlightColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkImageShimmerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color highlightColor;

  _NetworkImageShimmerPainter({
    required this.animation,
    required this.highlightColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final progress = Curves.easeInOutSine.transform(animation.value);
    final bandWidth = size.width * 1.1;
    final travelDistance = size.width + bandWidth;
    final left = -bandWidth + travelDistance * progress;
    final shaderBounds = Rect.fromLTWH(left, 0, bandWidth, size.height);
    final transparentColor = highlightColor.withValues(alpha: 0);
    final softHighlightColor = highlightColor.withValues(alpha: 0.35);
    final shader = LinearGradient(
      begin: const Alignment(-1, -0.32),
      end: const Alignment(1, 0.32),
      colors: [
        transparentColor,
        softHighlightColor,
        highlightColor,
        softHighlightColor,
        transparentColor,
      ],
      stops: const [0, 0.25, 0.5, 0.75, 1],
      tileMode: TileMode.clamp,
    ).createShader(shaderBounds);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_NetworkImageShimmerPainter oldDelegate) {
    return animation != oldDelegate.animation || highlightColor != oldDelegate.highlightColor;
  }
}
