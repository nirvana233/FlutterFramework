#!/usr/bin/env bash
# PostToolUse hook：校验项目硬性规范（AGENTS.md）中「机器可校验」的子集。
# 命中违规时 exit 2，把提醒经 stderr 反馈给 Claude；既有代码命中可忽略。
# 不覆盖的规范（i18n ~ 前缀、命名后缀、GetX 优先等需语义判断）交给 convention-reviewer 子代理。
set -u

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // empty' 2>/dev/null)

[ -z "$file" ] && exit 0
case "$file" in
  *.dart) ;;
  *) exit 0 ;;
esac
case "$file" in
  *.g.dart) exit 0 ;;          # 自动生成文件豁免
  */Common/Debug/*) exit 0 ;;  # Debug / 预览 / GM 页整体豁免
esac
[ -f "$file" ] || exit 0

violations=""

# §2 样式 Token：禁止裸 Color(0x...)（行内注释 // 开头的行豁免，保留 TODO 用法）
hits=$(grep -nE 'Color\(0x' "$file" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*//')
[ -n "$hits" ] && violations="${violations}
[§2 样式Token] 裸 Color(0x..)，应改用 getAppFigmaColors / FigmaVariables：
${hits}
"

# §8 GetX API 优先：禁止 Navigator.pop / push / pushNamed，改用 Get.back() / Get.toNamed()
hits=$(grep -nE 'Navigator\.(pop|push)' "$file" 2>/dev/null)
[ -n "$hits" ] && violations="${violations}
[§8 GetX] Navigator.*，应改用 Get.back() / Get.toNamed()：
${hits}
"

# §8：禁止 dart:io Platform.isIOS/isAndroid（GetPlatform.* 豁免）
hits=$(grep -nE 'Platform\.(isIOS|isAndroid)' "$file" 2>/dev/null | grep -v 'GetPlatform')
[ -n "$hits" ] && violations="${violations}
[§8 GetX] Platform.isXxx，应改用 GetPlatform.isIOS / GetPlatform.isAndroid：
${hits}
"

# §8：禁止 MediaQuery.of(context).size / sizeOf（安全区 padding.top 仍可用，故只查 .size）
hits=$(grep -nE 'MediaQuery\.(of\([^)]*\)\.size|sizeOf\()' "$file" 2>/dev/null)
[ -n "$hits" ] && violations="${violations}
[§8 GetX] MediaQuery..size，应改用 Get.width / Get.height（安全区见 device-util / SmartSafeArea）：
${hits}
"

if [ -n "$violations" ]; then
  printf '⚠️ 硬规范提醒：%s\n若以下命中为既有代码可忽略；若是本次新增/修改，请按规范修正：\n%s' \
    "$file" "$violations" >&2
  exit 2
fi

exit 0
