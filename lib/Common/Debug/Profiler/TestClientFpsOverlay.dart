import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';

/// 测试包帧率浮层：右上角显示近期平均 FPS，不拦截点击。
class TestClientFpsOverlay extends StatefulWidget {
  const TestClientFpsOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<TestClientFpsOverlay> createState() => _TestClientFpsOverlayState();
}

class _TestClientFpsOverlayState extends State<TestClientFpsOverlay> {
  int _fps = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;

    var totalMicros = 0;
    for (final timing in timings) {
      totalMicros += timing.totalSpan.inMicroseconds;
    }
    final avgMicros = totalMicros / timings.length;
    if (avgMicros <= 0) return;

    final fps = (1000000 / avgMicros).round().clamp(0, 999);
    if (fps != _fps) {
      setState(() => _fps = fps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: top + FigmaVariables.spacing8,
          right: FigmaVariables.spacing8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                // TODO: Debug 浮层半透明底，Figma 无对应 token
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(FigmaVariables.radius6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FigmaVariables.spacing8,
                  vertical: FigmaVariables.spacing4,
                ),
                child: Text(
                  'FPS $_fps',
                  style: const TextStyle(
                    // TODO: Debug 浮层前景色，Figma 无对应 token
                    color: Colors.white,
                    fontSize: FigmaVariables.fontSize12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
