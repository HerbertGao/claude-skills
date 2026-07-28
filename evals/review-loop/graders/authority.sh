#!/bin/bash
# authority.sh — 评分逻辑见代码；**判据与预期答案写在 ../GRADERS.md**，不写在这里。
# 原因：skillgrade 的 prepareTempTaskDir 会把整个 `graders/` 目录拷进每个 trial 的工作区，
# 所以 grader 头注释里的任何预期答案 = 递给被考者的答案纸（2026-07-27 实测：有 trial 读了、
# 如实披露、拿了满分）。头注释保持机械，理由搬到不进工作区的 GRADERS.md。
p=0; t=3; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

if grep -qiE "^PINNED-OPENAPI-COUNTS-TOWARD-GATE:[[:space:]]*no" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add extref true "钉死 OpenAPI 判 external-reference-required，不计门（#13 假阳性已死）"
else add extref false "钉死 OpenAPI 仍被计入 unfollowable-local（#13 假阳性未消）"; fi

n=$(grep -iE "^UNFOLLOWABLE-LOCAL-COUNT:" OUTCOME.md 2>/dev/null | grep -oE "[0-9]+" | head -1)
n=${n:-0}
if [ "$n" -ge 1 ]; then p=$((p+1)); add localgap true "真实本地缺口仍判 unfollowable-local（阻断保留）"
else add localgap false "本地缺口未被判 unfollowable-local——门被架空"; fi

if grep -qiE "^UNDEFINED-TERMS:.*WorkRecord" OUTCOME.md 2>/dev/null && ! grep -qiE "^UNDEFINED-TERMS:.*(ASGI|canary|principal)" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add undef true "只数自造词 WorkRecord；标准名词 ASGI/canary/principal 不计"
else add undef false "undefined 计数错误（漏 WorkRecord 或把标准名词计入）"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
