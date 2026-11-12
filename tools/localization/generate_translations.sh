#!/bin/bash

# 获取脚本所在目录的绝对路径
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 设置默认值
SHEET_NAME="client"
INPUT_FILE="languages.xlsx"
OUTPUT_DIR="多语言"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--sheet)
      SHEET_NAME="$2"
      shift 2
      ;;
    -i|--input)
      INPUT_FILE="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "未知参数: $1"
      echo "用法: $0 [-s|--sheet 工作表名] [-i|--input 输入文件] [-o|--output 输出目录]"
      exit 1
      ;;
  esac
done

# 输出开始执行信息
echo "===== 开始执行多语言文件处理 ====="
echo "脚本目录: $SCRIPT_DIR"
echo "工作表: $SHEET_NAME"
echo "输入文件: $INPUT_FILE"
echo "输出目录: $OUTPUT_DIR"

# 检查Python3是否安装
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3，请先安装Python3"
    exit 1
fi

# 切换到脚本目录
cd "$SCRIPT_DIR"

# 执行Excel转JSON脚本
echo "===== 步骤1: Excel转JSON ====="
echo "正在执行 excel_to_json.py..."
python3 "$SCRIPT_DIR/excel_to_json.py" -i "$INPUT_FILE" -o "$OUTPUT_DIR" -s "$SHEET_NAME"

# 检查excel_to_json.py执行结果
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    if [ $EXIT_CODE -eq 1 ]; then
        echo "错误: Excel转JSON失败。可能是由于Excel文件中存在重复键或其他格式问题。"
        echo "请修复问题后重新运行脚本。"
    else
        echo "错误: Excel转JSON失败，退出代码: $EXIT_CODE"
    fi
    exit $EXIT_CODE
fi

echo "Excel转JSON完成，多语言JSON文件已生成"

# 执行JSON转Dart脚本 - 生成MyLocalization.dart
echo "===== 步骤2: 生成Dart本地化文件 ====="
echo "正在执行 generate_localization.py..."
python3 "$SCRIPT_DIR/generate_localization.py" "$OUTPUT_DIR" "../../lib/Util/Translations/MyLocalization.dart"

# 检查执行结果
if [ $? -eq 0 ]; then
    echo "===== 本地化文件生成成功 ====="
    echo "输出文件: ../../lib/Util/Translations/MyLocalization.dart"
    echo "文件已直接覆盖到项目目录，无需手动复制"
else
    echo "错误: 本地化文件生成失败"
    exit 1
fi

# 提示用户下一步操作
echo "您可以查看更新后的 lib/Util/Translations/MyLocalization.dart 文件"
echo "===== 脚本执行完毕 ====="
