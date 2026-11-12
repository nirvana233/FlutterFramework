---
name: create-model
description: 当用户需要根据 JSON 生成 Flutter Model 文件时自动触发。关键词：生成 Model、创建 Model、JSON 转 Model、新建数据模型、接口 Model、XxxModel.dart。
version: 1.0.0
---

# Flutter Model 生成规范

本项目使用 `json_annotation` + `json_serializable` 自动生成序列化代码。

## 核心依赖

- `json_annotation`：提供 `@JsonSerializable()` 注解
- 生成文件：`XxxModel.g.dart`（由 `build_runner` 自动生成，禁止手动编辑）

---

## Step 1：分析 JSON 结构

用户提供 JSON 后，按以下规则映射 Dart 类型：

| JSON 类型 | Dart 类型 |
|-----------|-----------|
| `"string"` | `String?` |
| `123` (整数) | `int?` |
| `1.5` (小数) | `double?` |
| `true/false` | `bool?` |
| `{ ... }` (对象) | 新建子类（大驼峰命名）`XxxModel?` |
| `[ ... ]` (数组) | `List<XxxModel>?` 或 `List<int>?` 等 |
| `null` | 根据字段语义推断类型，加 `?` |

**字段命名：** JSON key 通常是 camelCase，直接映射为同名 Dart 字段。若 JSON key 为 snake_case，需加 `@JsonKey(name: 'field_name')`。

---

## Step 2：API 响应外层包装结构

> **重要！** 服务器接口文档通常只展示 `result` 内部的数据结构，并不包含外层字段。
> 但在定义 Model 时，**必须补全完整的外层包装**，即加上 `code`、`msg`、`result`、`sysAt`、`cost`、`traceId` 这六个字段。
>
> 完整的服务器响应格式如下：
> ```json
> {
>   "code": 200,
>   "msg": "",
>   "result": {},
>   "sysAt": 1774598182,
>   "cost": 124,
>   "traceId": "64383331839643648"
> }
> ```
> 文档只给 `result` 里的内容 ≠ Model 只需要定义 `result` 里的内容。

所有接口响应都有统一的外层结构，**外层包装类**固定格式如下：

```dart
@JsonSerializable()
class XxxModel {
  int? code;
  XxxResult? result;   // result 类型根据实际数据定义
  String? msg;
  int? sysAt;
  int? cost;
  String? traceId;

  XxxModel({this.code, this.result, this.msg, this.sysAt, this.cost, this.traceId});

  factory XxxModel.fromJson(Map<String, dynamic> json) => _$XxxModelFromJson(json);
  Map<String, dynamic> toJson() => _$XxxModelToJson(this);
}
```

若 `result` 是列表（如分页数据），`result` 类型改为 `List<XxxItem>?`，并在 `fromJson` 内处理。

---

## Step 3：完整文件模板

### 文件位置

```
lib/MainPage/XxxPage/Model/XxxModel.dart
lib/MainPage/XxxPage/Model/XxxModel.g.dart  ← 自动生成，不用手动创建
```

### 文件结构模板

```dart
import 'package:json_annotation/json_annotation.dart';

part 'XxxModel.g.dart';

// 外层响应包装
@JsonSerializable()
class XxxModel {
  int? code;
  XxxResult? result;
  String? msg;
  int? sysAt;
  int? cost;
  String? traceId;

  XxxModel({this.code, this.result, this.msg, this.sysAt, this.cost, this.traceId});

  factory XxxModel.fromJson(Map<String, dynamic> json) => _$XxxModelFromJson(json);
  Map<String, dynamic> toJson() => _$XxxModelToJson(this);
}

// result 数据结构
@JsonSerializable()
class XxxResult {
  int? total;
  List<XxxItem>? list;

  XxxResult({this.total, this.list});

  factory XxxResult.fromJson(Map<String, dynamic> json) => _$XxxResultFromJson(json);
  Map<String, dynamic> toJson() => _$XxxResultToJson(this);
}

// 列表子项
@JsonSerializable()
class XxxItem {
  int? id;
  String? name;

  XxxItem({this.id, this.name});

  factory XxxItem.fromJson(Map<String, dynamic> json) => _$XxxItemFromJson(json);
  Map<String, dynamic> toJson() => _$XxxItemToJson(this);
}
```

---

## Step 4：生成 .g.dart 文件

创建 `.dart` 文件后，**必须运行**：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

或增量构建（开发中推荐）：

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

---

## 常见场景示例

### 场景一：result 是单个对象

JSON：
```json
{
  "code": 200,
  "result": {
    "userId": 123,
    "nickname": "Tom",
    "vip": true
  }
}
```

