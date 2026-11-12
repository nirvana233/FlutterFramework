#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import openpyxl
from openpyxl import load_workbook

def clean_localization_file():
    """
    读取findtr.txt中的翻译键和languages.xlsx文件，
    删除Excel中未被使用的键所在行
    """
    try:
        # 获取路径
        script_dir = os.path.dirname(os.path.abspath(__file__))
        tools_dir = os.path.dirname(script_dir)
        project_dir = os.path.dirname(tools_dir)
        
        # 翻译键文件
        keys_file = os.path.join(script_dir, 'findtr.txt')
        # Excel文件
        excel_file = os.path.join(tools_dir, 'localization', 'languages.xlsx')
        
        if not os.path.exists(keys_file):
            print(f"错误: 找不到翻译键文件 {keys_file}")
            return
        
        if not os.path.exists(excel_file):
            print(f"错误: 找不到Excel文件 {excel_file}")
            return
        
        # 读取翻译键
        with open(keys_file, 'r', encoding='utf-8') as f:
            used_keys = set(line.strip() for line in f.readlines())
        
        if not used_keys:
            print(f"警告: 从 {keys_file} 中没有读取到任何翻译键")
            return
            
        print(f"从 {keys_file} 中读取到 {len(used_keys)} 个有效的翻译键")
        
        # 加载Excel文件
        try:
            # 使用openpyxl直接加载，保持格式
            workbook = load_workbook(excel_file)
            sheet_names = workbook.sheetnames
            
            # 查找"client"分页
            target_sheet_name = None
            for sheet_name in sheet_names:
                if "client" in sheet_name:
                    target_sheet_name = sheet_name
                    break
            
            if not target_sheet_name:
                print("错误: 找不到'client'分页")
                return
            
            print(f"找到目标分页: {target_sheet_name}")
            sheet = workbook[target_sheet_name]
            
            # 从第4行开始处理（Excel是从1开始索引的，第4行对应索引4）
            start_row = 4
            max_row = sheet.max_row
            
            # 第一列应该包含键
            key_column = 1
            
            # 记录要删除的行
            rows_to_delete = []
            excel_keys = []
            
            print(f"开始扫描Excel文件的翻译键 (共 {max_row - start_row + 1} 行)...")
            
            # 从底部向上遍历，以便安全删除
            for row in range(max_row, start_row - 1, -1):
                key_cell = sheet.cell(row=row, column=key_column)
                key = key_cell.value
                
                if key is None:
                    continue
                    
                key = str(key).strip()
                excel_keys.append(key)
                
                if key and key not in used_keys:
                    rows_to_delete.append(row)
                    print(f"将删除未使用的键: {key} (行 {row})")
            
            if not rows_to_delete:
                print("没有找到需要删除的未使用键")
                return
                
            print(f"开始删除 {len(rows_to_delete)} 行未使用的翻译键...")
            
            # 删除行
            for row in rows_to_delete:
                sheet.delete_rows(row, 1)
            
            # 保存修改后的Excel
            backup_file = f"{excel_file}.backup"
            # 先备份原文件
            if os.path.exists(excel_file):
                import shutil
                shutil.copy2(excel_file, backup_file)
                print(f"已创建备份文件: {backup_file}")
            
            workbook.save(excel_file)
            print(f"已成功删除 {len(rows_to_delete)} 行未使用的翻译键")
            print(f"Excel中有 {len(excel_keys)} 个键，实际使用了 {len(used_keys)} 个键")
            
            # 检查是否有代码中使用但Excel中没有的键
            missing_keys = used_keys - set(excel_keys)
            if missing_keys:
                print(f"\n警告: 以下 {len(missing_keys)} 个键在代码中使用但在Excel中未定义:")
                for key in sorted(missing_keys):
                    print(f"  - {key}")
                print("\n建议添加这些缺失的键到Excel文件中")
        
        except Exception as e:
            print(f"处理Excel文件时出错: {e}")
            import traceback
            print(traceback.format_exc())
    
    except Exception as e:
        print(f"程序执行出错: {e}")
        import traceback
        print(traceback.format_exc())

if __name__ == "__main__":
    clean_localization_file() 