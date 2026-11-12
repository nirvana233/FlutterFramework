#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
EXCEL多语言文件转JSON工具

将本项目的多语言Excel文件转换为多个语言的JSON文件。
每种语言会在输出目录下生成对应的JSON文件，命名格式为：序号_语言代码.json

Excel格式要求：
- 工作表名称: 可配置，默认为"client"
- 第一列: 语言key（从第3行开始有效）
- 第二列: 内容说明（仅供参考，不导出）
- 第三列及之后: 各语言的翻译内容
  - 第1行: 语言代码 (如 'en', 'es', 'zh', 等)
  - 第2行: 语言名称 (如 'English', 'Spanish', 'Chinese', 等)
  - 第3行: 语言说明 (仅供参考，不导出)
  - 第4行及之后: 实际翻译内容

注意：
- 所有翻译文本中的%s将被替换为@param1
"""

import os
import sys
import json
import argparse
import openpyxl
import shutil
import re
from pathlib import Path
from collections import defaultdict

class DuplicateKeyError(Exception):
    """当检测到重复键时抛出的异常"""
    pass

def clean_output_directory(output_dir):
    """
    清空输出目录中的所有文件和文件夹
    
    参数:
        output_dir (str): 要清空的目录路径
    """
    if os.path.exists(output_dir):
        print(f"正在清空输出目录: {output_dir}")
        for item in os.listdir(output_dir):
            item_path = os.path.join(output_dir, item)
            if os.path.isdir(item_path):
                shutil.rmtree(item_path)
            else:
                os.remove(item_path)
        print("输出目录已清空")
    else:
        print(f"输出目录不存在，将创建: {output_dir}")

def replace_format_placeholders(text):
    """
    将文本中的%s替换为@param1
    
    参数:
        text (str): 原始文本
    
    返回:
        tuple: (替换后的文本, 替换次数)
    """
    if not text or not isinstance(text, str):
        return text, 0
    
    # 计算原始字符串中%s的个数
    count = text.count('%s') + text.count('s%')
    
    # 使用正则表达式替换所有的%s
    replaced_text = re.sub(r'%s', '@param1', text)
    replaced_text = re.sub(r's%', '@param1', replaced_text)
    
    return replaced_text, count

def process_excel_to_json(excel_file, output_dir, sheet_name):
    """
    处理Excel文件并生成多语言JSON文件
    
    参数:
        excel_file (str): Excel文件路径
        output_dir (str): 输出目录路径
        sheet_name (str): 工作表名称
    
    返回:
        int: 成功生成的语言文件数量
    
    异常:
        DuplicateKeyError: 当检测到Excel中存在重复键时抛出
    """
    print(f"正在处理Excel文件: {excel_file}")
    
    # 首先清空输出目录
    clean_output_directory(output_dir)
    
    # 创建输出目录（如果不存在）
    try:
        os.makedirs(output_dir, exist_ok=True)
    except Exception as e:
        print(f"无法创建输出目录: {e}")
        return 0
    
    # 读取Excel文件
    try:
        wb = openpyxl.load_workbook(excel_file)
        
        # 确保存在指定的工作表
        if sheet_name not in wb.sheetnames:
            print(f"错误: Excel文件中不存在'{sheet_name}'工作表")
            print(f"可用的工作表: {', '.join(wb.sheetnames)}")
            return 0
        
        sheet = wb[sheet_name]
        print(f"已找到工作表: {sheet_name}")
    except Exception as e:
        print(f"无法打开Excel文件: {e}")
        return 0
    
    # 获取语言代码（第一行，从第三列开始）
    lang_codes = []
    for col in range(3, sheet.max_column + 1):
        lang_code = sheet.cell(row=1, column=col).value
        if lang_code:
            lang_codes.append(lang_code)
    
    if not lang_codes:
        print("错误: 未检测到任何语言代码，请检查Excel文件格式")
        return 0
    
    print(f"检测到 {len(lang_codes)} 种语言: {', '.join(lang_codes)}")
    
    # 为每种语言创建一个字典
    lang_data = {code: {} for code in lang_codes}
    
    # 收集所有的key并检查重复
    all_keys = []
    key_row_map = defaultdict(list)  # 用于存储每个key出现的行号
    
    for row in range(4, sheet.max_row + 1):
        key = sheet.cell(row=row, column=1).value
        if key:
            key_row_map[key].append(row)
            all_keys.append(key)
    
    # 检查并报告重复键
    duplicate_keys = [key for key, rows in key_row_map.items() if len(rows) > 1]
    if duplicate_keys:
        error_msg = "\n错误: 检测到重复的翻译键!\n"
        for key in duplicate_keys:
            rows = key_row_map[key]
            error_msg += f"  - 键 '{key}' 在以下行出现: {', '.join(str(r) for r in rows)}\n"
        error_msg += "\n请修复Excel文件中的重复键后再试。"
        raise DuplicateKeyError(error_msg)
    
    # 确保all_keys中的键不重复
    all_keys = list(key_row_map.keys())
    key_count = len(all_keys)
    print(f"找到 {key_count} 个唯一翻译键")
    
    # 统计替换次数
    total_replacements = 0
    
    # 从第四行开始处理数据
    for row in range(4, sheet.max_row + 1):
        key = sheet.cell(row=row, column=1).value  # 第一列是key
        
        # 跳过没有key的行
        if not key:
            continue
        
        # 处理每种语言的翻译
        for col_idx, code in enumerate(lang_codes):
            # 获取对应语言的翻译（第三列开始）
            value = sheet.cell(row=row, column=col_idx + 3).value  # +3 是因为从第三列开始
            
            # 将%s替换为@param
            if value and isinstance(value, str):
                value, replacements = replace_format_placeholders(value)
                total_replacements += replacements
            
            # 即使值为空，也添加为空字符串
            lang_data[code][key] = value if value is not None else ""
    
    # 将每种语言的数据写入对应的JSON文件
    success_count = 0
    for idx, (code, data) in enumerate(lang_data.items()):
        # 创建JSON文件路径 - 使用"序号_语言代码.json"的格式
        json_file = os.path.join(output_dir, f"{idx}_{code}.json")
        
        # 确保每个语言都有所有翻译键，如果缺少则添加为空字符串
        for key in all_keys:
            if key not in data:
                data[key] = ""
        
        # 统计有值的翻译数量（不包括空字符串）
        non_empty_count = sum(1 for value in data.values() if value)
        
        # 计算翻译完成率
        completion_rate = non_empty_count / key_count * 100 if key_count > 0 else 0
        
        # 将数据写入JSON文件（使用缩进美化格式）
        try:
            with open(json_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"已生成语言文件: {json_file} (包含 {non_empty_count}/{key_count} 个非空翻译, 完成率: {completion_rate:.1f}%)")
            success_count += 1
        except Exception as e:
            print(f"无法写入文件 {json_file}: {e}")
    
    # 输出替换统计信息
    print(f"将所有译文中的%s替换为@param，共替换 {total_replacements} 处")
    
    return success_count

def main():
    # 设置命令行参数解析
    parser = argparse.ArgumentParser(description='将Excel多语言文件转换为JSON文件')
    parser.add_argument('-i', '--input', default='languages.xlsx', help='输入Excel文件路径 (默认: languages.xlsx)')
    parser.add_argument('-o', '--output', default='多语言', help='输出目录路径 (默认: 多语言)')
    parser.add_argument('-s', '--sheet', default='client', help='Excel工作表名称 (默认: client)')
    args = parser.parse_args()
    
    try:
        # 处理Excel并生成JSON文件
        success_count = process_excel_to_json(args.input, args.output, args.sheet)
        
        if success_count > 0:
            print(f"所有语言文件生成完成！共生成 {success_count} 个语言文件")
        else:
            print("处理失败，未生成任何语言文件")
            sys.exit(1)
    except DuplicateKeyError as e:
        print(e)
        sys.exit(1)
    except Exception as e:
        print(f"发生错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()