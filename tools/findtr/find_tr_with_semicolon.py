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

def find_tr_variables_with_semicolon(lib_path):
    """
    在指定路径下查找所有形如 变量.tr; 的模式，包括赋值表达式中的
    """
    tr_variables = set()
    file_matches = {}
    
    # 定义匹配 变量.tr; 的正则表达式 - 匹配所有以分号结尾的情况
    # 不要匹配引号包裹的字符串.tr
    pattern = r'(?<![\'"])(\w+)\.tr\s*;'
    
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
                        
                        # 使用正则表达式查找所有匹配
                        matches = re.findall(pattern, content_without_comments)
                        
                        # 如果找到匹配，保存文件路径和匹配内容
                        if matches:
                            file_matches[file_path] = []
                            for match in matches:
                                # 在原始内容中查找该匹配，获取上下文
                                match_with_context = re.search(r'.{0,40}' + re.escape(match) + r'\.tr\s*;.{0,40}', content_without_comments)
                                if match_with_context:
                                    context = match_with_context.group(0)
                                    file_matches[file_path].append((match, context))
                                tr_variables.add(match + '.tr;')
                            
                except Exception as e:
                    print(f"处理文件 {file_path} 时出错: {e}")
    
    # 按文件路径排序并打印结果
    for file_path in sorted(file_matches.keys()):
        print(f"在文件 {file_path} 中找到匹配:")
        for match, context in file_matches[file_path]:
            print(f"  - {match}.tr; (上下文: ...{context}...)")
    
    return sorted(list(tr_variables))

def main():
    # 获取项目根目录 - 适应tools/findtr目录结构
    script_dir = os.path.dirname(os.path.abspath(__file__))  # findtr目录
    tools_dir = os.path.dirname(script_dir)  # tools目录
    project_dir = os.path.dirname(tools_dir)  # 项目根目录
    lib_dir = os.path.join(project_dir, 'lib')
    
    if not os.path.exists(lib_dir):
        print(f"错误: lib目录不存在于 {lib_dir}")
        sys.exit(1)
    
    # 查找所有变量.tr;模式
    tr_variables = find_tr_variables_with_semicolon(lib_dir)
    
    # 输出结果到文本文件
    output_file = os.path.join(script_dir, 'tr_with_semicolon.txt')
    with open(output_file, 'w', encoding='utf-8') as f:
        for var in tr_variables:
            f.write(f"{var}\n")
    
    print(f"找到 {len(tr_variables)} 个以分号结尾的变量.tr;模式，已保存到 {output_file}")

if __name__ == "__main__":
    main() 