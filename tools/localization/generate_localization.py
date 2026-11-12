#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
JSON到Dart翻译文件生成工具

直接从JSON文件生成MyLocalization.dart文件，只包含Map<String, Map<String, String>> translations变量
不依赖于_MyTranslations.dart文件，不包含任何辅助函数
"""

import os
import sys
import json
import glob
from pathlib import Path
import re

def generate_localization_file(json_dir, output_file):
    """
    从JSON文件生成MyLocalization.dart文件
    
    参数:
        json_dir (str): JSON文件所在目录
        output_file (str): 输出的Dart文件路径
    
    返回:
        bool: 是否成功生成文件
    """
    print("开始生成本地化文件...")
    
    # 获取所有JSON文件
    json_files = glob.glob(os.path.join(json_dir, "*.json"))
    if not json_files:
        print(f"错误: 在 {json_dir} 目录中未找到JSON文件")
        return False
    
    # 按照数字顺序排序文件
    def extract_file_index(filename):
        match = re.match(r'(\d+)_([a-zA-Z]+)\.json', os.path.basename(filename))
        if match:
            return int(match.group(1))
        return 999  # 如果没有匹配到格式，放到最后
    
    json_files.sort(key=extract_file_index)
    
    print(f"找到 {len(json_files)} 个语言文件")
    
    # 加载所有JSON文件
    translations = {}
    language_codes = []
    file_names = {}  # 存储文件名与语言代码的映射
    
    for json_file in json_files:
        file_name = os.path.basename(json_file)
        match = re.match(r'(\d+)_([a-zA-Z]+)\.json', file_name)
        if match:
            index = match.group(1)
            lang_code = match.group(2)
            language_codes.append(lang_code)
            # 存储没有.json后缀的文件名
            file_names[lang_code] = f"{index}_{lang_code}"
            
            print(f"处理语言文件: {file_name}")
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    translations[lang_code] = json.load(f)
            except Exception as e:
                print(f"错误: 无法读取文件 {json_file}: {e}")
                return False
    
    if not translations:
        print("错误: 未能成功加载任何翻译数据")
        return False
    
    print(f"成功加载了 {len(translations)} 种语言")
    
    # 生成Dart文件
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            # 写入文件头部
            f.write("""// 该文件由generate_localization.py自动生成，请勿手动修改
// Generated on: ${datetime}

// 直接的多语言翻译映射
final Map<String, Map<String, String>> localizations = {
""".replace("${datetime}", import_datetime()))
            
            # 写入每种语言的翻译
            for lang_code in language_codes:
                lang_data = translations[lang_code]
                # 在语言代码上方添加文件名注释（不含.json后缀）
                f.write(f'  // {file_names[lang_code]}\n')
                f.write(f'  "{lang_code}": {{\n')
                
                # 写入该语言的所有键值对
                for key, value in lang_data.items():
                    # 转义特殊字符
                    escaped_value = escape_string(value)
                    f.write(f'    "{key}": "{escaped_value}",\n')
                
                f.write('  },\n')
            
            # 写入文件尾部
            f.write("""};
""")
    
    except Exception as e:
        print(f"错误: 无法写入输出文件 {output_file}: {e}")
        return False
    
    print(f"翻译文件已成功生成: {output_file}")
    return True

def import_datetime():
    """返回当前日期时间字符串"""
    from datetime import datetime
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def escape_string(s):
    """转义字符串中的特殊字符"""
    if s is None:
        return ""
    
    # 将字符串中的特殊字符转义
    result = str(s)
    result = result.replace('\\', '\\\\')  # 必须首先处理反斜杠
    result = result.replace('"', '\\"')
    result = result.replace('$', '\\$')
    result = result.replace('\n', '\\n')
    result = result.replace('\r', '\\r')
    result = result.replace('\t', '\\t')
    return result

def main():
    # 默认参数
    json_dir = "多语言"
    # 修改默认输出路径为项目中的实际位置
    output_file = "../../lib/Util/Translations/MyLocalization.dart"
    
    # 检查命令行参数
    if len(sys.argv) > 1:
        json_dir = sys.argv[1]
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    
    # 确保JSON目录存在
    if not os.path.exists(json_dir):
        print(f"错误: 目录 {json_dir} 不存在")
        sys.exit(1)
    
    # 确保输出目录存在
    output_dir = os.path.dirname(output_file)
    if output_dir and not os.path.exists(output_dir):
        print(f"创建输出目录: {output_dir}")
        os.makedirs(output_dir, exist_ok=True)
    
    # 生成文件
    if generate_localization_file(json_dir, output_file):
        print("本地化文件生成成功！")
    else:
        print("生成本地化文件失败")
        sys.exit(1)

if __name__ == "__main__":
    main() 