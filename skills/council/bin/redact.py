#!/usr/bin/env python3
"""Deterministically redact supported secret/PII classes from one UTF-8 file."""

from __future__ import annotations

import argparse
import math
import re
import sys
from collections import Counter
from pathlib import Path

VERSION = "1.0.0"
MAX_BYTES = 10 * 1024 * 1024
NONCE_RE = re.compile(r"[A-Za-z0-9_-]{8,16}\Z")
SOURCE_PLACEHOLDER_RE = re.compile(
    r"\[(?:REDACTED|SOURCE-LITERAL-ESCAPED):[^\]\r\n]{1,200}\]"
)
PRIVATE_KEY_RE = re.compile(
    r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----",
    re.DOTALL,
)
PROVIDER_TOKEN_RE = re.compile(
    r"\b(?:AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,})\b"
)
JWT_RE = re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b")
AUTH_RE = re.compile(r"(?im)(\bauthorization\s*:\s*(?:bearer|basic)\s+)([^\s,;]+)")
COOKIE_RE = re.compile(r"(?im)(\b(?:set-cookie|cookie)\s*:\s*)([^\r\n]+)")
DESCRIBED_SECRET_RE = re.compile(
    r"(?i)(\b(?:api|auth|session|access|refresh)?[ \t_-]*(?:token|secret|password|credential)(?:[ \t]+value)?[ \t]*[`\"']?)([A-Za-z0-9+/_=-]{8,})"
)
URI_CREDENTIAL_RE = re.compile(r"(?i)(\b[a-z][a-z0-9+.-]*://)([^/\s@]+)@")
SENSITIVE_KEY = (
    r"[A-Za-z0-9_-]*(?:api[_-]?key|access[_-]?token|refresh[_-]?token|auth[_-]?token|"
    r"token|client[_-]?secret|secret|password|passwd|pwd|session(?:[_-]?id)?|cookie|"
    r"authorization|private[_-]?key|credential)[A-Za-z0-9_-]*"
)
SENSITIVE_ASSIGN_PREFIX = rf"(?<!:)(?:[\"'])?\b{SENSITIVE_KEY}\b(?:[\"'])?[ \t]*(?:=|:)[ \t]*"
QUOTED_ASSIGN_START_RE = re.compile(rf"(?im)({SENSITIVE_ASSIGN_PREFIX})([\"'])")
DOUBLE_QUOTED_ASSIGN_RE = re.compile(
    rf"(?im)({SENSITIVE_ASSIGN_PREFIX})(\")((?:\\.|[^\"\\\r\n])*)(\")"
)
SINGLE_QUOTED_ASSIGN_RE = re.compile(
    rf"(?im)({SENSITIVE_ASSIGN_PREFIX})(')((?:\\.|[^'\\\r\n])*)(')"
)
UNQUOTED_ASSIGN_RE = re.compile(rf"(?im)({SENSITIVE_ASSIGN_PREFIX})([^\"'\s,;`]+)")
YAML_BLOCK_SECRET_RE = re.compile(
    rf"(?im)^[ \t]*{SENSITIVE_ASSIGN_PREFIX}[|>][+-]?[1-9]?[ \t]*(?:#.*)?$"
)
STRUCTURED_SECRET_RE = re.compile(rf"(?im){SENSITIVE_ASSIGN_PREFIX}[\[{{]")
EMPTY_SENSITIVE_ASSIGN_RE = re.compile(
    rf"(?im)^[ \t]*{SENSITIVE_ASSIGN_PREFIX}(?:#.*)?$"
)
EMAIL_RE = re.compile(
    r"(?<![\w.+-])[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}(?![\w.-])", re.IGNORECASE
)
LABELED_PHONE_RE = re.compile(
    r"(?i)(\b(?:phone|mobile|tel(?:ephone)?)\s*[:=]\s*)(\+?\d{10,15})"
)
PHONE_RE = re.compile(
    r"(?<!\w)(?:\+\d{1,3}[ .-]?)?(?:\(?\d{3}\)?[ .-])\d{3}[ .-]\d{4}(?!\w)"
)
HEX_TOKEN_RE = re.compile(r"(?i)(?<![a-f0-9])[a-f0-9]{32,}(?![a-f0-9])")
TOKEN_CANDIDATE_RE = re.compile(
    r"(?<![A-Za-z0-9+=_-])[A-Za-z0-9+=_-]{24,}(?![A-Za-z0-9+=_-])"
)


class RedactionError(ValueError):
    """Input contains a sensitive construct this redactor cannot safely preserve."""


