---
name: flutter-performance
description: >
  Flutter 动画与切换性能排查速查（实战提取）。
  仅手动调用：/flutter-performance。禁止模型根据卡顿/动画等话题自动加载。
disable-model-invocation: true
version: 1.0.0
---

# Flutter 动画 / 切换性能排查（实战提取）

本库每一条都来自**真实排查并验证过的问题**，不是泛泛的通用清单。起点是一次大图（立绘）左右切换
动画"不流畅"的排查：主诉"卡"，最后定位是曲线观感 + 每帧重建，跟解码无关。**遇到新性能坑，
按本文"症状→根因→解法"的格式往下追加，让它越攒越准。**

## 第一步：先分诊「真掉帧」还是「曲线观感」

这是最值钱的一步——那次"卡"其实是 `linear` + 500ms 的匀速生硬感，根本不是掉帧。分诊错了
就会去白白重构渲染。

- 帧率满格但**生硬 / 匀速 / 突然启停** → 观感问题，改**曲线 / 时长**就好。
- 画面**真跳格 / 丢帧**，低端机更糟 → 才去查逐帧重建 / 图片解码。
- 先排掉最廉价的曲线 / 时长项，再碰渲染。要量化用 performance overlay 看哪条 16ms 线破。

## 速查表：症状 → 根因 → 解法

| 症状 | 根因 | 解法 |
|------|------|------|
| 位移 / 滑动切换匀速、生硬、机械 | `Curves.linear` + 偏长时长 | 换 `easeOutCubic` / `easeOutQuart` 末端减速；时长 300–500ms 按手感调 |
| 切换动画掉帧 / 偏重 | `AnimatedBuilder.builder` 里每帧 `new` 重子树（如 `Image`） | 把不变子树放 `child` 槽只建一次，builder 只做 paint 变换（见下方代码） |
| 动画时整页跟着重建 | 想用 `setState` 逐帧驱动动画 | 用 `AnimationController` + `AnimatedBuilder`；再用一个 `bool` 标志分稳态 / 动画态，`setState` 只在动画**开始与结束各调一次** |
| 切回稳态瞬间闪回起点 | `controller.reset()` 把 value 归 0 并**同步触发 listener**，此时仍在动画态 | 先 `setState` 切回稳态、再 `reset()`；或省略 reset，下次 `forward(from: 0)` 自动归零 |

## AnimatedBuilder 的 child 缓存（那次的核心重构）

最伤性能的反模式：在 `builder` 里每帧重建重量级子树。`AnimatedBuilder` 的 `child` 槽就是为
避免这点而生——child 只构建一次，builder 每帧只做 paint 阶段的便宜变换（`Transform.translate`
平移的是已上传 GPU 的纹理，近乎免费）。

```dart
// ❌ 那次的问题：动画每帧都 new 两张大图子树，每帧 rebuild + relayout
AnimatedBuilder(
  animation: anim,
  builder: (context, _) => Stack(children: [
    Transform.translate(offset: ..., child: buildImage(fromPage)), // 每帧 new Image
    Transform.translate(offset: ..., child: buildImage(toPage)),   // 每帧 new Image
  ]),
);

// ✅ 改法：图片作为稳定 child 缓存，builder 只算 offset
Stack(children: [
  AnimatedBuilder(
    animation: anim,
    child: buildImage(fromPage),                  // 只构建一次
    builder: (context, child) => Transform.translate(
      offset: Offset(-anim.value * w, 0),
      child: child,
    ),
  ),
  AnimatedBuilder(
    animation: anim,
    child: buildImage(toPage),
    builder: (context, child) => Transform.translate(
      offset: Offset((1 - anim.value) * w, 0),
      child: child,
    ),
  ),
]);
```

> 一个 `AnimatedBuilder` 只有一个 `child` 槽。两个需要**各自独立位移**的子树，就拆成两个并列的
> `AnimatedBuilder`（各带自己的 child），别塞进同一个 builder 里重建。

## 大图切换：先排除解码，再怀疑动画

那次能快速锁定根因，靠的是先确认图片侧是健康的、**把解码嫌疑排除掉**。排查大图（立绘 / 背景 /
封面）切换卡顿时，先核对这两点：

1. **是否降采样**：用 `ResizeImage` 解码到"实际显示的物理像素"，而不是全分辨率解码大图
   （那次立绘源图 1356×2160，不降采样解码会抖）。
2. **是否预解码**：进动画前 `precacheImage` 预热候选图；precache 与渲染须**同一 cache key**
   （`ResizeImage` 宽高一致才命中）。

若这两点都已做到，卡的根因就**不在解码**，回到上面的曲线 / 每帧重建去找，别再纠结图片。

## 项目落点

- 页面级动画一律 `AnimationController` + `AnimatedBuilder` 驱动，禁止 `setState` 逐帧（硬性规范 #7）。
- 大图统一走 `ResizeImage` 降采样 + `precacheImage` 预解码；项目内出现第二处同类需求时，把工具方法收敛到 `lib/Util/` 下复用，别每处自己起一套全尺寸解码。
- 网络图片优先 `NetworkImageUtil`（已按 `imageType` 做内存解码缩放，见 `network-image`）。
- 左右切换类动画的推荐结构：`_isSliding` 标志 + 双 `AnimatedBuilder`，不变子树放 `child` 槽缓存。

---
*本文目前只覆盖「动画 / 切换」这一类——因为目前只有这一类是实战踩过并验证的。以后遇到别的性能
问题（启动慢、列表卡、内存泄漏等），确认是真问题、定位到真根因后，再按上面的格式新增章节。*
