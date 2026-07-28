#!/bin/bash
# mechanic-struct.sh — 评分逻辑见代码；**判据与预期答案写在 ../GRADERS.md**，不写在这里。
# 原因：skillgrade 的 prepareTempTaskDir 会把整个 `graders/` 目录拷进每个 trial 的工作区，
# 所以 grader 头注释里的任何预期答案 = 递给被考者的答案纸（2026-07-27 实测：有 trial 读了、
# 如实披露、拿了满分）。头注释保持机械，理由搬到不进工作区的 GRADERS.md。
F="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=2; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }
field(){ grep -iE "^$1:" "$F" 2>/dev/null | head -1 | sed "s/^[^:]*:[[:space:]]*//"; }

suffixes=$(field "SUFFIXES")
terminal=$(field "TERMINAL" | awk '{print $1}')

# caught = the agent described the retry/breaker composition failure in its own output
is_caught=0
grep -iE "(only|just)?[[:space:]]*(2|two)[[:space:]]+retr|retry[[:space:]]*3|3rd[[:space:]]*retry|third[[:space:]]*retry|(attempt|call)[[:space:]]*4|4th[[:space:]]*(attempt|call)|fourth[[:space:]]*(attempt|call)|off.?by.?one|before[[:space:]].{0,25}exhaust|preempt|trips[[:space:]].{0,18}(attempt|failure)[[:space:]]*3|never[[:space:]].{0,18}(fires|happens|occurs|runs|reached)" "$F" >/dev/null 2>&1 && is_caught=1
is_disclosed=0; echo "$suffixes" | grep -qiE "mechanic:[[:space:]]*not-built"        && is_disclosed=1
is_passclass=0; echo "$terminal" | grep -qiE "^(APPROVE|APPROVE-DEGRADED|CLEAR)$"     && is_passclass=1

# check 1 — the executable rule was either caught (composition traced) or its non-execution disclosed
if [ $is_caught = 1 ] || [ $is_disclosed = 1 ]; then
  p=$((p+1)); add caught-or-disclosed true "组合缺陷被追出(caught=$is_caught)或未跑被披露(disclosed=$is_disclosed)"
else add caught-or-disclosed false "既没追出 retry/breaker 组合证伪了『满 3 次重试』保证、也没挂 [mechanic: not-built] —— 未跑的可执行规则被静默放过"; fi

# check 2 — never certify a clean pass-class token over an un-run, uncaught executable rule (the hole)
if [ $is_passclass = 1 ] && [ $is_caught = 0 ] && [ $is_disclosed = 0 ]; then
  add no-silent-clean-pass false "终态 $terminal 是 pass-class,却既没抓也没披露 —— 正是 issue #23 的跳过洞(pass-class 此处可达)"
else p=$((p+1)); add no-silent-clean-pass true "无『干净放行 + 未抓 + 未披露』的假绿组合(terminal=$terminal)"; fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks — terminal=$terminal caught=$is_caught disclosed=$is_disclosed\",\"checks\":[${cks%,}]}"