class Redactor:
    def __init__(self, nonce: str) -> None:
        self.nonce = nonce
        self._seen: dict[tuple[str, str], int] = {}
        self._next: Counter[str] = Counter()
        self._literal_seen: dict[str, int] = {}

    def placeholder(self, kind: str, value: str) -> str:
        key = (kind, value)
        if key not in self._seen:
            self._next[kind] += 1
            self._seen[key] = self._next[kind]
        return f"[REDACTED:{self.nonce}:{kind}:{self._seen[key]}]"

    def escape_source_placeholder(self, match: re.Match[str]) -> str:
        value = match.group(0)
        if value not in self._literal_seen:
            self._literal_seen[value] = len(self._literal_seen) + 1
        return f"[SOURCE-LITERAL-ESCAPED:{self.nonce}:{self._literal_seen[value]}]"

    def whole(
        self,
        kind: str,
        pattern: re.Pattern[str],
        text: str,
        *,
        preserve_lines: bool = False,
    ) -> str:
        def replace(match: re.Match[str]) -> str:
            placeholder = self.placeholder(kind, match.group(0))
            if preserve_lines:
                placeholder += "\n" * match.group(0).count("\n")
            return placeholder

        return pattern.sub(replace, text)

    @staticmethod
    def _validate_quoted_assignments(text: str) -> None:
        for match in QUOTED_ASSIGN_START_RE.finditer(text):
            quote = match.group(2)
            escaped = False
            for char in text[match.end() :]:
                if char in "\r\n":
                    break
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    break
            else:
                raise RedactionError("unterminated sensitive assignment")
            if char != quote:
                raise RedactionError("multiline sensitive assignment")

    def _redact_quoted_assignment(self, match: re.Match[str]) -> str:
        return (
            match.group(1)
            + match.group(2)
            + self.placeholder("NAMED_SECRET", match.group(3))
            + match.group(4)
        )

    def redact(self, text: str) -> str:
        text = SOURCE_PLACEHOLDER_RE.sub(self.escape_source_placeholder, text)
        if YAML_BLOCK_SECRET_RE.search(text):
            raise RedactionError("YAML block sensitive assignment")
        if STRUCTURED_SECRET_RE.search(text):
            raise RedactionError("structured sensitive assignment")
        if EMPTY_SENSITIVE_ASSIGN_RE.search(text):
            raise RedactionError("multiline structured sensitive assignment")
        self._validate_quoted_assignments(text)
        text = self.whole("PRIVATE_KEY", PRIVATE_KEY_RE, text, preserve_lines=True)
        text = self.whole("PROVIDER_TOKEN", PROVIDER_TOKEN_RE, text)
        text = self.whole("JWT", JWT_RE, text)
        text = AUTH_RE.sub(
            lambda match: (
                match.group(1) + self.placeholder("AUTHORIZATION", match.group(2))
            ),
            text,
        )
        text = COOKIE_RE.sub(
            lambda match: match.group(1) + self.placeholder("COOKIE", match.group(2)),
            text,
        )
        text = DESCRIBED_SECRET_RE.sub(
            lambda match: (
                match.group(1) + self.placeholder("DESCRIBED_SECRET", match.group(2))
            ),
            text,
        )
        text = URI_CREDENTIAL_RE.sub(
            lambda match: (
                match.group(1)
                + self.placeholder("URI_CREDENTIAL", match.group(2))
                + "@"
            ),
            text,
        )
        text = DOUBLE_QUOTED_ASSIGN_RE.sub(self._redact_quoted_assignment, text)
        text = SINGLE_QUOTED_ASSIGN_RE.sub(self._redact_quoted_assignment, text)
        text = UNQUOTED_ASSIGN_RE.sub(
            lambda match: (
                match.group(1) + self.placeholder("NAMED_SECRET", match.group(2))
            ),
            text,
        )
        text = self.whole("EMAIL", EMAIL_RE, text)
        text = LABELED_PHONE_RE.sub(
            lambda match: match.group(1) + self.placeholder("PHONE", match.group(2)),
            text,
        )
        text = self.whole("PHONE", PHONE_RE, text)
        text = HEX_TOKEN_RE.sub(self._redact_hex, text)
        text = TOKEN_CANDIDATE_RE.sub(self._redact_high_entropy, text)
        return text

    def _redact_hex(self, match: re.Match[str]) -> str:
        before = match.string[match.start() - 1] if match.start() else ""
        after = match.string[match.end()] if match.end() < len(match.string) else ""
        if before in "/." or after in "/.":
            return match.group(0)
        return self.placeholder("HEX_TOKEN", match.group(0))

    def _redact_high_entropy(self, match: re.Match[str]) -> str:
        value = match.group(0)
        classes = sum(
            (
                any(char.islower() for char in value),
                any(char.isupper() for char in value),
                any(char.isdigit() for char in value),
                any(char in "+/=_-" for char in value),
            )
        )
        counts = Counter(value)
        entropy = -sum(
            (n / len(value)) * math.log2(n / len(value)) for n in counts.values()
        )
        before = match.string[match.start() - 1] if match.start() else ""
        after = match.string[match.end()] if match.end() < len(match.string) else ""
        identifier_like = all(char.islower() or char in "_-" for char in value)
        if (
            before in "/."
            or after in "/."
            or identifier_like
            or classes < 2
            or entropy < 3.5
        ):
            return value
        return self.placeholder("HIGH_ENTROPY", value)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", action="version", version=VERSION)
    parser.add_argument("--nonce", required=True, help="8-16 URL-safe run identifier")
    parser.add_argument(
        "--input", required=True, type=Path, help="UTF-8 input file; never secret text"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not NONCE_RE.fullmatch(args.nonce):
        print("redactor: invalid nonce", file=sys.stderr)
        return 2
    try:
        raw = args.input.read_bytes()
    except OSError:
        print("redactor: input unavailable", file=sys.stderr)
        return 3
    if len(raw) > MAX_BYTES or b"\x00" in raw:
        print("redactor: unsupported input", file=sys.stderr)
        return 4
    try:
        text = raw.decode("utf-8", errors="strict")
    except UnicodeDecodeError:
        print("redactor: input is not UTF-8", file=sys.stderr)
        return 4
    try:
        redacted = Redactor(args.nonce).redact(text)
    except RedactionError:
        print("redactor: unsupported sensitive syntax", file=sys.stderr)
        return 4
    sys.stdout.write(redacted)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
