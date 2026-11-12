# 多语言国际化管理工具

这是一套用于管理本 Flutter 项目多语言翻译的自动化工具集。该工具帮助开发者扫描代码中的多语言文本，与 Excel 翻译表对比，并自动将硬编码文本替换为国际化 key。

## 工具概述

### 1. find_mutil_language.py
**功能**：扫描项目中所有需要翻译的文本

- 遍历 `lib` 目录下所有 `.dart` 文件
- 查找所有使用 `"~xxx"` 或 `'~xxx'` 格式标记的多语言文本（~ 前缀表示需要翻译的文本）
- 将找到的所有唯一文本输出到 `find_mutil_language.txt`

**运行方式**：
```bash
python3 find_mutil_language.py
```

**输出文件**：
- `find_mutil_language.txt`：所有找到的多语言文本列表

---

### 2. find_need_add_to_excel.py
**功能**：对比代码中的文本与 Excel 翻译表

- 读取 `find_mutil_language.txt` 中的文本列表
- 与 `tools/localization/languages.xlsx` 的 "client" 工作表进行对比
- 找出哪些文本已经在 Excel 中，哪些需要添加

**依赖**：
```bash
pip install openpyxl
```

**运行方式**：
```bash
python3 find_need_add_to_excel.py
```

**输入文件**：
- `find_mutil_language.txt`：待检查的文本列表
- `tools/localization/languages.xlsx`：项目翻译表

**输出文件**：
- `find_need_add_to_excel.txt`：需要添加到 Excel 的文本
- `find_already_in_excel.txt`：已存在的文本及其对应的 key（格式：`en_value    key_value`）

---

### 3. generate_language_key/generate_language_key.py
**功能**：为待新增的英文文案批量生成国际化 key

- 读取 `find_mutil_language.txt` 中的英文文案
- 读取 `lib/Util/Translations/MyLocalization.dart` 中所有现有 key
- 生成不与现有任意语言 key 重复的新 key
- 优先生成最多 `2` 个下划线的 key；只有在第 4 个核心词确实对语义有帮助时，才允许使用最多 `3` 个下划线
- 如果仍然冲突，会在 key 末尾追加数字后缀
- 会尽量保留 `@param1` 这类参数信息，使 key 一眼可看出是参数文案

**运行方式**：
```bash
cd generate_language_key
python3 generate_language_key.py
```

**输入文件**：
- `../find_mutil_language.txt`：待生成 key 的英文文案
- `../../lib/Util/Translations/MyLocalization.dart`：现有多语言 key 集合

**输出文件**：
- `generated_keys.txt`：生成结果（格式：`key\ten_value`）

**生成示例**：
```txt
param1_m_ago    @param1m ago
removed_history Removed from history
font_download_failed2    Font download failed, please try again later
```

**人工检查**：
- `generated_keys.txt` 是候选结果，不是最终结果
- 自动生成的 key 可能语义过弱，例如 `i`、`not`、`love`、`chat` 这类单词，或 `profile2`、`chat2` 这类数字后缀
- 添加到 Excel 前需要人工 review，优先改成能表达场景的 key，例如 `profile_i_am`、`profile_not_for_you`、`just_this_chat`
- 手动改名后需要确认新 key 不在现有多语言 key 和 Excel key 中重复

---

### 4. write_excel_to_code/write_excel_to_code.py
**功能**：将代码中的硬编码文本替换为国际化 key

- 从 `lan.txt` 加载 en 文本到 key 的映射关系
- 遍历所有 `.dart` 文件，将 `"~xxx"` 或 `'~xxx'` 替换为对应的 key
- 如果文本不包含参数（@param1 等），会添加 `.tr` 后缀以调用翻译
- 在替换的代码上方添加注释保留原始英文文本
- 自动添加 `import 'package:get/get.dart';` 如果文件中没有

**运行方式**：
```bash
cd write_excel_to_code
python3 write_excel_to_code.py
```

**输入文件**：
- `lan.txt`：翻译映射表（格式：`key\ten_value`）

**替换示例**：
```dart
// 替换前
Text("~Welcome to MyApp")

// 替换后
// Welcome to MyApp
Text('welcome_to_myapp'.tr)
```

---

### 5. replace_already_exist.py
**功能**：只替换 Excel 中已经存在的文案

- 从 `find_already_in_excel.txt` 加载已存在文案到 key 的映射
- 适合在新增 key 尚未入库前，先把当前系统已有 key 替换进代码
- 普通文本会替换为 `'key'.tr`
- 如果原文后面已经接了 `.tr`、`.trParams(...)` 或 `.trArgs(...)`，只替换字符串本身，保留原有调用方式
- 如果文案包含 `@param1` 等参数但原代码没有 `.trParams(...)` / `.trArgs(...)`，脚本只替换成 `'key'` 并在终端输出人工处理提示

**运行方式**：
```bash
cd tools/write_en_to_excel
python3 replace_already_exist.py
```

**输入文件**：
- `find_already_in_excel.txt`：已存在文本及 key（格式：`en_value    key_value`）

---

### 6. replace_string_to_new/replace_string_to_new.py
**功能**：批量替换代码中的多语言文本

- 从 `str.txt` 读取替换规则（旧文本 -> 新文本）
- 在所有 `.dart` 文件中将 `~旧文本` 替换为 `~新文本`
- 自动忽略 `MyLocalization.dart` 文件

