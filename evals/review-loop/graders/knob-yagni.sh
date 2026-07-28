#!/bin/bash
# Grades OUTCOME.md for issue #24. Rationale lives in eval.yaml's comment, NOT here.
#
# WHY NOT HERE: skillgrade's prepareTempTaskDir copies the whole `graders/` directory into every
# trial's workspace (it resolves the first path segment of each grader's `run:` line). So anything
# written in a grader header is readable by the agent being graded — a scoring script stating its
# own expected answer is an answer key handed to the examinee. Observed: a trial read this file,
# disclosed that it had, and scored 1.00. Keep grader headers mechanical; put the reasoning in
# eval.yaml, which is not staged into the workspace.
F="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=2
: > /tmp/.kyg_checks
# 消息里逐字引用 agent 原文，而原文含双引号/反斜杠/换行是常态（观测到 `openSync(overlay,"a")`
# 撑破手搓 JSON，skillgrade 报 "Failed to parse grader JSON" 并把该 trial 静默记 0）。
# 一律交给 python 做转义，不再手工拼字符串。
add(){ printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> /tmp/.kyg_checks; }
field(){ grep -iE "^$1:" "$F" 2>/dev/null | head -1 | sed "s/^[^:]*:[[:space:]]*//"; }

# 「删掉这个自由度」的表述面。两侧都要命中：既点名那个旋钮，又提出取消它。
KNOB='NOISE_OVERLAY_FILE|overlay 路径可配置|overlay path (is |being )?configurable'
# 观测到的漏判：「撤掉 NOISE_OVERLAY_FILE 这个无人使用的自由度」被判 miss —— 词表不全 = 假阴性。
# 中文说「取消一个东西」的说法多，任何一个都不能少；宁可宽，因为 KNOB 侧已经把范围钉死了。
DROP='删(掉|除)|去(掉|除)|移除|撤(掉|销|下|除)|摘(掉|除)|拿掉|砍(掉|了)|取消|不再(可配置|需要)|不可配置|改为派生|派生(出|自)|固定(死|下来)?|按约定固定|写死|收回|hardcod|derive|derived|remove|drop|eliminat|unconfigurable|non-configurable'
# 加固守卫的表述面 —— 基线的预期落点，仅用于 details，不参与打分。
HARDEN='realpath|statSync|try/?catch|大小写|case-?(in)?sensitiv|case-?fold|ELOOP|EACCES|ENOENT|dev/ino|inode|basename'

top=$(field "TOP-FIX")
if echo "$top" | grep -qiE "$KNOB" && echo "$top" | grep -qiE "$DROP"; then
  p=$((p+1)); add top-fix true "本轮派出的修复是「删掉这个自由度」——目标类命中"
else
  if echo "$top" | grep -qiE "$HARDEN"; then
    add top-fix false "本轮派出的修复仍在加固守卫（第 4 次），未质疑守卫所守的自由度。得到: '$top'"
  else
    add top-fix false "本轮派出的修复既非删除自由度、也未落在已知加固面。得到: '$top'"
  fi
fi

# 弱命中：OUTCOME 里但凡提出过取消这个旋钮，就算想到了——哪怕没被选为本轮修复。
# **同行共现**是硬要求。两个模式各自在文件某处出现不算：观测到的假阳性是「删掉 realpath 退化分支」
# （加固语，DROP 命中）与别处一句 `src/overlay.ts` 的旋钮引用（KNOB 命中）拼成一次伪命中。
# TOP-FIX 命中 ⇒ 蕴含"想到过"，不必再过一遍同一个词表（词表脆弱性否则会在这里复发）。
if { echo "$top" | grep -qiE "$KNOB" && echo "$top" | grep -qiE "$DROP"; } || grep -iE "$KNOB" "$F" 2>/dev/null | grep -qiE "$DROP"; then
  p=$((p+1)); add considered true "OUTCOME 中提出过取消该自由度（即使未被选为本轮修复）"
else
  add considered false "整份 OUTCOME 从未提出过取消该自由度——没有任何 lane 问「这东西该不该存在」"
fi

P=$p T=$t python3 -c '
import json,os,sys
rows=[]
for line in open("/tmp/.kyg_checks",encoding="utf-8"):
    n,ok,msg=line.rstrip("\n").split("\t",2)
    rows.append({"name":n,"passed":ok=="true","message":msg})
p,t=int(os.environ["P"]),int(os.environ["T"])
# 输出格式对齐仓内既有 grader（`"score":1.00`，冒号后无空格、两位小数）——graders/self-test.sh
# 用 sed 按该形状抽分，换格式会让自测在逻辑正确时误报 FAIL。
# 本段整体裹在 shell 单引号里 —— python 内部一律用双引号，出现单引号会当场截断脚本。
checks=json.dumps(rows,ensure_ascii=False,separators=(",",":"))
print("{\"score\":%.2f,\"details\":\"%d/%d checks\",\"checks\":%s}" % (p/t,p,t,checks))
'
rm -f /tmp/.kyg_checks
