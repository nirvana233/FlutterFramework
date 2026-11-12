import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadErrorView extends StatelessWidget {
  final String imagePath;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryText;
  final double? imageWidth;
  final double? imageHeight;
  final double? messageFontSize;
  final Color? messageColor;
  final Color? imageColor;
  final Color? iconColor;

  const LoadErrorView({
    super.key,
    this.imagePath = 'assets/images/common/home_icon_Default.png',
    this.message,
    this.onRetry,
    this.retryText,
    this.imageWidth,
    this.imageHeight,
    this.messageFontSize,
    this.messageColor,
    this.imageColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            color: imageColor,
            imagePath,
            width: imageWidth ?? 150,
            height: imageHeight ?? 150,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? 'nothing_show'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: messageFontSize ?? 14,
              color: messageColor ?? Colors.black54,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            IconButton(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh_rounded,
                color: iconColor ?? const Color.fromARGB(255, 204, 204, 204),
                size: 32,
              ),
            ),
            // ButtonBigRed(
            //   content: retryText ?? 'retry'.tr,
            //   width: 100,
            //   height: 40,
            //   fontSize: 14,
            //   onTap: () {
            //     onRetry?.call();
            //   },
            // ),
          ],
        ],
      ),
    );
  }
}
