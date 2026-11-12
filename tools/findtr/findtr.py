#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys

def remove_comments(code):
    """
    移除Dart代码中的注释
    - 移除 // 开始的单行注释
    - 移除 /* */ 之间的多行注释
    """
    # 移除多行注释 (/* ... */)
    code = re.sub(r'/\*[\s\S]*?\*/', '', code)
    
    # 移除单行注释 (// ...)
    code = re.sub(r'//.*?$', '', code, flags=re.MULTILINE)
    
    return code

def find_translation_keys(lib_path):
    """
    在指定路径下查找所有包含 .tr 或 .trParams 的翻译键，排除注释中的内容，支持跨行匹配
    """
    translation_keys = set()
    
    # 定义匹配模式：
    # 1. 标准模式: 'key'.tr 或 "key".tr
    # 2. 跨行模式: 'key'\s*.tr 或 "key"\s*.tr (包括换行和空格)
    # 3. trParams模式: 'key'.trParams(...) 或 "key".trParams(...)
    # 4. 跨行trParams模式: 'key'\s*.trParams(...) 或 "key"\s*.trParams(...)
    patterns = [
        # 标准单行 .tr 模式
        r"['\"]([^'\"]+)['\"]\.tr(?![a-zA-Z])",
        # 跨行 .tr 模式 (允许换行和空格)
        r"['\"]([^'\"]+)['\"]\s*\.tr(?![a-zA-Z])",
        # 标准单行 .trParams 模式
        r"['\"]([^'\"]+)['\"]\.trParams\s*\(",
        # 跨行 .trParams 模式 (允许换行和空格)
        r"['\"]([^'\"]+)['\"]\s*\.trParams\s*\(",
    ]
    
    # 遍历lib目录下的所有文件
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        
                        # 移除注释
                        content_without_comments = remove_comments(content)
                        
                        # 使用所有模式进行匹配
                        for pattern in patterns:
                            matches = re.findall(pattern, content_without_comments, re.DOTALL | re.MULTILINE)
                            for match in matches:
                                translation_keys.add(match)
                except Exception as e:
                    print(f"处理文件 {file_path} 时出错: {e}")
    
    return sorted(list(translation_keys))

def main():
    # 获取项目根目录 - 修改以适应tools/findtr目录结构
    script_dir = os.path.dirname(os.path.abspath(__file__))  # findtr目录
    tools_dir = os.path.dirname(script_dir)  # tools目录
    project_dir = os.path.dirname(tools_dir)  # 项目根目录
    lib_dir = os.path.join(project_dir, 'lib')
    
    if not os.path.exists(lib_dir):
        print(f"错误: lib目录不存在于 {lib_dir}")
        sys.exit(1)
    
    # 查找所有翻译键
    translation_keys = find_translation_keys(lib_dir)
    
    # 输出结果到文本文件
    output_file = os.path.join(script_dir, 'findtr.txt')
    with open(output_file, 'w', encoding='utf-8') as f:
        for key in translation_keys:
            f.write(f"{key}\n")
    
    print(f"找到 {len(translation_keys)} 个翻译键，已保存到 {output_file}")

if __name__ == "__main__":
    main() 