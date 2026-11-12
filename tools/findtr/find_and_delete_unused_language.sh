#!/bin/bash

# 获取当前脚本的目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "开始执行 findtr.py..."
python3 "$SCRIPT_DIR/findtr.py"

if [ $? -eq 0 ]; then
    echo "findtr.py 执行成功。"
    echo "开始执行 clean_localization.py..."
    python3 "$SCRIPT_DIR/clean_localization.py"
    if [ $? -eq 0 ]; then
        echo "clean_localization.py 执行成功。"
        echo "所有本地化清理任务完成。"
    else
        echo "错误: clean_localization.py 执行失败。"
        exit 1
    fi
else
    echo "错误: findtr.py 执行失败。"
    exit 1
fi