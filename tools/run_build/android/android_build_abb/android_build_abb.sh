#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$PROJECT_ROOT"

# 用法：android_build_abb.sh [--yes|-y] [自定义包名]
ASSUME_YES=""
CUSTOM_NAME=""
for ARG in "$@"; do
    case "$ARG" in
        --yes|-y) ASSUME_YES="--yes" ;;
        *) CUSTOM_NAME="$ARG" ;;
    esac
done

# 在修改环境、编译和上传前确认同版本备份覆盖。
bash "$SCRIPT_DIR/helper/backup_release_symbols.sh" --check-only ${ASSUME_YES:+"$ASSUME_YES"}

# 准备正式发布环境
bash "$SCRIPT_DIR/helper/prepare_release_env.sh"

# 执行打包（混淆 + 拆分符号表到 test/debug-info）
flutter build appbundle --release --obfuscate --split-debug-info=test/debug-info
# 接入 Firebase Crashlytics 后在此上传符号表（替换为项目自己的 Android App ID）：
# firebase crashlytics:symbols:upload --app=<FIREBASE_ANDROID_APP_ID> test/debug-info

# 按版本备份符号表
bash "$SCRIPT_DIR/helper/backup_release_symbols.sh" --yes

# 复制并命名产物，透传可选的自定义包名
bash "$SCRIPT_DIR/helper/copy_release_aab.sh" "$CUSTOM_NAME"
