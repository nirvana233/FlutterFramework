#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys
from pathlib import Path

def load_replacement_rules(str_file_path):
    """从str.txt文件加载替换规则"""
    replacement_rules = {}
    
    with open(str_file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            # 解析格式：左边文本\t右边文本
            parts = line.split('\t')
            if len(parts) == 2:
                old_text = parts[0].strip()
                new_text = parts[1].strip()
                
                # 只有当左右文本不同时才添加到替换规则
                if old_text != new_text:
                    replacement_rules[old_text] = new_text
    
    return replacement_rules

def find_dart_files(lib_dir, ignore_file, ignore_dirs):
    """遍历lib目录下的所有dart文件，忽略指定文件和指定目录"""
    dart_files = []
    ignore_file_path = os.path.abspath(ignore_file)
    ignore_dir_paths = [os.path.abspath(d) for d in ignore_dirs]

    for root, dirs, files in os.walk(lib_dir):
        abs_root = os.path.abspath(root)

        # 忽略指定目录（含子目录）
        if any(abs_root == d or abs_root.startswith(d + os.sep) for d in ignore_dir_paths):
            dirs[:] = []
            continue

        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                abs_file_path = os.path.abspath(file_path)

                # 忽略MyLocalization.dart文件
                if abs_file_path != ignore_file_path:
                    dart_files.append(file_path)

    return dart_files

def replace_text_in_file(file_path, replacement_rules):
    """在文件中进行文本替换"""
    replacements_made = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        for old_text, new_text in replacement_rules.items():
            # 创建正则表达式，匹配单引号或双引号包围的文本
            # 匹配 '~old_text' 或 "~old_text"
            pattern1 = rf"'~{re.escape(old_text)}'"
            pattern2 = rf'"~{re.escape(old_text)}"'
            
            replacement1 = f"'~{new_text}'"
            replacement2 = f'"~{new_text}"'
            
            # 替换单引号版本
            if re.search(pattern1, content):
                content = re.sub(pattern1, replacement1, content)
                replacements_made.append((old_text, new_text))
            
            # 替换双引号版本
            if re.search(pattern2, content):
                content = re.sub(pattern2, replacement2, content)
                # 避免重复记录同一个替换
                if (old_text, new_text) not in replacements_made:
                    replacements_made.append((old_text, new_text))
        
        # 如果内容有变化，写回文件
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        
        return replacements_made
    
    except Exception as e:
        print(f"处理文件 {file_path} 时出错: {e}")
        return []

def main():
    # 设置路径
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.join(script_dir, '../../..')
    lib_dir = os.path.join(project_root, 'lib')
    str_file = os.path.join(script_dir, 'str.txt')
    ignore_file = os.path.join(lib_dir, 'Util/Translations/MyLocalization.dart')
    ignore_dirs = [os.path.join(lib_dir, 'Common/Debug')]
    output_file = os.path.join(script_dir, 'replaced.txt')

    print(f"项目根目录: {project_root}")
    print(f"lib目录: {lib_dir}")
    print(f"规则文件: {str_file}")
    print(f"忽略文件: {ignore_file}")
    print(f"忽略目录: {ignore_dirs}")
    print(f"输出文件: {output_file}")
    
    # 检查必要文件是否存在
    if not os.path.exists(lib_dir):
        print(f"错误: lib目录不存在: {lib_dir}")
        return
    
    if not os.path.exists(str_file):
        print(f"错误: str.txt文件不存在: {str_file}")
        return
    
    # 加载替换规则
    print("\n加载替换规则...")
    replacement_rules = load_replacement_rules(str_file)
    print(f"加载了 {len(replacement_rules)} 条替换规则")
    
    # 查找所有dart文件
    print("\n查找dart文件...")
    dart_files = find_dart_files(lib_dir, ignore_file, ignore_dirs)
    print(f"找到 {len(dart_files)} 个dart文件")
    
    # 处理每个文件并记录替换结果
    all_replacements = []
    processed_files = 0
    
    print("\n开始处理文件...")
    for file_path in dart_files:
        replacements = replace_text_in_file(file_path, replacement_rules)
        if replacements:
            processed_files += 1
            for old_text, new_text in replacements:
                all_replacements.append({
                    'file': file_path,
                    'old': old_text,
                    'new': new_text
                })
    
    # 输出替换结果到文件
    with open(output_file, 'w', encoding='utf-8') as f:
        for replacement in all_replacements:
            f.write(f"File: {replacement['file']}\n")
            f.write(f"Old: {replacement['old']}\n")
            f.write(f"New: {replacement['new']}\n")
            f.write("\n")
    
    print(f"\n处理完成!")
    print(f"处理了 {processed_files} 个文件")
    print(f"总共进行了 {len(all_replacements)} 次替换")
    print(f"结果已保存到: {output_file}")

if __name__ == "__main__":
    main()
