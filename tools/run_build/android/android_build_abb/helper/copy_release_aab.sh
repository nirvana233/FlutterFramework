#!/bin/bash
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"

# 读取版本号并处理可选的自定义包名
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"
VERSION_LINE="$(grep -E '^version:' "$PUBSPEC" | head -1 | awk '{print $2}')"
VERSION_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"

CUSTOM_ARG="$1"
if [ -n "$CUSTOM_ARG" ]; then
    CUSTOM_NAME="$(basename "$CUSTOM_ARG")"
    if [[ "$CUSTOM_NAME" != *.aab ]]; then
        AAB_NAME="${CUSTOM_NAME}.aab"
    else
        AAB_NAME="$CUSTOM_NAME"
    fi
else
    APP_NAME="$(grep -E '^name:' "$PUBSPEC" | head -1 | awk '{print $2}')"
    AAB_NAME="${APP_NAME}-${VERSION_NAME}-${BUILD_NUMBER}-release.aab"
fi

echo "📦 目标自定义包名: $AAB_NAME"
echo ""

# 检查并复制构建产物
OUTPUT_DIR="$PROJECT_ROOT/build/app/outputs/bundle/release"
ORIGIN_AAB="$OUTPUT_DIR/app-release.aab"
if [ ! -f "$ORIGIN_AAB" ]; then
    echo "❌ 未找到 AAB 产物: $ORIGIN_AAB" >&2
    exit 1
fi

cp "$ORIGIN_AAB" "$OUTPUT_DIR/$AAB_NAME"
echo ""
echo "🎉 AAB 产物已复制并命名为:"
echo "   📁 ${OUTPUT_DIR#$PROJECT_ROOT/}/$AAB_NAME"
