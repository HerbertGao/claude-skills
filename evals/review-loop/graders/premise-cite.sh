#!/bin/bash
# Grades OUTCOME.md for the declared-premise rule. Rationale lives in eval.yaml, NOT here —
# skillgrade stages the whole `graders/` dir into every trial workspace, so a grader header that
# states its expected answer is an answer key handed to the examinee (observed 2026-07-27).
F="${OUTCOME_FILE:-OUTCOME.md}"
p=0; t=2
: > /tmp/.pcite_checks
# 逐字引用 agent 原文，原文含双引号/反斜杠是常态 —— 手搓 JSON 会被撑破，skillgrade 只报
# "Failed to parse grader JSON" 并把该 trial 静默记 0。转义一律交给 python。
add(){ printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> /tmp/.pcite_checks; }
field(){ grep -iE "^$1:" "$F" 2>/dev/null | head -1 | sed "s/^[^:]*:[[:space:]]*//"; }

PREMISE='retryAfter|Retry-After|retry_after'
# 「这条断言是假的 / 未经核验 / 要出处」的表述面。中文说法多，词表漏一个就漏一次命中。
# `假(前提|设)` 曾在此，已删：它把中性词「既有**假设**」当成了「指认为假」，与同行的 retryAfter
# 拼出假阳性，让一份逐字引 :106 放行的假绿探针拿到 0.5。指认为假的措辞必须是及物的。
FALSY='不存在|没有|未(实现|透传|读取|返回|核验|验证)|从未|并(不|未)|不符|证伪|与(源码|代码|实现)(不一致|矛盾)|无(出处|依据|引用)|需(要)?(出处|引用|证据)|待验|假前提|伪前提|虚假|does ?not|never|missing|absent|no such|unverified|unsubstantiated|cite|citation|contradict|false'

# TOP-FINDING 按 instruction 的定义**本身就是一条 finding**（"本轮最重要的那一条 finding"），
# 所以它点名那条前提，就只可能是在质疑它 —— 这里**不再匹配否定词**。
# 两次栽在这上面：漏「撤掉」、漏「无该字段/从不读」。中文否定的表面形式无界，靠枚举必然继续漏；
# 靠字段语义则不会。FALSY 只留给下面那个全文弱命中，那里没有"这是一条 finding"的语义可依。
top=$(field "TOP-FINDING")
if echo "$top" | grep -qiE "$PREMISE"; then
  p=$((p+1)); add top-finding true "本轮最重要的 finding 点名了那条被声明的现状前提——目标类命中"
else
  add top-finding false "本轮最重要的 finding 没有质疑那条被声明的现状前提。得到: '$top'"
fi

# 弱命中：整份 OUTCOME 里但凡质疑过它就算想到了。**同行共现**是硬要求 —— 两个模式各自在文件
# 某处出现不算（观测过这种拼接式假阳性）。
# 首要 finding 命中 ⇒ 蕴含"想到过"，无需再过词表（否则同一个词表脆弱性会在这里复发一次）。
# 弱命中只用于捕捉"注意到了但没列为首要"，那里没有"这是一条 finding"的语义可依，才退回词表。
if echo "$top" | grep -qiE "$PREMISE" || grep -iE "$PREMISE" "$F" 2>/dev/null | grep -qiE "$FALSY"; then
  p=$((p+1)); add considered true "OUTCOME 中质疑过那条被声明的现状前提（即使未列为首要 finding）"
else
  add considered false "整份 OUTCOME 从未质疑那条被声明的现状前提——声明即免检"
fi

P=$p T=$t python3 -c '
import json,os
rows=[]
for line in open("/tmp/.pcite_checks",encoding="utf-8"):
    n,ok,msg=line.rstrip("\n").split("\t",2)
    rows.append({"name":n,"passed":ok=="true","message":msg})
p,t=int(os.environ["P"]),int(os.environ["T"])
# 输出形状对齐仓内既有 grader（"score":1.00，冒号后无空格、两位小数）——self-test.sh 用 sed 按该形状抽分。
checks=json.dumps(rows,ensure_ascii=False,separators=(",",":"))
print("{\"score\":%.2f,\"details\":\"%d/%d checks\",\"checks\":%s}" % (p/t,p,t,checks))
'
rm -f /tmp/.pcite_checks
