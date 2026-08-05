#!/usr/bin/env bash
set -euo pipefail
redactor=${REDACTOR_PATH:-../../skills/review-loop/bin/redact.py}
tmp=$(mktemp -d "${TMPDIR:-/tmp}/review-redactor.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
cat >"$tmp/input.txt" <<'EOF'
api_key="sk-FAKE_REDACTOR_TOKEN_1234567890"
api_key="sk-FAKE_REDACTOR_TOKEN_1234567890"
contact: alice@example.test
literal: [REDACTED:deadbeef:API_TOKEN:1]
literal-two: [SOURCE-LITERAL-ESCAPED:runNonce1234:1]
Authorization: Bearer headerValue_ABC1234567890
path: /src/very-long-directory-name/component.py
identifier: this_is_a_long_configuration_identifier
EOF
printf '%s\n' 'password="prefix\"suffix"' >>"$tmp/input.txt"
json_secret=CorrectHorseBatteryStaple
phone_value=4155552671
printf '{"password":"%s"}\nphone: %s\n' "$json_secret" "$phone_value" >>"$tmp/input.txt"
key_label='PRIVATE KEY'
printf -- '-----BEGIN %s-----\nfixture-key-body\n-----END %s-----\n' "$key_label" "$key_label" >>"$tmp/input.txt"
uri_user=fixture-user
uri_value=example
printf 'endpoint=postgres://%s:%s@example.test/app\n' "$uri_user" "$uri_value" >>"$tmp/input.txt"
hex_left=0123456789abcdef
hex_right=0123456789abcdef
hex_value=${hex_left}${hex_right}
printf 'hex-path=/objects/%s/file\n' "$hex_value" >>"$tmp/input.txt"
printf 'opaque=%s\n' "$hex_value" >>"$tmp/input.txt"
python3 "$redactor" --nonce runNonce1234 --input "$tmp/input.txt" >"$tmp/out-1.txt"
python3 "$redactor" --nonce runNonce1234 --input "$tmp/input.txt" >"$tmp/out-2.txt"
cmp -s "$tmp/out-1.txt" "$tmp/out-2.txt"
! grep -qE 'FAKE_REDACTOR_TOKEN|alice@example\.test|headerValue_ABC|prefix\\"suffix|fixture-key-body' "$tmp/out-1.txt"
! grep -q "${uri_user}:${uri_value}" "$tmp/out-1.txt"
! grep -q "opaque=${hex_value}" "$tmp/out-1.txt"
! grep -q "$json_secret" "$tmp/out-1.txt"
! grep -q "$phone_value" "$tmp/out-1.txt"
[ "$(grep -o '\[REDACTED:runNonce1234:NAMED_SECRET:1\]' "$tmp/out-1.txt" | wc -l | tr -d ' ')" = 2 ]
grep -q '\[REDACTED:runNonce1234:EMAIL:1\]' "$tmp/out-1.txt"
grep -q '\[REDACTED:runNonce1234:AUTHORIZATION:1\]' "$tmp/out-1.txt"
grep -q '\[REDACTED:runNonce1234:URI_CREDENTIAL:1\]' "$tmp/out-1.txt"
grep -q '\[REDACTED:runNonce1234:HEX_TOKEN:1\]' "$tmp/out-1.txt"
grep -q '\[SOURCE-LITERAL-ESCAPED:runNonce1234:1\]' "$tmp/out-1.txt"
grep -q '\[SOURCE-LITERAL-ESCAPED:runNonce1234:2\]' "$tmp/out-1.txt"
grep -q '/src/very-long-directory-name/component.py' "$tmp/out-1.txt"
grep -q "/objects/${hex_value}/file" "$tmp/out-1.txt"
grep -q 'this_is_a_long_configuration_identifier' "$tmp/out-1.txt"
[ "$(wc -l <"$tmp/input.txt" | tr -d ' ')" = "$(wc -l <"$tmp/out-1.txt" | tr -d ' ')" ]
cat >"$tmp/multiline.txt" <<'EOF'
password="line-one
line-two"
EOF
if python3 "$redactor" --nonce runNonce1234 --input "$tmp/multiline.txt" >"$tmp/multiline.out" 2>"$tmp/multiline.err"; then
	echo 'multiline sensitive value unexpectedly accepted' >&2
	exit 1
fi
[ ! -s "$tmp/multiline.out" ]
! grep -qE 'line-one|line-two' "$tmp/multiline.err"
block_secret=multilineSecretValue
printf 'password: |\n  %s\n' "$block_secret" >"$tmp/yaml-block.txt"
if python3 "$redactor" --nonce runNonce1234 --input "$tmp/yaml-block.txt" >"$tmp/yaml-block.out" 2>"$tmp/yaml-block.err"; then
	echo 'YAML block sensitive value unexpectedly accepted' >&2
	exit 1
fi
[ ! -s "$tmp/yaml-block.out" ]
! grep -q "$block_secret" "$tmp/yaml-block.err"
structured_secret=structuredSecretValue
printf '{"token":["%s"]}\n' "$structured_secret" >"$tmp/structured.txt"
if python3 "$redactor" --nonce runNonce1234 --input "$tmp/structured.txt" >"$tmp/structured.out" 2>"$tmp/structured.err"; then
	echo 'structured sensitive value unexpectedly accepted' >&2
	exit 1
fi
[ ! -s "$tmp/structured.out" ]
! grep -q "$structured_secret" "$tmp/structured.err"
yaml_secret=yamlStructuredSecret
printf 'token:\n  - %s\n' "$yaml_secret" >"$tmp/yaml-sequence.txt"
printf 'token:\n  nested: %s\n' "$yaml_secret" >"$tmp/yaml-map.txt"
for yaml_kind in sequence map; do
	if python3 "$redactor" --nonce runNonce1234 --input "$tmp/yaml-${yaml_kind}.txt" >"$tmp/yaml-${yaml_kind}.out" 2>"$tmp/yaml-${yaml_kind}.err"; then
		echo "YAML ${yaml_kind} sensitive value unexpectedly accepted" >&2
		exit 1
	fi
	[ ! -s "$tmp/yaml-${yaml_kind}.out" ]
	! grep -q "$yaml_secret" "$tmp/yaml-${yaml_kind}.err"
done
printf 'x\0secret' >"$tmp/binary"
if python3 "$redactor" --nonce runNonce1234 --input "$tmp/binary" >"$tmp/binary.out" 2>"$tmp/binary.err"; then
	echo 'binary input unexpectedly accepted' >&2
	exit 1
fi
[ ! -s "$tmp/binary.out" ]
! grep -q secret "$tmp/binary.err"
[ "$(python3 "$redactor" --version)" = 1.0.0 ]
echo 'redactor self-test PASS'
