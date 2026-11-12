#!/bin/bash

# Pod 重新安装脚本
# 删除 Podfile.lock 文件并重新运行 pod install

echo "🚀 开始 Pod 重新安装过程..."

# 获取脚本所在目录的上两级目录（项目根目录）
PROJECT_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"

echo "📁 项目根目录: $PROJECT_ROOT"
echo "📁 iOS 目录: $IOS_DIR"

# 检查 iOS 目录是否存在
if [ ! -d "$IOS_DIR" ]; then
    echo "❌ 错误: iOS 目录不存在: $IOS_DIR"
    exit 1
fi

# 进入 iOS 目录
cd "$IOS_DIR"

# 检查 Podfile 是否存在
if [ ! -f "Podfile" ]; then
    echo "❌ 错误: Podfile 不存在于 $IOS_DIR"
    exit 1
fi

# 删除 Podfile.lock 文件
if [ -f "Podfile.lock" ]; then
    echo "🗑️  删除 Podfile.lock..."
    rm -f Podfile.lock
    echo "✅ Podfile.lock 已删除"
else
    echo "ℹ️  Podfile.lock 文件不存在，跳过删除步骤"
fi

# 删除 Pods 目录
if [ -d "Pods" ]; then
    echo "🗑️  删除 Pods 目录..."
    rm -rf Pods
    echo "✅ Pods 目录已删除"
else
    echo "ℹ️  Pods 目录不存在，跳过删除步骤"
fi

# 检查 CocoaPods 是否安装
if ! command -v pod &> /dev/null; then
    echo "❌ 错误: CocoaPods 未安装，请先安装 CocoaPods"
    echo "💡 安装命令: gem install cocoapods"
    exit 1
fi

# 运行 pod install
echo "📦 运行 pod install..."
pod install

# 检查命令执行结果
if [ $? -eq 0 ]; then
    echo "✅ Pod 安装成功完成！"
else
    echo "❌ Pod 安装失败"
    exit 1
fi

echo "🎉 Pod 重新安装过程完成！"
