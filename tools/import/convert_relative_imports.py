#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
相对路径import转绝对路径脚本
将lib目录下所有使用相对路径导入的import改成绝对路径

使用方法:
python convert_relative_imports.py

作者: AI Assistant
"""

import os
import re
import sys
from pathlib import Path

def get_package_name(project_root):
    """从 pubspec.yaml 读取 package 名（name 字段）"""
    pubspec = os.path.join(project_root, 'pubspec.yaml')
    with open(pubspec, 'r', encoding='utf-8') as f:
        for line in f:
            match = re.match(r"^name:\s*([A-Za-z0-9_]+)", line)
            if match:
                return match.group(1)
    raise RuntimeError('pubspec.yaml 中未找到 name 字段')

PACKAGE_NAME = None

def get_relative_path_from_lib(file_path, lib_root):
    """获取文件相对于lib目录的路径"""
    return os.path.relpath(file_path, lib_root)

def resolve_relative_import(current_file_path, relative_import, lib_root):
    """解析相对路径导入，转换为绝对路径"""
    # 获取当前文件所在目录
    current_dir = os.path.dirname(current_file_path)
    
    # 解析相对路径
    if relative_import.startswith('../'):
        # 处理 ../xxx 形式的相对路径
        target_path = os.path.normpath(os.path.join(current_dir, relative_import))
    elif relative_import.startswith('./'):
        # 处理 ./xxx 形式的相对路径
        target_path = os.path.normpath(os.path.join(current_dir, relative_import[2:]))
    else:
        # 处理直接的相对路径
        target_path = os.path.normpath(os.path.join(current_dir, relative_import))
    
    # 确保路径在lib目录内
    if not target_path.startswith(lib_root):
        return None
    
    # 转换为相对于lib的路径
    relative_to_lib = os.path.relpath(target_path, lib_root)
    
    # 转换为包路径格式
    package_path = relative_to_lib.replace(os.sep, '/')
    
    # 移除.dart扩展名
    if package_path.endswith('.dart'):
        package_path = package_path[:-5]
    
    return f"package:{PACKAGE_NAME}/{package_path}.dart"

def process_dart_file(file_path, lib_root):
    """处理单个Dart文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        lines = content.split('\n')
        modified_lines = []
        changes_made = False
        
        # 正则表达式匹配相对路径的import
        import_pattern = re.compile(r"^(\s*import\s+['\"])(\.\./.*?|\./.+?|(?!package:)[^/'\"][^'\"]*?)(['\"];?.*)$")
        
        for line_num, line in enumerate(lines, 1):
            match = import_pattern.match(line)
            if match:
                prefix = match.group(1)  # import '
                relative_path = match.group(2)  # 相对路径部分
                suffix = match.group(3)  # '; 或其他后缀
                
                # 跳过已经是绝对路径的import
                if relative_path.startswith('package:') or relative_path.startswith('dart:'):
                    modified_lines.append(line)
                    continue
                
                # 解析相对路径
                absolute_path = resolve_relative_import(file_path, relative_path, lib_root)
                
                if absolute_path:
                    new_line = f"{prefix}{absolute_path}{suffix}"
                    modified_lines.append(new_line)
                    changes_made = True
                    print(f"  {os.path.relpath(file_path, lib_root)}:{line_num}")
                    print(f"    - {line.strip()}")
                    print(f"    + {new_line.strip()}")
                else:
                    modified_lines.append(line)
            else:
                modified_lines.append(line)
        
        # 如果有修改，写回文件
        if changes_made:
            new_content = '\n'.join(modified_lines)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
        
        return False
        
    except Exception as e:
        print(f"处理文件 {file_path} 时出错: {e}")
        return False

def find_dart_files(lib_root):
    """查找lib目录下所有的Dart文件"""
    dart_files = []
    for root, dirs, files in os.walk(lib_root):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def main():
    """主函数"""
    # 获取项目根目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(os.path.dirname(script_dir))
    lib_root = os.path.join(project_root, 'lib')
    global PACKAGE_NAME
    PACKAGE_NAME = get_package_name(project_root)
    
    print(f"项目根目录: {project_root}")
    print(f"lib目录: {lib_root}")
    
    if not os.path.exists(lib_root):
        print(f"错误: lib目录不存在 {lib_root}")
        sys.exit(1)
    
    # 查找所有Dart文件
    dart_files = find_dart_files(lib_root)
    print(f"\n找到 {len(dart_files)} 个Dart文件")
    
    # 处理每个文件
    total_modified = 0
    for file_path in dart_files:
        if process_dart_file(file_path, lib_root):
            total_modified += 1
    
    print(f"\n处理完成!")
    print(f"总共处理了 {len(dart_files)} 个文件")
    print(f"修改了 {total_modified} 个文件")
    
    if total_modified > 0:
        print("\n建议运行以下命令检查语法:")
        print("flutter analyze")

if __name__ == "__main__":
    main() 