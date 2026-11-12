   # 相对路径Import转绝对路径脚本

## 功能描述

`convert_relative_imports.py` 脚本用于将Flutter项目lib目录下所有使用相对路径的import语句转换为绝对路径。

## 转换示例

**转换前：**
```dart
import '../Util/Common/Tools.dart';
import '../../Common/Manager/AppMgr.dart';
import './Model/ExampleModel.dart';
```

**转换后：**
```dart
import 'package:flutter_framework/Util/Common/Tools.dart';
import 'package:flutter_framework/Common/Manager/AppMgr.dart';
import 'package:flutter_framework/MainPage/Example/Model/ExampleModel.dart';
```

## 使用方法

1. 确保你在项目根目录下
2. 运行脚本：
   ```bash
   python tools/import/convert_relative_imports.py
   ```

## 脚本特性

- ✅ 自动识别相对路径import（`../`, `./`, 或直接相对路径）
- ✅ 跳过已经是绝对路径的import（`package:`、`dart:`）
- ✅ 保持原有的import格式和注释
- ✅ 显示详细的转换过程
- ✅ 统计转换结果
- ✅ 错误处理和安全检查

## 运行结果

脚本会显示：
- 找到的Dart文件总数
- 每个被修改的文件和具体的转换内容
- 最终的统计信息
- 建议运行的检查命令

## 注意事项

1. 脚本会直接修改源文件，建议运行前先提交代码到git
2. 转换完成后建议运行 `flutter analyze` 检查语法
3. 脚本只处理lib目录下的.dart文件
4. 转换的绝对路径基于 `pubspec.yaml` 中的 `name`（package 名）
