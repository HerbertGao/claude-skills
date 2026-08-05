#!/usr/bin/env python3
"""Run council's fixed, local, read-only checks without exposing raw output."""

from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

from redact import MAX_BYTES, RedactionError, Redactor

VERSION = "1.0.0"


class CheckError(ValueError):
    """A requested check is outside the fixed safety boundary."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", action="version", version=VERSION)
    parser.add_argument("--nonce", required=True)
    parser.add_argument("--allow-root", action="append", required=True, type=Path)
    subparsers = parser.add_subparsers(dest="operation", required=True)

    search = subparsers.add_parser(
        "search", help="fixed-string search; emits locators, never lines"
    )
    search.add_argument("literal")
    search.add_argument("path", type=Path)

    read_line = subparsers.add_parser("read-line", help="emit one redacted line")
    read_line.add_argument("path", type=Path)
    read_line.add_argument("line", type=int)

    for operation in ("stat", "wc-lines", "sha256"):
        command = subparsers.add_parser(operation)
        command.add_argument("path", type=Path)
    return parser.parse_args()


def resolve_existing(path: Path) -> Path:
    try:
        return path.expanduser().resolve(strict=True)
    except OSError as err:
        raise CheckError("path unavailable") from err


def allowed_roots(paths: list[Path]) -> list[Path]:
    roots = [resolve_existing(path) for path in paths]
    if not roots:
        raise CheckError("no allowed roots")
    return roots


def resolve_allowed(path: Path, roots: list[Path]) -> tuple[Path, int, str]:
    resolved = resolve_existing(path)
    for index, root in enumerate(roots, start=1):
        try:
            relative = resolved.relative_to(root)
        except ValueError:
            if resolved != root:
                continue
            relative = Path(".")
        return resolved, index, relative.as_posix()
    raise CheckError("path outside allowed roots")


def opaque_locator(root_index: int, relative: str) -> str:
    material = f"{root_index}\0{relative}".encode()
    digest = hashlib.sha256(material).hexdigest()[:16]
    return f"root{root_index}:path-{digest}"


def read_utf8(path: Path) -> str:
    try:
        raw = path.read_bytes()
    except OSError as err:
        raise CheckError("input unavailable") from err
    if len(raw) > MAX_BYTES or b"\x00" in raw:
        raise CheckError("unsupported input")
    try:
        return raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError as err:
        raise CheckError("unsupported input") from err


def iter_search_files(target: Path) -> list[Path]:
    if target.is_file():
        return [target]
    if not target.is_dir():
        raise CheckError("search target is not a file or directory")
    return sorted(path for path in target.rglob("*") if path.is_file())


def run_search(args: argparse.Namespace, roots: list[Path]) -> int:
    if (
        not args.literal
        or len(args.literal) > 256
        or "\n" in args.literal
        or "\r" in args.literal
    ):
        raise CheckError("invalid search literal")
    target, _, _ = resolve_allowed(args.path, roots)
    matches: list[str] = []
    skipped = 0
    for candidate in iter_search_files(target):
        try:
            resolved, root_index, relative = resolve_allowed(candidate, roots)
            text = read_utf8(resolved)
        except CheckError:
            skipped += 1
            continue
        for line_number, line in enumerate(text.splitlines(), start=1):
            if args.literal in line:
                matches.append(
                    f"MATCH {opaque_locator(root_index, relative)}:{line_number}"
                )
    for match in matches:
        print(match)
    print(f"COUNT {len(matches)}")
    print(f"SKIPPED-UNSAFE {skipped}")
    return 5 if skipped else 0


def run_read_line(args: argparse.Namespace, roots: list[Path]) -> int:
    if args.line < 1:
        raise CheckError("line must be positive")
    path, root_index, relative = resolve_allowed(args.path, roots)
    lines = read_utf8(path).splitlines(keepends=True)
    if args.line > len(lines):
        raise CheckError("line unavailable")
    try:
        safe = Redactor(args.nonce).redact(lines[args.line - 1])
    except RedactionError as err:
        raise CheckError("unsupported sensitive syntax") from err
    print(f"LINE {opaque_locator(root_index, relative)}:{args.line}")
    sys.stdout.write(safe)
    if safe and not safe.endswith(("\n", "\r")):
        print()
    return 0


def run_metadata(args: argparse.Namespace, roots: list[Path]) -> int:
    path, root_index, relative = resolve_allowed(args.path, roots)
    locator = opaque_locator(root_index, relative)
    if args.operation == "stat":
        stat = path.stat()
        print(f"STAT {locator} mode={stat.st_mode & 0o777:o} size={stat.st_size}")
    elif args.operation == "wc-lines":
        text = read_utf8(path)
        print(f"LINES {locator} {len(text.splitlines())}")
    elif args.operation == "sha256":
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        print(f"SHA256 {locator} {digest}")
    else:
        raise CheckError("unsupported operation")
    return 0


def main() -> int:
    args = parse_args()
    try:
        roots = allowed_roots(args.allow_root)
        if args.operation == "search":
            return run_search(args, roots)
        if args.operation == "read-line":
            return run_read_line(args, roots)
        return run_metadata(args, roots)
    except (CheckError, OSError):
        print("safe-check: unavailable", file=sys.stderr)
        return 4


if __name__ == "__main__":
    raise SystemExit(main())
