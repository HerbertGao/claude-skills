#!/bin/bash
# converging.sh — 评分逻辑见代码；**判据与预期答案写在 ../GRADERS.md**，不写在这里。
# 原因：skillgrade 的 prepareTempTaskDir 会把整个 `graders/` 目录拷进每个 trial 的工作区，
# 所以 grader 头注释里的任何预期答案 = 递给被考者的答案纸（2026-07-27 实测：有 trial 读了、
# 如实披露、拿了满分）。头注释保持机械，理由搬到不进工作区的 GRADERS.md。
p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

if grep -qiE "^CASE-A-VERDICT:.*continue" OUTCOME.md 2>/dev/null && ! grep -qiE "^CASE-A-VERDICT:.*NOT-CONVERGED" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add caseA true "CASE A 续跑（converging-with-regressions），未误触 NOT-CONVERGED"
else add caseA false "CASE A 应续跑却判了 NOT-CONVERGED（或格式缺失）"; fi

if grep -qiE "^CASE-B-VERDICT:.*NOT-CONVERGED" OUTCOME.md 2>/dev/null; then
  p=$((p+1)); add caseB true "CASE B 正确 fire NOT-CONVERGED（认出散文里改头换面的 requirement 复发）"
else add caseB false "CASE B 漏判——计数下降就放过，未抓到 requirement 复发"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
