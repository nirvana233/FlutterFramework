#!/usr/bin/env bash
# PostToolUse hook：自动格式化被编辑的 .dart 文件（line-length 100）
# 设计为静默、永远 exit 0，不打断主流程；只做格式化，不动 import 排序逻辑。
set -u

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)

[ -z "$file" ] && exit 0
case "$file" in
  *.dart) ;;
  *) exit 0 ;;
esac
case "$file" in
  *.g.dart) exit 0 ;;   # 自动生成文件不格式化
esac
[ -f "$file" ] || exit 0

# dart 在 PATH 时才执行；找不到也静默退出，绝不阻断
command -v dart >/dev/null 2>&1 || exit 0
dart format --line-length 100 "$file" >/dev/null 2>&1

exit 0