生成：
```dart
@JsonSerializable()
class UserInfoModel {
  int? code;
  UserInfoResult? result;
  String? msg;
  int? sysAt;
  int? cost;
  String? traceId;

  UserInfoModel({this.code, this.result, this.msg, this.sysAt, this.cost, this.traceId});

  factory UserInfoModel.fromJson(Map<String, dynamic> json) => _$UserInfoModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoModelToJson(this);
}

@JsonSerializable()
class UserInfoResult {
  int? userId;
  String? nickname;
  bool? vip;

  UserInfoResult({this.userId, this.nickname, this.vip});

  factory UserInfoResult.fromJson(Map<String, dynamic> json) => _$UserInfoResultFromJson(json);
  Map<String, dynamic> toJson() => _$UserInfoResultToJson(this);
}
```

### 场景二：result 是数组

JSON：
```json
{
  "code": 200,
  "result": [
    { "id": 1, "title": "Book A" }
  ]
}
```

生成：
```dart
@JsonSerializable()
class BookListModel {
  int? code;
  List<BookListItem>? result;
  String? msg;
  int? sysAt;
  int? cost;
  String? traceId;

  BookListModel({this.code, this.result, this.msg, this.sysAt, this.cost, this.traceId});

  factory BookListModel.fromJson(Map<String, dynamic> json) => _$BookListModelFromJson(json);
  Map<String, dynamic> toJson() => _$BookListModelToJson(this);
}

@JsonSerializable()
class BookListItem {
  int? id;
  String? title;

  BookListItem({this.id, this.title});

  factory BookListItem.fromJson(Map<String, dynamic> json) => _$BookListItemFromJson(json);
  Map<String, dynamic> toJson() => _$BookListItemToJson(this);
}
```

### 场景三：带分页的列表

JSON：
```json
{
  "code": 200,
  "result": {
    "total": 100,
    "pageNum": 1,
    "pageSize": 20,
    "list": [
      { "id": 1, "name": "Item A" }
    ]
  }
}
```

生成：
```dart
@JsonSerializable()
class PagedListModel {
  int? code;
  PagedListResult? result;
  String? msg;
  int? sysAt;
  int? cost;
  String? traceId;

  PagedListModel({this.code, this.result, this.msg, this.sysAt, this.cost, this.traceId});

  factory PagedListModel.fromJson(Map<String, dynamic> json) => _$PagedListModelFromJson(json);
  Map<String, dynamic> toJson() => _$PagedListModelToJson(this);
}

@JsonSerializable()
class PagedListResult {
  int? total;
  int? pageNum;
  int? pageSize;
  List<PagedListItem>? list;

  PagedListResult({this.total, this.pageNum, this.pageSize, this.list});

  factory PagedListResult.fromJson(Map<String, dynamic> json) => _$PagedListResultFromJson(json);
  Map<String, dynamic> toJson() => _$PagedListResultToJson(this);
}

@JsonSerializable()
class PagedListItem {
  int? id;
  String? name;

  PagedListItem({this.id, this.name});

  factory PagedListItem.fromJson(Map<String, dynamic> json) => _$PagedListItemFromJson(json);
  Map<String, dynamic> toJson() => _$PagedListItemToJson(this);
}
```

### 场景四：snake_case 字段名

JSON key 为 snake_case 时加 `@JsonKey`：

```dart
@JsonKey(name: 'book_id')
int? bookId;

@JsonKey(name: 'created_at')
int? createdAt;
```

---

## 命名规范

| 元素 | 规范 | 示例 |
|------|------|------|
| 外层类 | 功能名 + `Model` | `TaskModel`、`BookDetailModel` |
| result 类 | 功能名 + `Result` | `TaskResult`、`BookDetailResult` |
| 列表子项类 | 功能名 + `Item` | `TaskItem`、`BookItem` |
| 嵌套子对象 | 语义名 + `Model` | `AuthorModel`、`ChapterModel` |
| 文件名 | 同外层类名 | `TaskModel.dart` |

---

## 重要规范

- **所有字段加 `?` 可空**，避免解析崩溃
- **禁止手动编辑 `.g.dart` 文件**，修改 `.dart` 后重新运行 `build_runner`
- 同一文件可定义多个 `@JsonSerializable()` 类
- 所有类都在同一 `part` 文件声明范围内，`part 'XxxModel.g.dart'` 只写一次
- 若只是操作类返回（无 result 数据），直接用 `lib/Common/Model/CommonModel.dart`，无需新建 Model

## 参考文件

- **分页列表 Model（外层包装 + result + 列表子项）**: `lib/MainPage/Example/Model/ExampleModel.dart`
- **通用响应 Model**: `lib/Common/Model/CommonModel.dart`
- **通用 Model**: `lib/Common/Model/CommonModel.dart`
