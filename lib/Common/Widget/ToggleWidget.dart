//todo: 协议&弹窗
import 'package:flutter/material.dart';

import '../../../Util/Common/Tools.dart';

class ToggleWidget extends StatefulWidget {
  final bool isAgree;
  final Function(bool isAgree)? onIsAgreeChangedCallback;

  const ToggleWidget({super.key, this.isAgree = true, this.onIsAgreeChangedCallback});

  @override
  State<ToggleWidget> createState() => ToggleWidgetState();
}

class ToggleWidgetState extends State<ToggleWidget> {
  late bool isAgreeAgreement;

  @override
  void initState() {
    super.initState();

    isAgreeAgreement = widget.isAgree;
  }

  setIsAgreeUserAgreement(bool? value) {
    if (mounted) {
      setState(() {
        isAgreeAgreement = value ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() {
            isAgreeAgreement = !isAgreeAgreement; // 切换状态
          });

          if (isAvailable(widget.onIsAgreeChangedCallback)) {
            widget.onIsAgreeChangedCallback!(isAgreeAgreement); // 通知父组件状态改变
          }
        }
      },
      child: Container(
        width: 15,
        height: 15,
        color: Colors.transparent,
        child: Image.asset(
          isAgreeAgreement
              ? "assets/images/common/icon_toggle_check.png"
              : "assets/images/common/icon_toggle_uncheck.png",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
