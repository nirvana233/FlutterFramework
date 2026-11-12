#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图片引用检查工具
检查指定目录或图片文件是否在项目的lib目录中被引用
如果未找到引用，则输出图片路径
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List, Set

# 支持的图片扩展名
IMAGE_EXTENSIONS = {'.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.bmp'}

def get_image_files(path: str) -> List[Path]:
    """
    获取指定路径下的所有图片文件
    
    Args:
        path: 文件或目录路径
        
    Returns:
        图片文件路径列表
    """
    path_obj = Path(path)
    image_files = []
    
    if not path_obj.exists():
        print(f"错误: 路径不存在: {path}")
        return image_files
    
    if path_obj.is_file():
        # 如果是文件，检查是否为图片
        if path_obj.suffix.lower() in IMAGE_EXTENSIONS:
            image_files.append(path_obj)
        else:
            print(f"警告: {path} 不是支持的图片格式")
    else:
        # 如果是目录，递归查找所有图片
        for ext in IMAGE_EXTENSIONS:
            image_files.extend(path_obj.rglob(f'*{ext}'))
    
    return image_files

def search_in_dart_files(lib_path: str, image_name: str) -> bool:
    """
    在lib目录的所有Dart文件中搜索图片名称
    
    Args:
        lib_path: lib目录路径
        image_name: 图片文件名
        
    Returns:
        是否找到引用
    """
    lib_path_obj = Path(lib_path)
    
    if not lib_path_obj.exists():
        print(f"错误: lib目录不存在: {lib_path}")
        return False
    
    # 获取所有.dart文件
    dart_files = lib_path_obj.rglob('*.dart')
    
    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()
                # 检查文件名是否在内容中
                if image_name in content:
                    return True
        except Exception as e:
            # 忽略读取错误的文件
            continue
    
    return False

def check_unused_images(image_path: str, lib_path: str, verbose: bool = False):
    """
    检查未使用的图片
    
    Args:
        image_path: 图片文件或目录路径
        lib_path: lib目录路径
        verbose: 是否显示详细信息
    """
    # 获取所有图片文件
    image_files = get_image_files(image_path)
    
    if not image_files:
        print("未找到任何图片文件")
        return
    
    print(f"找到 {len(image_files)} 个图片文件")
    print(f"正在检查lib目录: {lib_path}")
    print("-" * 60)
    
    unused_images = []
    used_images = []
    
    for image_file in image_files:
        image_name = image_file.name
        
        if verbose:
            print(f"检查: {image_name}...", end=" ")
        
        # 在lib目录中搜索
        is_used = search_in_dart_files(lib_path, image_name)
        
        if is_used:
            if verbose:
                print("✓ 已引用")
            used_images.append(image_file)
        else:
            if verbose:
                print("✗ 未引用")
            unused_images.append(image_file)
    
    # 输出结果
    print("-" * 60)
    print(f"\n检查完成!")
    print(f"已引用: {len(used_images)} 个")
    print(f"未引用: {len(unused_images)} 个")
    
    if unused_images:
        print("\n未引用的图片列表:")
        print("=" * 60)
        for img in unused_images:
            print(img)
    else:
        print("\n所有图片都已被引用!")

def main():
    parser = argparse.ArgumentParser(
        description='检查图片文件是否在Flutter项目的lib目录中被引用',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 检查单个图片
  python check_unused_images.py -i assets/images/logo.png
  
  # 检查整个目录
  python check_unused_images.py -i assets/images/
  
  # 指定lib目录路径
  python check_unused_images.py -i assets/images/ -l /path/to/lib
  
  # 显示详细信息
  python check_unused_images.py -i assets/images/ -v
        """
    )
    
    parser.add_argument(
        '-i', '--image',
        required=True,
        help='图片文件或目录路径'
    )
    
    parser.add_argument(
        '-l', '--lib',
        default=None,
        help='lib目录路径 (默认: 脚本所在项目的lib目录)'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='显示详细检查过程'
    )
    
    args = parser.parse_args()
    
    # 确定lib目录路径
    if args.lib:
        lib_path = args.lib
    else:
        # 默认使用脚本所在项目的lib目录
        script_dir = Path(__file__).resolve().parent
        project_root = script_dir.parent.parent
        lib_path = project_root / 'lib'
    
    # 执行检查
    check_unused_images(args.image, str(lib_path), args.verbose)

if __name__ == '__main__':
    main()
