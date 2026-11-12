#!/usr/bin/env python3
"""Collect git evidence for generating QA-oriented change notes."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


DEFAULT_MAX_DIFF_CHARS = 60000
DEFAULT_MAX_UNTRACKED_FILE_CHARS = 8000


def run_git(args: list[str], cwd: Path) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed:\n{result.stderr.strip()}")
    return result.stdout.strip()


def truncate(text: str, max_chars: int) -> str:
    if len(text) <= max_chars:
        return text
    return text[:max_chars] + f"\n\n[diff truncated at {max_chars} chars]"


def section(title: str, body: str) -> str:
    body = body.strip()
    if not body:
        body = "(empty)"
    return f"## {title}\n\n```text\n{body}\n```"


def read_untracked_preview(repo: Path, files: list[str], max_chars: int) -> str:
    previews: list[str] = []
    remaining = max_chars

    for name in files:
        path = repo / name
        if not path.is_file():
            continue

        try:
            data = path.read_bytes()
        except OSError as exc:
            previews.append(f"--- {name}\n[unable to read: {exc}]")
            continue

        if b"\0" in data[:4096]:
            previews.append(f"--- {name}\n[binary file omitted]")
            continue

        text = data.decode("utf-8", errors="replace")
        if len(text) > DEFAULT_MAX_UNTRACKED_FILE_CHARS:
            text = text[:DEFAULT_MAX_UNTRACKED_FILE_CHARS]
            text += f"\n[untracked file truncated at {DEFAULT_MAX_UNTRACKED_FILE_CHARS} chars]"

        entry = f"--- {name}\n{text}"
        if len(entry) > remaining:
            previews.append(entry[:remaining] + f"\n[untracked preview truncated at {max_chars} chars]")
            break

        previews.append(entry)
        remaining -= len(entry)

    return "\n\n".join(previews)


def collect_local(repo: Path, max_diff_chars: int) -> str:
    untracked = run_git(["ls-files", "--others", "--exclude-standard"], repo)
    untracked_files = [line for line in untracked.splitlines() if line.strip()]
    parts = [
        section("git status --short", run_git(["status", "--short"], repo)),
        section("untracked files", untracked),
        section("staged name-status", run_git(["diff", "--cached", "--name-status"], repo)),
        section("unstaged name-status", run_git(["diff", "--name-status"], repo)),
        section("staged stat", run_git(["diff", "--cached", "--stat"], repo)),
        section("unstaged stat", run_git(["diff", "--stat"], repo)),
    ]

    staged_diff = run_git(["diff", "--cached", "--no-ext-diff", "--unified=80"], repo)
    unstaged_diff = run_git(["diff", "--no-ext-diff", "--unified=80"], repo)
    combined_diff = "\n\n".join(part for part in [staged_diff, unstaged_diff] if part.strip())
    parts.append(section("combined diff", truncate(combined_diff, max_diff_chars)))
    parts.append(section("untracked text preview", read_untracked_preview(repo, untracked_files, max_diff_chars)))
    return "\n\n".join(parts)


def collect_rev(repo: Path, rev: str, max_diff_chars: int) -> str:
    parts = [
        section(
            f"git show summary {rev}",
            run_git(
                [
                    "show",
                    "--stat",
                    "--name-status",
                    "--format=commit %H%nAuthor: %an%nDate: %ad%n%n%B",
                    "--date=short",
                    rev,
                ],
                repo,
            ),
        ),
        section(
            f"git show diff {rev}",
            truncate(run_git(["show", "--no-ext-diff", "--unified=80", "--format=", rev], repo), max_diff_chars),
        ),
    ]
    return "\n\n".join(parts)


def collect_range(repo: Path, rev_range: str, max_diff_chars: int) -> str:
    parts = [
        section(
            f"git log {rev_range}",
            run_git(
                [
                    "log",
                    "--reverse",
                    "--stat",
                    "--name-status",
                    "--format=commit %H%nAuthor: %an%nDate: %ad%n%n%B",
                    "--date=short",
                    rev_range,
                ],
                repo,
            ),
        ),
        section(
            f"git diff {rev_range}",
            truncate(run_git(["diff", "--no-ext-diff", "--unified=80", rev_range], repo), max_diff_chars),
        ),
    ]
    return "\n\n".join(parts)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Collect git context for QA change notes.")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--local", action="store_true", help="Collect staged and unstaged local changes.")
    source.add_argument("--rev", action="append", help="Collect one commit. Can be repeated.")
    source.add_argument("--range", dest="rev_range", help="Collect a commit range, e.g. base..head.")
    parser.add_argument("--repo", default=".", help="Repository path. Defaults to current directory.")
    parser.add_argument("--max-diff-chars", type=int, default=DEFAULT_MAX_DIFF_CHARS)
    parser.add_argument("--output", help="Optional output file path.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = Path(args.repo).resolve()

    try:
        repo_root = Path(run_git(["rev-parse", "--show-toplevel"], repo)).resolve()
        if args.local:
            output = collect_local(repo_root, args.max_diff_chars)
        elif args.rev:
            output = "\n\n".join(collect_rev(repo_root, rev, args.max_diff_chars) for rev in args.rev)
        else:
            output = collect_range(repo_root, args.rev_range, args.max_diff_chars)
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    if args.output:
        Path(args.output).write_text(output + "\n", encoding="utf-8")
    else:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
