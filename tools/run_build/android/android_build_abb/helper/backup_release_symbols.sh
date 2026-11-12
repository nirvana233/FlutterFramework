#!/bin/bash
set -euo pipefail

CHECK_ONLY=0
ASSUME_YES=0
for ARG in "$@"; do
    case "$ARG" in
        --check-only) CHECK_ONLY=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        *) echo "❌ 未知参数: $ARG" >&2; exit 1 ;;
    esac
done

# 按版本备份符号表；同版本备份已存在时需确认覆盖。
PROJECT_ROOT="$(cd "$(dirname "$0")/../../../../.." && pwd)"
PUBSPEC="$PROJECT_ROOT/pubspec.yaml"
DEBUG_INFO_DIR="$PROJECT_ROOT/test/debug-info"
BACKUP_DIR="$PROJECT_ROOT/test/backup-symbols"

if [ ! -f "$PUBSPEC" ]; then
    echo "❌ 错误: 找不到 pubspec.yaml: $PUBSPEC"
    exit 1
fi

VERSION_LINE="$(grep -E '^version:' "$PUBSPEC" | head -1 | awk '{print $2}')"
if [ -z "$VERSION_LINE" ]; then
    echo "❌ 错误: pubspec.yaml 中未找到 version 字段"
    exit 1
fi

VERSION_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"
if [ "$VERSION_NAME" = "$BUILD_NUMBER" ]; then
    echo "❌ 错误: version 缺少 build number（应形如 1.0.17+57），当前: $VERSION_LINE"
    exit 1
fi

ZIP_NAME="${VERSION_NAME}-${BUILD_NUMBER}-debug-info.zip"
ZIP_PATH="$BACKUP_DIR/$ZIP_NAME"

if [ -f "$ZIP_PATH" ] && [ "$ASSUME_YES" -eq 0 ]; then
    echo "⚠️ 已存在符号备份: $ZIP_PATH"
    printf "覆盖它？[y/N] "
    ANSWER=""
    read -r ANSWER || exit 1
    case "$ANSWER" in
        y|Y|yes|YES) ;;
        *) echo "🛑 已取消符号备份，旧备份保持不变。"; exit 1 ;;
    esac
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
    exit 0
fi

# 缺少符号时直接终止，避免生成空备份。
shopt -s nullglob
SYMBOL_FILES=("$DEBUG_INFO_DIR"/*.symbols)
if [ "${#SYMBOL_FILES[@]}" -eq 0 ]; then
    echo "❌ 未找到符号文件: $DEBUG_INFO_DIR" >&2
    exit 1
fi

echo "🗄️ 备份符号表"
if ! mkdir -p "$BACKUP_DIR"; then
    echo "❌ 无法创建符号备份目录: $BACKUP_DIR"
    exit 1
fi

# 先在目标目录生成并校验临时 zip，最后用同文件系统的 mv 原子替换旧备份。
# 即使压缩或校验失败，已存在的线上符号备份也不会被提前删除。
TEMP_ZIP_PATH="$(mktemp "$BACKUP_DIR/.${ZIP_NAME}.tmp.XXXXXX")"
if [ -z "$TEMP_ZIP_PATH" ] || [ ! -f "$TEMP_ZIP_PATH" ]; then
    echo "❌ 无法创建临时符号备份"
    exit 1
fi

cleanup_temp_zip() {
    if [ -n "$TEMP_ZIP_PATH" ] && [ -f "$TEMP_ZIP_PATH" ]; then
        rm -f "$TEMP_ZIP_PATH"
    fi
}
trap cleanup_temp_zip EXIT

# 保留 debug-info/ 目录层级，与 test/backup-symbols/ 下已有历史备份的结构一致
if ! (cd "$(dirname "$DEBUG_INFO_DIR")" &&
    zip -q - "$(basename "$DEBUG_INFO_DIR")"/*.symbols > "$TEMP_ZIP_PATH"); then
    echo "❌ 符号压缩失败，旧备份保持不变: $ZIP_PATH"
    exit 1
fi

if [ ! -s "$TEMP_ZIP_PATH" ] || ! unzip -tq "$TEMP_ZIP_PATH" >/dev/null 2>&1; then
    echo "❌ 符号备份校验失败，旧备份保持不变: $ZIP_PATH"
    exit 1
fi

if ! mv -f "$TEMP_ZIP_PATH" "$ZIP_PATH"; then
    echo "❌ 无法替换符号备份，旧备份保持不变: $ZIP_PATH"
    exit 1
fi
TEMP_ZIP_PATH=""
trap - EXIT

ZIP_SIZE="$(du -h "$ZIP_PATH" | awk '{print $1}')"
echo "✅ 备份完成: test/backup-symbols/$ZIP_NAME ($ZIP_SIZE)"
