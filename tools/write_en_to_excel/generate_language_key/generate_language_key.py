#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys
from pathlib import Path


STOP_WORDS = {
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'then', 'else',
    'is', 'are', 'am', 'was', 'were', 'be', 'been', 'being',
    'do', 'does', 'did', 'done', 'can', 'could', 'may', 'might',
    'must', 'shall', 'should', 'will', 'would',
    'to', 'of', 'for', 'in', 'on', 'at', 'by', 'from', 'with',
    'as', 'into', 'onto', 'about', 'over', 'under',
    'this', 'that', 'these', 'those', 'it', 'its', 'you', 'your',
    'we', 'our', 'they', 'their', 'he', 'she', 'his', 'her',
    'here', 'there', 'just', 'please', 'again', 'later', 'now',
    'very', 'more', 'most', 'any', 'some', 'such', 'only',
    'me', 'my', 'mine', 'us', 'them', 'than',
    'try', 'get', 'got',
}

FOURTH_TOKEN_QUALIFIERS = {
    'ago', 'today', 'tomorrow', 'yesterday',
    'daily', 'weekly', 'monthly', 'yearly',
    'first', 'last', 'next', 'prev', 'previous',
    'current', 'new', 'old',
}

PARAM_RELATED_TOKENS = {
    'day', 'days', 'week', 'weeks', 'month', 'months', 'year', 'years',
    'hour', 'hours', 'hr', 'hrs', 'minute', 'minutes', 'min', 'mins',
    'second', 'seconds', 'sec', 'secs', 'ago',
}


def read_lines(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return [line.strip() for line in file.readlines() if line.strip()]


def load_existing_keys(localization_path):
    existing_keys = set()

    with open(localization_path, 'r', encoding='utf-8') as file:
        for line in file:
            match = re.match(r'^\s{4}"([^"]+)":\s*', line)
            if match:
                existing_keys.add(match.group(1))

    return existing_keys


def normalize_text(text):
    text = text.strip().lower()
    text = re.sub(r'@param(\d+)([a-z]+)', r' @param\1 \2 ', text)
    text = re.sub(r'@([a-z0-9_]+)', r' \1 ', text)
    text = text.replace('&', ' and ')
    text = re.sub(r'[^a-z0-9]+', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def split_tokens(text):
    normalized = normalize_text(text)
    if not normalized:
        return []
    return normalized.split(' ')


def select_core_tokens(tokens):
    filtered_tokens = [token for token in tokens if token not in STOP_WORDS]
    return filtered_tokens or tokens


def build_candidate(tokens, max_underscores):
    max_parts = max_underscores + 1
    parts = tokens[:max_parts]
    return '_'.join(parts)


def has_param_token(tokens):
    return any(re.fullmatch(r'param\d+', token) for token in tokens)


def should_use_four_parts(core_tokens, original_tokens):
    if len(core_tokens) < 4:
        return False

    fourth_token = core_tokens[3]

    if fourth_token in FOURTH_TOKEN_QUALIFIERS:
        return True

    if has_param_token(original_tokens) and fourth_token in PARAM_RELATED_TOKENS:
        return True

    if len(core_tokens) >= 5:
        return True

    return False


def preferred_underscore_limit(core_tokens, original_tokens):
    if should_use_four_parts(core_tokens, original_tokens):
        return 3
    return 2


def uniquify_candidate(candidate, occupied_keys):
    if candidate not in occupied_keys:
        return candidate

    for number in range(2, 10000):
        new_candidate = f'{candidate}{number}'
        if new_candidate not in occupied_keys:
            return new_candidate

    raise RuntimeError(f'无法为 key 生成唯一后缀: {candidate}')


def generate_key(text, occupied_keys):
    tokens = split_tokens(text)
    if not tokens:
        tokens = ['text']

    core_tokens = select_core_tokens(tokens)
    underscore_limit = preferred_underscore_limit(core_tokens, tokens)

    tried_candidates = []
    for max_underscores in (underscore_limit,):
        candidate = build_candidate(core_tokens, max_underscores)
        if not candidate or candidate in tried_candidates:
            continue
        tried_candidates.append(candidate)
        if candidate not in occupied_keys:
            return candidate

    fallback_candidate = build_candidate(core_tokens, underscore_limit) or 'text'
    return uniquify_candidate(fallback_candidate, occupied_keys)


def write_output(output_path, rows):
    with open(output_path, 'w', encoding='utf-8') as file:
        for key, text in rows:
            file.write(f'{key}\t{text}\n')


def main():
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent.parent.parent

    # 按照要求固定输入文件名为 generate_language_input.txt
    input_file = script_dir / 'generate_language_input.txt'
    
    if len(sys.argv) > 1:
        input_file = Path(sys.argv[1]).resolve()

    localization_file = project_root / 'lib/Util/Translations/MyLocalization.dart'
    output_file = script_dir / 'generated_keys.txt'

    if len(sys.argv) > 2:
        localization_file = Path(sys.argv[2]).resolve()
    if len(sys.argv) > 3:
        output_file = Path(sys.argv[3]).resolve()

    if not input_file.exists():
        print(f'错误: 找不到输入文件: {input_file}')
        sys.exit(1)

    if not localization_file.exists():
        print(f'错误: 找不到本地化文件: {localization_file}')
        sys.exit(1)

    texts = read_lines(input_file)
    existing_keys = load_existing_keys(localization_file)
    occupied_keys = set(existing_keys)

    rows = []
    for text in texts:
        key = generate_key(text, occupied_keys)
        occupied_keys.add(key)
        rows.append((key, text))

    os.makedirs(output_file.parent, exist_ok=True)
    write_output(output_file, rows)

    print(f'输入文本数: {len(texts)}')
    print(f'现有 key 数: {len(existing_keys)}')
    print(f'输出文件: {output_file}')


if __name__ == '__main__':
    main()
