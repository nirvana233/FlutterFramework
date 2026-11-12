#!/bin/bash

# 获取脚本所在的父目录的父目录，即项目根目录
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
TARGET_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk/"

if [ -d "$TARGET_DIR" ]; then
    echo "Opening $TARGET_DIR"
    open "$TARGET_DIR"
else
    echo "错误: 目录不存在 $TARGET_DIR"
    echo "请确认是否已经运行过安卓编译程序。"
fi
