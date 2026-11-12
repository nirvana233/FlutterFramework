#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re

STRING_PATTERN = re.compile(
    r'"""\~(.*?)"""|\'\'\'\~(.*?)\'\'\'|"\~((?:\\.|[^"\\\n\r])*)"|\'\~((?:\\.|[^\'\\\n\r])*)\'',
    re.DOTALL,
)


def unescape_dart_string_text(text):
    """还原脚本关心的 Dart 字符串引号转义。"""
    return text.replace(r"\'", "'").replace(r'\"', '"')


def log(message):
    """统一输出入口，方便按需收敛日志。"""
    print(message)


def load_language_mappings(txt_file):
    """从find_already_in_excel.txt加载语言映射
    格式: 英文文本    key (使用多个空格或制表符分隔)
    """
    mappings = {}
    try:
        with open(txt_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                
                # 使用正则表达式分割，支持多个空格或制表符
                parts = re.split(r'\s{2,}|\t+', line)
                if len(parts) >= 2:
                    # 第一部分是英文文本，最后一部分是key
                    english_text = parts[0].strip()
                    key = parts[-1].strip()
                    if english_text and key:
                        mappings[english_text] = key
        
        return mappings
    except FileNotFoundError:
        log(f"错误: 找不到文件 {txt_file}")
        return {}
    except Exception as e:
        log(f"读取语言文件时出错: {e}")
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
        needs_trparams = []  # 含参数占位符但未写 .trParams 的情况
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

                    # 跳过空字符串
                    if not text_content.strip():
                        continue

                    if text_content in mappings:
                        # 找到映射，准备替换
                        key = mappings[text_content]

                        # 检查是否包含参数占位符（@param1, @param2 等）
                        has_params = bool(re.search(r'@param\d+', text_content))

                        # 检查当前字符串后面是否已经带了翻译方法（.tr / .trParams / .trArgs）
                        # 同时检查下一行（处理换行情况，如字符串后换行接 .trParams(...)）
                        suffix_text = current_line[match.end():]
                        next_line_text = lines[line_num + 1].lstrip() if line_num + 1 < len(lines) else ''
                        has_tr_already = bool(
                            re.match(r'^\s*\.(tr|trParams|trArgs)\b', suffix_text) or
                            re.match(r'^\.(tr|trParams|trArgs)\b', next_line_text)
                        )

                        if has_tr_already:
                            # 已经有翻译方法，只替换 key，保留原有后缀
                            replacement = f"'{key}'"
                        elif has_params:
                            # 有参数占位符但没写翻译方法，只换 key，需开发者手动补 .trParams
                            replacement = f"'{key}'"
                            needs_trparams.append((file_path, line_num + 1, key, text_content))
                        else:
                            # 普通文本且没有翻译方法，自动补上 .tr
                            replacement = f"'{key}'.tr"

                        # 记录需要添加的注释
                        if text_content not in [c[1] for c in comments_to_add]:
                            comments_to_add.append((full_match, text_content))

                        # 执行替换
                        start, end = match.span()
                        current_line = current_line[:start] + replacement + current_line[end:]
                        replacements_made += 1
                        line_modified = True
                        log(f"    第 {line_num + 1} 行替换: {full_match} -> {replacement}")
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
            log(f"  文件已更新，共进行了 {replacements_made} 次替换")

        return not_found_strings, replacements_made, needs_trparams

    except Exception as e:
        log(f"处理文件 {file_path} 时出错: {e}")
        return [], 0, []

def find_dart_files(root_dir, ignore_dirs=None):
    """递归查找所有Dart文件，忽略指定目录"""
    dart_files = []
    ignore_dir_paths = [os.path.abspath(d) for d in (ignore_dirs or [])]

    for root, dirs, files in os.walk(root_dir):
        abs_root = os.path.abspath(root)

        # 忽略指定目录（含子目录）
        if any(abs_root == d or abs_root.startswith(d + os.sep) for d in ignore_dir_paths):
            dirs[:] = []
            continue

        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    return dart_files

def main():
    """主函数"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    txt_file = os.path.join(script_dir, 'find_already_in_excel.txt')
    
    # 获取项目根目录（向上两级）
    project_root = os.path.dirname(os.path.dirname(script_dir))
    lib_dir = os.path.join(project_root, 'lib')
    
    # 检查必要的文件和目录
    if not os.path.exists(txt_file):
        log(f"错误: 语言文件不存在 {txt_file}")
        return
    
    if not os.path.exists(lib_dir):
        log(f"错误: lib目录不存在 {lib_dir}")
        return
    
    # 加载语言映射
    mappings = load_language_mappings(txt_file)
    if not mappings:
        log("没有加载到任何语言映射，退出")
        return
    
    # 查找所有Dart文件
    ignore_dirs = [os.path.join(lib_dir, 'Common/Debug')]
    dart_files = find_dart_files(lib_dir, ignore_dirs)

    # 查找所有Dart文件
    log(f"找到 {len(dart_files)} 个Dart文件（已排除 {ignore_dirs}）")
    log("-" * 50)
    
    # 处理每个文件
    all_not_found = set()
    all_needs_trparams = []
    total_replacements = 0
    files_modified = 0

    for dart_file in dart_files:
        rel_path = os.path.relpath(dart_file, project_root)
        log(f"处理文件: {rel_path}")

        not_found, replacements, needs_trparams = process_dart_file(dart_file, mappings)
        if replacements > 0:
            files_modified += 1
        total_replacements += replacements
        all_not_found.update(not_found)
        all_needs_trparams.extend(needs_trparams)

        if not replacements:
            log("  没有找到需要替换的内容")
        log("")

    # 总结
    log("=" * 50)
    log("处理完成！")
    log(f"修改了 {files_modified} 个文件")
    log(f"总共进行了 {total_replacements} 次替换")

    if all_needs_trparams:
        log(f"\n⚠️  以下 {len(all_needs_trparams)} 处含参数占位符，需手动补 .trParams({{...}}):")
        for fpath, lineno, key, original in all_needs_trparams:
            rel = os.path.relpath(fpath, project_root)
            log(f"  {rel}:{lineno}  '{key}'  // 原文: {original}")

    if all_not_found:
        log(f"\n以下 {len(all_not_found)} 个字符串在find_already_in_excel.txt中未找到对应的key:")
        for text in sorted(all_not_found):
            log(f"  '~{text}'")
    else:
        log("\n所有字符串都找到了对应的映射!")

if __name__ == "__main__":
    main()
