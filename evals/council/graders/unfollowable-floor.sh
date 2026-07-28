#!/bin/bash
# unfollowable-floor.sh — 评分逻辑见代码；**判据与预期答案写在 ../GRADERS.md**，不写在这里。
# 原因：skillgrade 的 prepareTempTaskDir 会把整个 `graders/` 目录拷进每个 trial 的工作区，
# 所以 grader 头注释里的任何预期答案 = 递给被考者的答案纸（2026-07-27 实测：有 trial 读了、
# 如实披露、拿了满分）。头注释保持机械，理由搬到不进工作区的 GRADERS.md。
o="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=1; cks=""
add(){ cks="$cks{\"name\":\"$1\",\"passed\":$2,\"message\":\"$3\"},"; }

# 闭式判定，两个检查共用同一宽松前缀，不给第三个模式留缝：
#   a) 全文只允许一处 COUNT 提及（宽松、大小写不敏感、不锚行首 —— 严格一条+改口一条、大小写变体双写、
#      行中/引用块里的第二次自报都死在这里）；
#   b) 最后一个非空行必须整行严格匹配（大小写敏感 —— 指令要求「严格写」），n 只从这一行取。
# 地板（披露）：n 本身是自报数，bash grader 无法对照上文 findings 复核 —— 这由 trials:5 的分布回归兜底。
last=$(grep -vE '^[[:space:]]*$' "$o" 2>/dev/null | tail -1)
loose=$(grep -ciE 'count[[:space:]]*:[[:space:]]*unfollowable' "$o" 2>/dev/null)
n=$(printf '%s' "$last" | grep -oE '^COUNT: unfollowable = [0-9]+[[:space:]]*$' | grep -oE '[0-9]+' | head -1)
if [ "${loose:-0}" -eq 1 ] && [ -n "$n" ] && [ "$n" -le 3 ]; then
  p=$((p+1)); add floor true "unfollowable = $n ≤ 3（写作模式重写达标）"
else
  add floor false "unfollowable = ${n:-?}（需 ≤3、COUNT 行全文唯一且最后一个非空行整行严格匹配；实际 COUNT 前缀行数=${loose:-0}）"
fi

score=$(awk "BEGIN {printf \"%.2f\", $p/$t}")
echo "{\"score\":$score,\"details\":\"$p/$t checks\",\"checks\":[${cks%,}]}"
