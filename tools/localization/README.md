# Excel多语言转JSON工具

这个工具用于将本项目的多语言Excel文件转换为多个语言的JSON文件，并最终生成Dart语言的本地化文件。每种语言会在输出目录下生成对应的JSON文件，命名格式为：`序号_语言代码.json`。

## 功能特点

- 支持多种语言的翻译处理
- 自动清空输出目录，避免旧文件干扰
- 为每种语言生成独立的JSON文件，并以"序号_语言代码.json"命名
- 对于空值的翻译，会导出为空字符串而不是忽略该字段
- 确保每种语言都包含所有翻译键，缺失的键会设置为空字符串
- 严格检测Excel中的重复键，发现重复键时直接报错并终止程序
- 自动将译文中的`%s`格式化占位符替换为`@param`
- 显示每种语言的翻译完成率
- 直接生成包含`Map<String, Map<String, String>> translations`的`MyLocalization.dart`文件
- 支持命令行参数配置输入和输出
- 支持配置Excel工作表名称，可以处理不同客户端的工作表（如"client"）
- 提供错误处理和详细日志

## 系统要求

- Python 3.6或更高版本
- openpyxl库（用于读取Excel文件）

## 安装依赖

```bash
pip install openpyxl
```

## 使用方法

### 一键执行整个流程

使用Shell脚本执行从Excel到JSON再到Dart的完整流程：

```bash
./generate_translations.sh
```

可以指定工作表和其他参数：

```bash
./generate_translations.sh -s "client" -i "languages.xlsx" -o "多语言"
```

### 单独执行Excel转JSON

如果只需要生成JSON文件而不生成Dart文件，可以直接使用：

```bash
python excel_to_json.py -i 你的文件名.xlsx -o 输出目录 -s 工作表名称
```

### 单独执行JSON转Dart本地化文件

如果已经有JSON文件，只需要生成Dart文件，可以直接使用：

```bash
python generate_localization.py 多语言目录 输出文件名.dart
```

### 参数说明

- Excel转JSON:
  - `-i, --input`: 输入Excel文件路径（默认：`languages.xlsx`）
  - `-o, --output`: 输出目录路径（默认：`多语言`）
  - `-s, --sheet`: Excel工作表名称（默认：`client`）

- JSON转Dart (generate_localization.py):
  - 参数1: JSON文件所在目录（默认：`多语言`）
  - 参数2: 输出的Dart文件名（默认：`MyLocalization.dart`）

- generate_translations.sh:
  - `-s, --sheet`: Excel工作表名称（默认：`client`）
  - `-i, --input`: 输入Excel文件路径（默认：`languages.xlsx`）
  - `-o, --output`: 输出目录路径（默认：`多语言`）

## Excel文件格式要求

Excel文件应按以下格式组织：

- **工作表名称**: 可配置，默认为`client`
- **第1列**: 语言key（从第3行开始有效）
- **第2列**: 内容说明（仅供参考，不导出）
- **第3列及之后**: 各语言的翻译内容
  - 第1行: 语言代码（如 'en', 'es', 'zh' 等）
  - 第2行: 语言名称（如 'English', 'Spanish', 'Chinese' 等）
  - 第3行: 语言说明（仅供参考，不导出）
  - 第4行及之后: 实际翻译内容

## 格式占位符处理

对于文本中的格式化占位符，脚本会自动将文本中的`%s`替换为`@param`，例如：

原始文本：
```
欢迎您，%s！您已经连续登录%s天。
```

处理后的文本：
```
欢迎您，@param！您已经连续登录@param天。
```

这样处理可以使输出的文本更适合目标平台的字符串格式化需求，避免格式化错误。

## 重复键处理

脚本会严格检测Excel中的重复键，如果发现任何重复键，程序将立即报错并终止执行。错误信息将包含重复键的详细信息，例如：

```
错误: 检测到重复的翻译键!
  - 键 'welcome' 在以下行出现: 10, 25
  - 键 'cancel' 在以下行出现: 15, 30, 45

请修复Excel文件中的重复键后再试。
```

必须修复Excel文件中的所有重复键，程序才能继续执行。这样设计可以确保翻译数据的一致性和可靠性。

## 输出结果

### JSON文件

脚本会在指定的输出目录中生成多个JSON文件，每个文件对应一种语言。文件名格式为"序号_语言代码.json"。例如：

```
多语言/
  ├── 0_en.json
  ├── 1_es.json
  ├── 2_zh.json
  └── ...
```

每个JSON文件包含对应语言的所有翻译内容，即使某些翻译为空也会保留该字段，格式如下：

```json
{
  "key1": "翻译1",
  "key2": "翻译2，包含@param占位符",
  "key3": ""  // 空翻译会设置为空字符串
}
```

### Dart本地化文件

脚本最终会生成一个`MyLocalization.dart`文件，其中只包含所有语言的翻译内容的Map变量，格式如下：

```dart
// 该文件由generate_localization.py自动生成，请勿手动修改
// Generated on: 2023-05-15 10:04:37

// 直接的多语言翻译映射
final Map<String, Map<String, String>> translations = {
  // 0_en
  "en": {
    "key1": "value1",
    "key2": "value2 with @param placeholder",
    // ...
  },
  // 1_es
  "es": {
    "key1": "valor1",
    "key2": "valor2 con marcador de posición @param",
    // ...
  },
  // 其他语言...
};
```

**注意**：运行脚本前，会自动清空输出目录中的所有文件和文件夹，请确保备份重要数据。