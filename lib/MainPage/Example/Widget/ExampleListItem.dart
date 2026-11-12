import 'package:flutter/material.dart';
import 'package:flutter_framework/Common/Config/FigmaVariables.dart';
import 'package:flutter_framework/MainPage/Example/Model/ExampleModel.dart';
import 'package:flutter_framework/Util/Common/NetworkImageUtil.dart';

/// 示例列表项：封面 + 标题 + 描述
class ExampleListItem extends StatelessWidget {
  final ExampleItem item;
  final VoidCallback? onTap;

  const ExampleListItem({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = getAppFigmaColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: FigmaVariables.padding12,
        decoration: BoxDecoration(
          color: colors.colorBgElementB100,
          borderRadius: FigmaVariables.borderRadius12,
        ),
        child: Row(
          children: [
            // ===== 封面 =====
            ClipRRect(
              borderRadius: FigmaVariables.borderRadius8,
              child: NetworkImageUtil(
                imageUrl: item.cover,
                width: FigmaVariables.spacing60,
                height: FigmaVariables.spacing60 * 4 / 3,
                fit: BoxFit.cover,
                // Mock 图片服务不支持 ?w=&h= 裁剪参数
                isNeedRedirect: false,
              ),
            ),
            const SizedBox(width: FigmaVariables.spacing12),
            // ===== 标题 + 描述 =====
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.colorTextPrimaryB20,
                      fontSize: FigmaVariables.fontSize16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: FigmaVariables.spacing6),
                  Text(
                    item.desc ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.colorTextRegularB50,
                      fontSize: FigmaVariables.fontSize14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
