#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys
from pathlib import Path

def find_novel_time_tags(root_dir, ignore_dirs=None):
    """
    遍历指定目录下所有文件，查找@标签内容，并返回匹配结果列表
    """
    results = []
    # 优先匹配三引号字符串，再匹配普通单双引号字符串。
    # 普通字符串允许转义字符，避免 "~Couldn\'t..." 这类文案被截断。
    pattern = re.compile(
        r'"""\~(.*?)"""|\'\'\'\~(.*?)\'\'\'|"\~((?:\\.|[^"\\\n\r])*)"|\'\~((?:\\.|[^\'\\\n\r])*)\'',
        re.DOTALL,
    )
    ignore_dir_paths = [os.path.abspath(d) for d in (ignore_dirs or [])]

    # 遍历所有文件
    for root, dirs, files in os.walk(root_dir):
        abs_root = os.path.abspath(root)

        # 忽略指定目录（含子目录）
        if any(abs_root == d or abs_root.startswith(d + os.sep) for d in ignore_dir_paths):
            dirs[:] = []
            continue

        for file in files:
            file_path = os.path.join(root, file)
            # 跳过.DS_Store和其他非文本文件
            if file.endswith(('.dart')):
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # 查找所有匹配
                    matches = pattern.findall(content)
                    for match in matches:
                        # match是一个元组，包含多个捕获组，只有一个会有内容
                        text = next((group for group in match if group), '')
                        text = text.replace(r"\'", "'").replace(r'\"', '"')
                        if text and text not in results:
                            results.append(text)
                except Exception as e:
                    print(f"读取文件 {file_path} 时出错: {e}")
    
    return results

def main():
    # 获取脚本所在目录的上两级目录，即项目根目录
    script_path = Path(__file__).resolve()
    project_root = script_path.parent.parent.parent
    
    # lib目录路径
    lib_dir = os.path.join(project_root, 'lib')
    
    if not os.path.exists(lib_dir):
        print(f"错误: 无法找到lib目录: {lib_dir}")
        sys.exit(1)
    
    # 查找所有匹配内容
    ignore_dirs = [os.path.join(lib_dir, 'Common/Debug')]
    print(f"正在扫描目录: {lib_dir}")
    print(f"忽略目录: {ignore_dirs}")
    matches = find_novel_time_tags(lib_dir, ignore_dirs)
    
    # 输出到文件
    output_file = os.path.join(script_path.parent, 'find_mutil_language.txt')
    with open(output_file, 'w', encoding='utf-8') as f:
        for match in matches:
            f.write(f"{match}\n")
    
    print(f"共找到 {len(matches)} 个匹配项")
    print(f"结果已保存到: {output_file}")

if __name__ == "__main__":
    main()
