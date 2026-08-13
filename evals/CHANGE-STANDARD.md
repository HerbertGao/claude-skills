# Skill 改动测试标准(改 skill 前读这条)

**一条总账**:给 skill 加东西,**必须先证明它在「基线真会失败」的 fixture 上带来实质性提升,才值得加**。测不出实质提升 → 不加(默认走简约)。

这条来自 B4 的实测教训(2026-07-24,review-loop):council 一致认为「加跨-artifact 不变量枚举攻 mechanic 洞」有料,但实测基线结构召回 5/5、新增臂边际 **0/5** → 不加。详见 memory `review-loop-b4-council-empirical`。

---

## 1. 先判改动属于哪一类(决定用哪种测试)

| 改动类型 | 价值来自 | 测什么 | 门槛 |
| --- | --- | --- | --- |
| **效果型**(加 lane/step/reviewer,声称「多抓到/改善某指标」) | 一个**可能为零**的经验性检测/行为增量 | **A/B 前后实测**(§2) | 目标类上有**实质边际** |
| **演绎型**(出处/覆盖/一致性检查,构造即正确) | 触发时就一定对,跟平均无关 | **回归 fixture**(§3,skillgrade valid+false-green 对) | 检查在坏例上触发、好例上放过 |
| **可行性/设计型**(平台能力、平台中立取舍) | 「能不能做/合不合设计」,非「有没有用」 | 可行性 spike + 设计决策,**不是** A/B | 决策留痕 |

**判别捷径**:能不能问「它在坏例上多抓到几条?」——能,且答案可能是 0 → 效果型,走 A/B。不能(它是「指向不存在位置就拦」这种构造即对的守卫)→ 演绎型,走回归 fixture。像输入校验:你不会 A/B 测「加校验能不能提升召回」。

---

## 2. 效果型:A/B 实测协议(B4 用的这套)

1. **fixture + 独立 ground truth**:埋 N 条真缺陷,按目标失败类打标签(如 `structural-combinational` vs `local/recomputable`)。**ground truth 由改动提议者之外的人/agent 作者,reviewer 全程看不到**。
2. **两臂,同 fixture**:Arm A = 现状 skill;Arm B = skill + 本改动。
3. **独立盲判官**:不知道哪臂是哪个;把每条 finding **1:1 语义匹配**到 planted 缺陷(一条 finding 只能认领一个缺陷 → **防蒙对**);泛泛「可能有问题」不算命中。
4. **算边际,不算绝对**:核心数字是 **Arm B 抓到、Arm A 漏掉**的目标类缺陷(marginal),不是 Arm B 的绝对召回。B4 就是绝对 4/5 但边际 0/5 → 不值得加。
5. **门槛**:目标类上边际实质 > 0(参照 B4 各席的翻案线 ≥3/5 量级);边际 ≈0 → 拒。

## 3. 演绎型:回归 fixture(接现有 skillgrade harness)

不跑 A/B。在 `evals/<skill>/` 加一对 fixture + 一个确定性 grader(见 SKILLGRADE.md):

- `<mechanism>-valid.md` — 改动**正确处理**坏例时的 OUTCOME(grader 应通过)。
- `<mechanism>-false-green.md` — 一个**看着对、实则漏掉**的 OUTCOME(grader 必须抓住、判失败)。
- grader 里每条改 grader 前先跑 `graders/self-test.sh`(fixture + 假绿探针)。
演绎型改动的「测」= 证明这个检查**在坏例上会触发**,而非证明它平均多抓多少。

---

## 4. 致命前提:fixture 必须复现失败模式(B4 最大教训)

**A/B 只有在「基线真的会在这个 fixture 上失败」时才有意义。** B4 的 fixture 基线拿了 **5/5**(不是 issue #23 记录的 0/5)——因为它是**小而全可见的 5 文件 fixture**,勤勉 reviewer 一屏装下、交叉引用就抓到了。于是那次 A/B 只证明了「新臂在**容易**的输入上冗余」,**没测**它在洞真正咬人时的价值。

规则:

- **跑 A/B 前,先确认基线在该 fixture 上确实掉到接近失败**(如 mechanic 洞类:基线目标类召回 ~0)。基线本就通过 → 这个 fixture 测不出改动价值,换更难的。
- **失败若是规模现象,fixture 必须复现规模压力**,不能只复现「结构形状」。mechanic 洞极可能是**上下文装不下所有 fragment 才漏**——那 fixture 就得大到/碎到基线一次读不完,而不是 5 个短文件。
「埋了跨片段结构缺陷」≠「复现了洞」;还得复现**让基线失败的那个条件**(规模/上下文压力)。

---

## 5. 相关性 caveat(结果怎么读)

- reviewer 与判官常是同一底模穿人格 → **correlated**,「几个都同意/都抓到」是**弱证据**。
- 单 fixture、每臂单跑 = **方向性信号,非 benchmark**。要下强结论:多 trial(skillgrade 默认 5)、多 fixture、尽量跨模型家族。
- 记录:reviewer/judge 的模型、trial 数、fixture 是否验证过复现失败。

---

## 6. 一页 checklist(改 skill 前过一遍)

- [ ] 这是效果型 / 演绎型 / 设计型?(§1)
- [ ] 效果型:有没有一个**基线真会失败**的 fixture?(§4,先验证再信结果)
- [ ] 效果型:算的是**边际**(B 抓到、A 漏掉)吗?独立盲判官 + 1:1 防蒙对?(§2)
- [ ] 演绎型:有没有 valid + false-green 回归对 + 确定性 grader?(§3)
- [ ] 边际 ≈0 / 检查不触发 → **不加**,如实记录(别为「感觉有用」硬加)。
- [ ] 结果标注 correlated + trial 数 + fixture 是否复现失败。(§5)
