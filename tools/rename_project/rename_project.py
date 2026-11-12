#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
基于本框架创建新项目后，一键修改项目标识：

- Dart package 名：pubspec.yaml `name` + lib/ 下所有 `package:旧名/` import
- Android：namespace / applicationId / profile 包名 / MainActivity 包路径 / app_name
- iOS：PRODUCT_BUNDLE_IDENTIFIER / CFBundleDisplayName / CFBundleName
- 代码常量：Const.appName、LogUtil.projectName、StringUtil.googlePlayStoreId
- IDE 配置：.vscode/launch.json、.serena/project.yml

用法（在项目根目录执行）：
    python3 tools/rename_project/rename_project.py <package_name> <bundle_id> [display_name]

示例：
    python3 tools/rename_project/rename_project.py my_app com.company.myapp "My App"

执行后请运行：flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
"""

import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def read(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()


def write(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)


def sub_file(rel_path, pattern, repl, count=0, required=True):
    path = os.path.join(ROOT, rel_path)
    if not os.path.exists(path):
        if required:
            print(f'⚠️  文件不存在，跳过: {rel_path}')
        return
    content = read(path)
    new_content, n = re.subn(pattern, repl, content, count=count, flags=re.M)
    if n == 0 and required:
        print(f'⚠️  未匹配到需要替换的内容: {rel_path} ({pattern})')
    if new_content != content:
        write(path, new_content)
        print(f'✅ {rel_path}（{n} 处）')


def current_package_name():
    match = re.search(r'^name:\s*([A-Za-z0-9_]+)', read(os.path.join(ROOT, 'pubspec.yaml')), re.M)
    if not match:
        sys.exit('❌ pubspec.yaml 中未找到 name 字段')
    return match.group(1)


def current_android_id():
    gradle = read(os.path.join(ROOT, 'android/app/build.gradle.kts'))
    match = re.search(r'applicationId = "([^"]+)"', gradle)
    if not match:
        sys.exit('❌ android/app/build.gradle.kts 中未找到 applicationId')
    return match.group(1)


def rename_dart_package(old, new):
    sub_file('pubspec.yaml', r'^name:\s*' + re.escape(old) + r'\s*$', f'name: {new}', count=1)
    changed = 0
    for base in ('lib', 'test'):
        base_dir = os.path.join(ROOT, base)
        if not os.path.isdir(base_dir):
            continue
        for dirpath, _, filenames in os.walk(base_dir):
            for filename in filenames:
                if not filename.endswith('.dart'):
                    continue
                path = os.path.join(dirpath, filename)
                content = read(path)
                new_content = content.replace(f'package:{old}/', f'package:{new}/')
                if new_content != content:
                    write(path, new_content)
                    changed += 1
    print(f'✅ Dart import 已替换（{changed} 个文件）')
    sub_file('lib/Util/Common/LogUtil.dart', r"const String projectName = '[^']*';",
             f"const String projectName = '{new}';")


def rename_android(old_id, new_id, display_name):
    gradle = 'android/app/build.gradle.kts'
    sub_file(gradle, r'namespace = "[^"]+"', f'namespace = "{new_id}"')
    sub_file(gradle, r'applicationId = "[^"]+"', f'applicationId = "{new_id}"')
    sub_file(gradle, r'variant\.applicationId\.set\("[^"]+"\)',
             f'variant.applicationId.set("{new_id}.test")')

    kotlin_root = os.path.join(ROOT, 'android/app/src/main/kotlin')
    old_dir = os.path.join(kotlin_root, *old_id.split('.'))
    new_dir = os.path.join(kotlin_root, *new_id.split('.'))
    old_activity = os.path.join(old_dir, 'MainActivity.kt')
    if os.path.exists(old_activity) and old_dir != new_dir:
        os.makedirs(new_dir, exist_ok=True)
        shutil.move(old_activity, os.path.join(new_dir, 'MainActivity.kt'))
        # 清理空的旧包目录
        cur = old_dir
        while cur != kotlin_root and os.path.isdir(cur) and not os.listdir(cur):
            os.rmdir(cur)
            cur = os.path.dirname(cur)
        print(f'✅ MainActivity.kt 已移动到 {os.path.relpath(new_dir, ROOT)}')
    sub_file(os.path.relpath(os.path.join(new_dir, 'MainActivity.kt'), ROOT),
             r'^package [A-Za-z0-9_.]+', f'package {new_id}', count=1)

    if display_name:
        for values in ('values', 'values-zh'):
            sub_file(f'android/app/src/main/res/{values}/strings.xml',
                     r'<string name="app_name">[^<]*</string>',
                     f'<string name="app_name">{display_name}</string>', required=False)


def rename_ios(new_bundle_id, package_name, display_name):
    pbxproj = 'ios/Runner.xcodeproj/project.pbxproj'
    sub_file(pbxproj, r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+\.RunnerTests;',
             f'PRODUCT_BUNDLE_IDENTIFIER = {new_bundle_id}.RunnerTests;')
    sub_file(pbxproj, r'PRODUCT_BUNDLE_IDENTIFIER = (?![^;]*RunnerTests)[^;]+;',
             f'PRODUCT_BUNDLE_IDENTIFIER = {new_bundle_id};')
    plist = 'ios/Runner/Info.plist'
    sub_file(plist, r'(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)',
             r'\g<1>' + package_name + r'\g<2>')
    if display_name:
        sub_file(plist, r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)',
                 r'\g<1>' + display_name + r'\g<2>')


def rename_constants(new_id, package_name, display_name):
    if display_name:
        sub_file('lib/Util/Const.dart', r'const String appName = "[^"]*";',
                 f'const String appName = "{display_name}";')
    sub_file('lib/Util/Common/StringUtil.dart', r'const String googlePlayStoreId = "[^"]*";',
             f'const String googlePlayStoreId = "{new_id}";')
    sub_file('.vscode/launch.json', r'"name": "[A-Za-z0-9_]+(?= \(|")', f'"name": "{package_name}',
             required=False)
    if display_name:
        sub_file('.serena/project.yml', r'^project_name: .*$', f'project_name: "{display_name}"',
                 required=False)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    new_package, new_bundle_id = sys.argv[1], sys.argv[2]
    display_name = sys.argv[3] if len(sys.argv) > 3 else None

    if not re.fullmatch(r'[a-z][a-z0-9_]*', new_package):
        sys.exit('❌ package_name 只能包含小写字母、数字、下划线，且以字母开头')
    if not re.fullmatch(r'[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+', new_bundle_id):
        sys.exit('❌ bundle_id 格式不正确，例如 com.company.myapp')

    old_package = current_package_name()
    old_android_id = current_android_id()
    print(f'项目根目录: {ROOT}')
    print(f'package: {old_package} → {new_package}')
    print(f'bundle id: {old_android_id} → {new_bundle_id}')
    if display_name:
        print(f'display name: {display_name}')
    print('')

    rename_dart_package(old_package, new_package)
    rename_android(old_android_id, new_bundle_id, display_name)
    rename_ios(new_bundle_id, new_package, display_name)
    rename_constants(new_bundle_id, new_package, display_name)

    print('\n🎉 完成。请执行：flutter clean && flutter pub get && '
          'dart run build_runner build --delete-conflicting-outputs')
    print('   另外记得修改：AGENTS.md 项目描述、ApiConfig 域名、StringUtil 中的商店 / 协议链接')


if __name__ == '__main__':
    main()
