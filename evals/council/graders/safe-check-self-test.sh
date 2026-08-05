#!/usr/bin/env bash
set -euo pipefail
wrapper=${SAFE_CHECK_PATH:-../../skills/council/bin/safe_check.py}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/council-safe-check.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/root"
secret=FAKE_COUNCIL_SENTINEL_ALPHA
printf 'feature_gate enabled; API token value %s\n' "$secret" >"$tmp/root/spec.md"
structured=structuredSecretValue
printf '{"token":["%s"]}\n' "$structured" >"$tmp/root/structured.json"
printf 'outside %s\n' "$secret" >"$tmp/outside"
base=(python3 "$wrapper" --nonce runNonce1234 --allow-root "$tmp/root")
"${base[@]}" search feature_gate "$tmp/root" >"$tmp/search.out"
grep -Eq '^MATCH root1:path-[a-f0-9]{16}:1$' "$tmp/search.out"
grep -q 'COUNT 1' "$tmp/search.out"
! grep -q "$secret" "$tmp/search.out"
"${base[@]}" read-line "$tmp/root/spec.md" 1 >"$tmp/line.out"
grep -q '\[REDACTED:runNonce1234:' "$tmp/line.out"
! grep -q "$secret" "$tmp/line.out"
if "${base[@]}" read-line "$tmp/root/structured.json" 1 >"$tmp/structured.out" 2>"$tmp/structured.err"; then
	echo 'structured sensitive value unexpectedly accepted' >&2
	exit 1
fi
[ ! -s "$tmp/structured.out" ]
! grep -q "$structured" "$tmp/structured.err"
path_secret=FAKE_PATH_SECRET_ABC123
printf 'path_probe\n' >"$tmp/root/$path_secret"
"${base[@]}" search path_probe "$tmp/root" >"$tmp/path-search.out"
grep -Eq '^MATCH root1:path-[a-f0-9]{16}:1$' "$tmp/path-search.out"
! grep -q "$path_secret" "$tmp/path-search.out"
"${base[@]}" read-line "$tmp/root/$path_secret" 1 >"$tmp/path-line.out"
! grep -q "$path_secret" "$tmp/path-line.out"
ln -s "$tmp/outside" "$tmp/root/link-out"
if "${base[@]}" read-line "$tmp/root/link-out" 1 >"$tmp/outside.out" 2>"$tmp/outside.err"; then
	echo 'symlink escape unexpectedly accepted' >&2
	exit 1
fi
[ ! -s "$tmp/outside.out" ]
! grep -q "$secret" "$tmp/outside.err"
"${base[@]}" stat "$tmp/root/spec.md" | grep -Eq '^STAT root1:path-[a-f0-9]{16} '
"${base[@]}" wc-lines "$tmp/root/spec.md" | grep -Eq '^LINES root1:path-[a-f0-9]{16} 1$'
"${base[@]}" sha256 "$tmp/root/spec.md" | grep -Eq '^SHA256 root1:path-[a-f0-9]{16} [a-f0-9]{64}$'
printf 'x\0%s' "$secret" >"$tmp/root/binary"
if "${base[@]}" search feature_gate "$tmp/root" >"$tmp/binary-search.out" 2>"$tmp/binary-search.err"; then
	echo 'search with unsafe skipped input unexpectedly passed cleanly' >&2
	exit 1
fi
grep -q 'SKIPPED-UNSAFE 2' "$tmp/binary-search.out"
! grep -q "$secret" "$tmp/binary-search.out" "$tmp/binary-search.err"
[ "$(python3 "$wrapper" --version)" = 1.0.0 ]
echo 'safe-check self-test PASS'
