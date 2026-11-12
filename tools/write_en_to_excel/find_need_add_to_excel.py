#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from pathlib import Path
import openpyxl
from openpyxl import load_workbook
from openpyxl.utils.exceptions import InvalidFileException

def read_tags_from_file(file_path):
    """读取文本文件中的标签内容"""
    tags = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            tags = [line.strip() for line in f.readlines() if line.strip()]
        return tags
    except Exception as e:
        print(f"读取文件时出错: {e}")
        return []

def find_excel_file(directory):
    """查找目录中的Excel文件"""
    excel_files = []
    for file in os.listdir(directory):
        if file.endswith(('.xlsx', '.xls')):
            excel_files.append(os.path.join(directory, file))
    
    if not excel_files:
        return None
    
    # 如果找到多个，让用户选择
    if len(excel_files) > 1:
        print("找到多个Excel文件:")
        for i, file in enumerate(excel_files):
            print(f"{i+1}. {os.path.basename(file)}")
        choice = input("请选择要使用的文件 (输入数字): ")
        try:
            index = int(choice) - 1
            if 0 <= index < len(excel_files):
                return excel_files[index]
        except ValueError:
            pass
        return None
    else:
        return excel_files[0]

def extract_missing_en_tags(excel_file, tags):
    """从Excel文件中提取不存在的标签和已存在的标签"""
    try:
        # 尝试使用openpyxl加载工作簿
        try:
            workbook = load_workbook(excel_file)
        except InvalidFileException:
            print(f"无法打开Excel文件: {excel_file}")
            return [], []
        
        # 获取所有工作表
        sheet_names = workbook.sheetnames
        
        if not sheet_names:
            print("Excel文件中没有工作表")
            return [], []
        
        # 直接使用"client"工作表
        sheet_name = "client"
        if sheet_name in sheet_names:
            active_sheet = workbook[sheet_name]
            print(f"使用工作表: {sheet_name}")
        else:
            print(f"找不到'{sheet_name}'工作表，可用工作表:")
            for i, name in enumerate(sheet_names):
                print(f"{i+1}. {name}")
            
            choice = input("请选择要查询的工作表 (输入数字): ")
            try:
                index = int(choice) - 1
                if 0 <= index < len(sheet_names):
                    active_sheet = workbook[sheet_names[index]]
                else:
                    active_sheet = workbook.active
            except ValueError:
                active_sheet = workbook.active
            
        if not active_sheet:
            print("无法获取工作表")
            return [], []
        
        # 查找en列的索引
        en_col_index = None
        for col in range(1, active_sheet.max_column + 1):
            header = active_sheet.cell(row=1, column=col).value
            if header and header.lower() == 'en':
                en_col_index = col
                break
        
        if not en_col_index:
            print("未找到'en'列")
            return tags, []  # 如果没找到en列，返回所有标签作为缺失标签，空列表作为已存在标签
        
        # 获取key列的索引（第一列）
        key_col_index = 1
        
        # 获取en列中已有的值和对应的key
        existing_values = {}  # value -> key 的映射
        for row in range(2, active_sheet.max_row + 1):
            key_value = active_sheet.cell(row=row, column=key_col_index).value
            en_value = active_sheet.cell(row=row, column=en_col_index).value
            if en_value and key_value:
                existing_values[en_value] = key_value
        
        # 找出缺失的标签和已存在的标签
        missing_tags = []
        existing_tags = []  # 存储 (en_value, key_value) 元组
        for tag in tags:
            if tag not in existing_values:
                missing_tags.append(tag)
            else:
                existing_tags.append((tag, existing_values[tag]))
        
        return missing_tags, existing_tags
        
    except Exception as e:
        print(f"读取Excel文件时出错: {e}")
        return [], []

def main():
    # 获取脚本路径
    script_path = Path(__file__).resolve().parent
    project_root = script_path.parent.parent
    
    # 标签文件路径
    tags_file = os.path.join(script_path, 'find_mutil_language.txt')
    
    if not os.path.exists(tags_file):
        print(f"错误: 找不到标签文件: {tags_file}")
        sys.exit(1)
    
    # 读取标签
    tags = read_tags_from_file(tags_file)
    
    if not tags:
        print("没有找到标签或标签文件为空")
        sys.exit(1)
    
    print(f"从文件中读取了 {len(tags)} 个标签")
    
    # 使用指定的Excel文件
    excel_file = os.path.join(project_root, 'tools/localization/languages.xlsx')
    
    if not os.path.exists(excel_file):
        print(f"错误: 找不到Excel文件: {excel_file}")
        sys.exit(1)
    
    print(f"使用Excel文件: {excel_file}")
    
    # 提取Excel中不存在的标签和已存在的标签
    missing_tags, existing_tags = extract_missing_en_tags(excel_file, tags)
    
    # 输出需要添加到Excel的标签到文件
    missing_output_file = os.path.join(script_path, 'find_need_add_to_excel.txt')
    with open(missing_output_file, 'w', encoding='utf-8') as f:
        if missing_tags:
            f.write('\n'.join(missing_tags))
    
    # 输出已存在于Excel的标签到文件（格式：en_value    key_value）
    existing_output_file = os.path.join(script_path, 'find_already_in_excel.txt')
    with open(existing_output_file, 'w', encoding='utf-8') as f:
        if existing_tags:
            lines = []
            for en_value, key_value in existing_tags:
                lines.append(f"{en_value}    {key_value}")
            f.write('\n'.join(lines))
    
    print(f"找到 {len(missing_tags)} 个在Excel中不存在的标签")
    print(f"找到 {len(existing_tags)} 个已存在于Excel中的标签")
    print(f"需要添加的标签已保存到: {missing_output_file}")
    print(f"已存在的标签已保存到: {existing_output_file}")

if __name__ == "__main__":
    main()