**运行方式**：
```bash
cd replace_string_to_new
python3 replace_string_to_new.py
```

**输入文件**：
- `str.txt`：替换规则文件（格式：`old_text\tnew_text`，每行一个规则）

**输出文件**：
- `replaced.txt`：替换操作的详细日志

---

## 完整工作流程

### 步骤 1：扫描项目中的多语言文本
```bash
python3 find_mutil_language.py
```
这会生成 `find_mutil_language.txt`，包含所有使用 `~` 前缀标记的文本。

### 步骤 2：检查哪些文本需要添加到 Excel
```bash
python3 find_need_add_to_excel.py
```
这会生成两个文件：
- `find_need_add_to_excel.txt`：需要手动添加翻译的文本
- `find_already_in_excel.txt`：已有翻译的文本和 key

### 步骤 3：先替换已存在的 key
```bash
python3 replace_already_exist.py
```
这一步只读取 `find_already_in_excel.txt`，不会使用新生成但尚未入库的 key。

带参数文案需要检查替换结果：
- 原代码已有 `.trParams(...)` / `.trArgs(...)`：脚本只替换字符串，保留参数调用
- 原代码没有参数调用：脚本会输出需人工补 `.trParams({...})` 的位置

### 步骤 4：为新文案生成 key
```bash
cd generate_language_key
python3 generate_language_key.py
```
这会生成 `generated_keys.txt`，格式为：
```txt
key_name    English text
```

### 步骤 5：在 Excel 中添加翻译
1. 打开 `tools/localization/languages.xlsx`
2. 先人工 review `generate_language_key/generated_keys.txt`，把语义过弱、过短或带数字后缀的 key 改成更清晰的命名
3. 在 "client" 工作表中补充 review 后的 key 和英文文本
4. 为每个文本设置 key、英文翻译和其他语言的翻译
5. 保存 Excel 文件

### 步骤 6：导出映射到 lan.txt
将 Excel 中的 key 和 en 列导出到 `write_excel_to_code/lan.txt`，格式为：
```
key_name    English text
another_key    Another text
```

### 步骤 7：替换代码中的文本为 key
```bash
cd write_excel_to_code
python3 write_excel_to_code.py
```
这会自动将所有 `"~xxx"` 替换为对应的国际化 key 引用。

### 步骤 8（可选）：批量修改文本内容
如果需要修改某些多语言文本的内容：
1. 在 `replace_string_to_new/str.txt` 中添加替换规则
2. 运行：
```bash
cd replace_string_to_new
python3 replace_string_to_new.py
```

---

## 文件说明

### 脚本文件
- `find_mutil_language.py` - 扫描工具
- `find_need_add_to_excel.py` - 对比工具
- `generate_language_key/generate_language_key.py` - key 生成工具
- `write_excel_to_code/write_excel_to_code.py` - 替换工具
- `replace_already_exist.py` - 只替换 Excel 已存在 key 的工具
- `replace_string_to_new/replace_string_to_new.py` - 批量修改工具

### 数据文件
- `find_mutil_language.txt` - 扫描结果
- `find_need_add_to_excel.txt` - 需要添加的文本
- `find_already_in_excel.txt` - 已存在的文本
- `generate_language_key/generated_keys.txt` - 自动生成的 key 与英文映射
- `write_excel_to_code/lan.txt` - 翻译映射表
- `replace_string_to_new/str.txt` - 替换规则
- `replace_string_to_new/replaced.txt` - 替换日志

---

## 注意事项

1. **多语言文本标记**：在代码中使用 `~` 前缀标记需要翻译的文本
   ```dart
   Text("~Hello")  // 会被工具识别
   Text("Hello")   // 不会被识别
   ```

2. **参数化文本**：使用 `@param1`、`@param2` 等占位符
   ```dart
   Text("~Welcome @param1")  // 会被替换为 'welcome_key'（不加 .tr）
   ```

3. **key 生成规则**：
   - 默认优先生成最多 `2` 个下划线的 key
   - 只有满足以下任一条件时，才允许使用最多 `3` 个下划线：
     - 第 4 个核心词是明显的限定词，例如 `today`、`ago`、`daily`、`first`、`next`
     - 文案里包含 `@param1` 这类参数，且第 4 个核心词是时间单位或关系词，例如 `day`、`hour`、`ago`
     - 过滤停用词后仍有 `5` 个及以上核心词，前三个词明显不足以表达完整语义
   - 如果仍冲突，会自动追加数字后缀，如 `just_now2`
   - 参数占位符会尽量保留在 key 中，如 `param1_m_ago`

4. **人工 review key**：自动生成的 key 可能过短、过泛或只靠数字后缀避免冲突。添加到 Excel 前必须人工检查并改成更语义化的 key，例如把 `i` 改成 `profile_i_am`、把 `not` 改成 `profile_not_for_you`、把 `chat2` 改成 `chat_label`。

5. **备份代码**：在运行替换工具前，建议提交或备份代码

6. **检查结果**：替换后请检查编译是否通过，必要时手动调整

7. **Excel 格式**：确保 Excel 文件中有 "client" 工作表，且第一列为 key，en 列为英文文本

---

## 依赖安装

```bash
pip install openpyxl
```

---

## 技术栈

- Python 3
- openpyxl（Excel 文件处理）
- Flutter + GetX（国际化框架）

---

## 维护

如有问题或改进建议，请联系项目维护者。
