#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys

STRING_PATTERN = re.compile(
    r'"""\~(.*?)"""|\'\'\'\~(.*?)\'\'\'|"\~((?:\\.|[^"\\\n\r])*)"|\'\~((?:\\.|[^\'\\\n\r])*)\'',
    re.DOTALL,
)


def unescape_dart_string_text(text):
    """还原脚本关心的 Dart 字符串引号转义。"""
    return text.replace(r"\'", "'").replace(r'\"', '"')


def load_language_mappings(lan_file):
    """从lan.txt加载语言映射"""
    mappings = {}
    try:
        with open(lan_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and '\t' in line:
                    parts = line.split('\t', 1)
                    if len(parts) == 2:
                        key, value = parts
                        mappings[value.strip()] = key.strip()
        print(f"加载了 {len(mappings)} 个语言映射")
        return mappings
    except FileNotFoundError:
        print(f"错误: 找不到文件 {lan_file}")
        return {}
    except Exception as e:
        print(f"读取语言文件时出错: {e}")
        return {}

def has_get_import(content):
    """检查文件是否已经导入了get"""
    import_patterns = [
        r"import\s+['\"]package:get/get\.dart['\"]",
        r"import\s+['\"]package:get/.*['\"]"
    ]
    
    for pattern in import_patterns:
        if re.search(pattern, content):
            return True
    return False

def add_get_import(content):
    """在文件开头添加get导入"""
    # 找到最后一个import语句的位置
    import_pattern = r"^import\s+['\"][^'\"]*['\"];?\s*$"
    lines = content.split('\n')
    
    last_import_index = -1
    for i, line in enumerate(lines):
        if re.match(import_pattern, line.strip()):
            last_import_index = i
    
    if last_import_index != -1:
        # 在最后一个import后添加get导入
        lines.insert(last_import_index + 1, "import 'package:get/get.dart';")
        print("  添加了 get 导入")
        return '\n'.join(lines)
    else:
        # 如果没有找到import语句，在文件开头添加
        return "import 'package:get/get.dart';\n\n" + content

def process_dart_file(file_path, mappings):
    """处理单个Dart文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        original_lines = lines.copy()
        not_found_strings = []
        replacements_made = 0
        new_lines = []
        
        for line_num, line in enumerate(lines):
            line_modified = False
            current_line = line
            comments_to_add = []
            
            # 检查当前行是否包含需要替换的文本
            matches = list(STRING_PATTERN.finditer(current_line))
            if matches:
                # 从后往前替换，避免位置偏移问题
                for match in reversed(matches):
                    full_match = match.group(0)
                    text_content = next((group for group in match.groups() if group), '')
                    text_content = unescape_dart_string_text(text_content)

                    if text_content in mappings:
                        # 找到映射，准备替换
                        key = mappings[text_content]

                        # 检查是否包含参数占位符（@param1, @param2 等）
                        has_params = bool(re.search(r'@param\d+', text_content))

                        # 确定替换后的文本
                        start, end = match.span()
                        # 检查后面是否已经写了 .tr
                        already_has_tr = current_line[end:end+3] == '.tr'

                        if has_params:
                            replacement = f"'{key}'"
                        else:
                            if already_has_tr:
                                # 如果原来的代码已经写了 .tr，这里就只替换 key 部分
                                replacement = f"'{key}'"
                            else:
                                # 如果原来没写，才需要加上 .tr
                                replacement = f"'{key}'.tr"

                        # 记录需要添加的注释
                        if text_content not in [c[1] for c in comments_to_add]:
                            comments_to_add.append((full_match, text_content))

                        # 执行替换
                        current_line = current_line[:start] + replacement + current_line[end:]
                        replacements_made += 1
                        line_modified = True
                        print(f"    替换: {full_match} -> {replacement}")
                    else:
                        # 记录未找到的字符串
                        if text_content not in not_found_strings:
                            not_found_strings.append(text_content)
            
            # 如果有替换，添加注释
            if line_modified and comments_to_add:
                # 获取当前行的缩进
                indent = len(line) - len(line.lstrip())
                indent_str = line[:indent]
                
                # 为每个被替换的文本添加注释
                for full_match, text_content in comments_to_add:
                    comment = f"{indent_str}// {text_content}\n"
                    new_lines.append(comment)
            
            # 添加当前行（可能已经被修改）
            new_lines.append(current_line)
        
        # 重新构建文件内容
        content = ''.join(new_lines)
        
        # 如果有替换且文件没有get导入，则添加导入
        if replacements_made > 0 and not has_get_import(content):
            content = add_get_import(content)
        
        # 如果有修改，写回文件
        if new_lines != original_lines or replacements_made > 0:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  文件已更新，共进行了 {replacements_made} 次替换")
        
        return not_found_strings, replacements_made
        
    except Exception as e:
        print(f"处理文件 {file_path} 时出错: {e}")
        return [], 0

def find_dart_files(root_dir):
    """递归查找所有Dart文件"""
    dart_files = []
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def main():
    """主函数"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    lan_file = os.path.join(script_dir, 'lan.txt')
    
    # 获取项目根目录（向上三级）
    project_root = os.path.dirname(os.path.dirname(os.path.dirname(script_dir)))
    lib_dir = os.path.join(project_root, 'lib')
    
    print(f"脚本目录: {script_dir}")
    print(f"项目根目录: {project_root}")
    print(f"lib目录: {lib_dir}")
    print(f"语言文件: {lan_file}")
    print("-" * 50)
    
    # 检查必要的文件和目录
    if not os.path.exists(lan_file):
        print(f"错误: 语言文件不存在 {lan_file}")
        return
    
    if not os.path.exists(lib_dir):
        print(f"错误: lib目录不存在 {lib_dir}")
        return
    
    # 加载语言映射
    mappings = load_language_mappings(lan_file)
    if not mappings:
        print("没有加载到任何语言映射，退出")
        return
    
    # 查找所有Dart文件
    dart_files = find_dart_files(lib_dir)
    print(f"找到 {len(dart_files)} 个Dart文件")
    print("-" * 50)
    
    # 处理每个文件
    all_not_found = set()
    total_replacements = 0
    
    for dart_file in dart_files:
        rel_path = os.path.relpath(dart_file, project_root)
        print(f"处理文件: {rel_path}")
        
        not_found, replacements = process_dart_file(dart_file, mappings)
        total_replacements += replacements
        all_not_found.update(not_found)
        
        if not replacements:
            print("  没有找到需要替换的内容")
        print()
    
    # 总结
    print("=" * 50)
    print(f"处理完成！总共进行了 {total_replacements} 次替换")
    
    if all_not_found:
        print(f"\n以下 {len(all_not_found)} 个字符串在lan.txt中未找到对应的key:")
        for text in sorted(all_not_found):
            print(f"  '{text}'")
    else:
        print("\n所有字符串都找到了对应的映射!")

if __name__ == "__main__":
    main()
