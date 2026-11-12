import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Manager/VibrationMgr.dart';
import 'package:flutter_framework/Util/Common/DeviceUtil.dart';

class BackTopFloatingButton extends StatelessWidget {
  final bool show;
  final VoidCallback? onPressed;
  final ScrollController? scrollController;
  const BackTopFloatingButton({
    super.key,
    required this.show,
    this.onPressed,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !show,
        child: FloatingActionButton(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 1),
          mini: isWideDevice ? false : true,
          elevation: 0,
          shape: CircleBorder(
            side: BorderSide(
              color: const Color.fromARGB(255, 229, 229, 229).withValues(alpha: 1),
              width: isWideDevice ? 2 : 1.0,
            ),
          ),
          onPressed: () {
            scrollController?.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
            );
            onPressed?.call();
            VibrationMgr.instance.selection();
          },
          child: const Icon(
            Icons.arrow_upward,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
