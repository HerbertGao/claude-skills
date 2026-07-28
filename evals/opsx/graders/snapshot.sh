#!/bin/bash
# snapshot.sh — 评分逻辑见代码；**判据与预期答案写在 ../GRADERS.md**，不写在这里。
# 原因：skillgrade 的 prepareTempTaskDir 会把整个 `graders/` 目录拷进每个 trial 的工作区，
# 所以 grader 头注释里的任何预期答案 = 递给被考者的答案纸（2026-07-27 实测：有 trial 读了、
# 如实披露、拿了满分）。头注释保持机械，理由搬到不进工作区的 GRADERS.md。
o="${OUTCOME_FILE:-OUTCOME.md}"; p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
gline=$(grep -iE '^[[:space:]]*GROUND:' "$o" | head -1)
if printf '%s' "$gline" | grep -qE 'auth\.py' && printf '%s' "$gline" | grep -qE 'app\.tsx' \
   && ! printf '%s' "$gline" | grep -qE 'notes\.txt'; then
  p=$((p+1)); add ground true "ground=树快照口径(含 auth+app,排除 porcelain-only 的 notes.txt)"
else add ground false "ground 应含 auth.py+app.tsx 且不含 notes.txt(树快照 vs porcelain 相减)"; fi
if grep -qE '^[[:space:]]*TRAP:.*auth\.py' "$o"; then
  p=$((p+1)); add trap true "点名 porcelain 相减会漏 auth.py"
else add trap false "TRAP 应点名 auth.py(波首已脏,相减即消失)"; fi
score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
