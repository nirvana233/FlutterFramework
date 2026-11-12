---
name: network-image
description: 当用户需要显示网络图片、加载远程图片、显示封面图、显示头像、显示 Banner 时自动触发。关键词：网络图片、NetworkImageUtil、CachedNetworkImage、封面、头像、Banner、图片加载、imageUrl。
version: 1.0.0
---

# 网络图片加载规范

本项目使用 `NetworkImageUtil` 统一加载网络图片，禁止直接使用 `CachedNetworkImage` 或 `Image.network`。

## 核心文件

`lib/Util/Common/NetworkImageUtil.dart`

## 基本用法

```dart
import 'package:flutter_framework/Util/Common/NetworkImageUtil.dart';

NetworkImageUtil(
  imageUrl: url,         // 图片 URL（必填，可为 null）
  width: 100,            // 宽度（可选，null 则填满父容器）
  height: 150,           // 高度（可选，null 则填满父容器）
)
```

---

## imageType 裁剪尺寸（重要）

`imageType` 控制图片裁剪参数（拼接 `?w=&h=`，见 `Tools.getRedirectImageUrl`）与内存解码尺寸，必须根据实际用途选择，默认为 `cover`：

| 类型 | 尺寸 | 用途 |
|------|------|------|
| `NetworkImageSizeEnum.cover` | 540×720 | 封面图（默认） |
| `NetworkImageSizeEnum.avatar` | 148×148 | 头像（大） |
| `NetworkImageSizeEnum.userHead` | 68×68 | 用户头像（小） |
| `NetworkImageSizeEnum.banner` | 750×276 | 横幅 |
| `NetworkImageSizeEnum.illustration` | 750×1500 | 大图 / 立绘 |
| `NetworkImageSizeEnum.none` | 不裁剪 | 原图尺寸 |

> 图片服务**不支持** `?w=&h=` 裁剪参数时，传 `isNeedRedirect: false`（如 `ExampleListItem` 使用的 Mock 图片）。
> 新增业务尺寸：在 `NetworkImageSizeEnum` 追加枚举并在 `getImageSize` 登记。

```dart
// 封面图（默认，可以不写 imageType）
NetworkImageUtil(
  imageUrl: item.cover,
  width: 80,
  height: 107,
  imageType: NetworkImageSizeEnum.cover,
)

// 头像
NetworkImageUtil(
  imageUrl: profile.avatarUrl,
  width: 44,
  height: 44,
  imageType: NetworkImageSizeEnum.avatar,
)

// 用户头像（圆形裁剪）
NetworkImageUtil(
  imageUrl: user.avatarUrl,
  width: 44,
  height: 44,
  imageType: NetworkImageSizeEnum.userHead,
  isCircle: true,
)
```

---

## 完整参数列表

```dart
NetworkImageUtil(
  imageUrl: url,                               // 图片 URL（必填）
  width: 100,                                  // 宽度
  height: 150,                                 // 高度
  imageType: NetworkImageSizeEnum.cover,       // 图片尺寸类型（默认 cover）
  fit: BoxFit.cover,                           // 图片适应方式（默认 BoxFit.fill）
  isCircle: false,                             // 是否圆形裁剪（默认 false）
  showPlaceholder: true,                       // 是否显示占位图（默认 true）
  showError: true,                             // 是否显示错误图（默认 true）
  isNeedRedirect: true,                        // 是否拼接裁剪参数（默认 true）
  placeholderColor: Colors.grey[200],          // 占位图颜色（可选）
  errorImage: 'assets/images/xxx.png',         // 自定义错误图路径（可选）
  maxRetryAttempts: 3,                         // 最大重试次数（默认 3）
)
```

---

## 常见场景示例

### 列表卡片封面

```dart
NetworkImageUtil(
  imageUrl: item.cover,
  width: 80,
  height: 107,
  fit: BoxFit.cover,
)
```

### 圆形头像

```dart
NetworkImageUtil(
  imageUrl: profile.avatar,
  width: 32,
  height: 32,
  imageType: NetworkImageSizeEnum.avatar,
  isCircle: true,
)
```

### 全宽 Banner 图（不裁剪）

```dart
NetworkImageUtil(
  imageUrl: banner.imageUrl,
  width: double.infinity,
  height: 160,
  imageType: NetworkImageSizeEnum.banner,
  fit: BoxFit.cover,
  showPlaceholder: false,
)
```

### 本地资源图片路径（兼容）

`imageUrl` 传入以 `assets/` 开头的路径时，会自动走 `Image.asset` 加载本地图片。

---

## 注意事项

- `imageUrl` 可以为 `null`，组件会自动显示占位图
- `width` 和 `height` 若不传，则图片填满父容器（需要父容器有确定尺寸）
- 圆形头像使用 `isCircle: true`，无需额外套 `ClipOval`
- 所有网络图片均自动缓存，无需手动处理缓存逻辑
- 清除缓存：`NetworkImageUtil.clearCache()`（设置页「清除缓存」已调用）
- **禁止**直接使用 `CachedNetworkImage`、`Image.network`
- 参考：`lib/MainPage/Example/Widget/ExampleListItem.dart`
