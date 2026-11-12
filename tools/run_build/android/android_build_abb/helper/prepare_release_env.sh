#!/bin/bash
set -e

# 定位项目根目录 (tools/run_build/android/android_build_abb/helper -> ../../../../..)
PROJECT_ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"
CONST_FILE="$PROJECT_ROOT/lib/Util/Const.dart"

echo "🔍 检查测试环境开关配置..."
if [ ! -f "$CONST_FILE" ]; then
    echo "❌ 错误: 未找到配置文件 $CONST_FILE"
    exit 1
fi

for FLAG in isTestClient isTestServer; do
    FLAG_LINE="$(grep -E "^[[:space:]]*const bool ${FLAG} *=" "$CONST_FILE" | head -1)"
    if [ -z "$FLAG_LINE" ]; then
        echo "❌ 未在 Const.dart 中找到 ${FLAG} 的定义，停止打包" >&2
        exit 1
    fi
    FLAG_VALUE="$(echo "$FLAG_LINE" | sed -E "s/^[[:space:]]*const bool [a-zA-Z0-9_]+ *= *([a-zA-Z]+);.*/\1/")"
    if [ "$FLAG_VALUE" != "true" ] && [ "$FLAG_VALUE" != "false" ]; then
        echo "❌ 无法解析 ${FLAG} 的布尔值，停止打包" >&2
        exit 1
    fi
    if [ "$FLAG_VALUE" = "false" ]; then
        echo "   ${FLAG} = false"
    else
        sed -E "s/^([[:space:]]*const bool ${FLAG} *= *)[a-zA-Z]+(;)/\1false\2/" "$CONST_FILE" > "$CONST_FILE.tmp" && mv "$CONST_FILE.tmp" "$CONST_FILE" || exit $?
        if ! grep -Eq "^[[:space:]]*const bool ${FLAG} *= *false;" "$CONST_FILE"; then
            echo "❌ ${FLAG} 修改后未通过 false 校验，停止打包" >&2
            exit 1
        fi
        echo "   ⚠️ ${FLAG} 原为 ${FLAG_VALUE}，已自动修改为 false"
    fi
done
