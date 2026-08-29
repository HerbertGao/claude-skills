# Incumbent-draft decision mode

Read this file completely when an architecture or technology decision has an existing draft and the requested terminal is a choice rather than an edit. This mode changes candidate discovery and comparison; the main `SKILL.md` still governs seating, debate, capability disclosure, assurance, human value rulings, and terminal tokens.

## Routing boundary

| Input and requested terminal | Route |
| --- | --- |
| No draft; choose an architecture or technology | council, `greenfield` |
| Draft exists; decide whether to keep, replace, combine, or remain unresolved | council, `incumbent-draft` |
| Draft exists; find and fix defects until `APPROVE` | review-loop |
| Both choose and revise | council first; after its terminal, review-loop uses the decision record as a constraint |

If the council leaves the architecture decision unresolved, stop before the review-loop phase. Council never edits the incumbent. A later review-loop phase may edit only after the council phase has ended and the user's request authorizes that phase.

## Intake and neutral-brief adoption

Before seating or any specialist dispatch:

1. Record `decision mode: incumbent-draft`, `incumbent source: <path or user-supplied artifact>`, its SHA-256 digest when file-backed, and the user-provided `brief sources` from which candidate-independent requirements may be derived. In audited mode also pin this reference as `incumbent-procedure: <absolute path> · version/commit:<id> · sha256:<digest>` in the §0 opening block and every auditor payload.
2. Build one `Neutral brief:` containing the decision question, goals, hard constraints with source citations, non-goals, candidate-independent truth sources, and shared comparison criteria. Criteria must cover at least fitness to hard constraints, complexity, evolvability, reliability/failure behavior, operating cost, and reversibility; add domain criteria only when a cited source requires them.
3. Emit `Incumbent fingerprints:` outside the round-one manifest: the source locator, distinctive option/technology names, quoted eight-word spans that describe the chosen design, and every draft-only assumption. This list is a mechanical leakage floor, not proof of semantic neutrality.
4. A design choice or assumption appearing only in the incumbent is **not** a requirement. Put it under `Excluded draft claims:` unless the human restates or adopts it in solution-neutral language. The moderator may propose neutral wording, but must show the draft origin beside it.
5. Ask one adoption question with exactly three outcomes: adopt this neutral brief; request changes; stop. A change rebuilds and re-presents the brief. Adoption must precede seating and be copied verbatim into `Brief adoption:`. No answer is `STOPPED (awaiting human)`.

The moderator has read the draft and cannot become psychologically blind. Source citations, explicit exclusions, human adoption, and exact fingerprint scans reduce anchoring; they do not prove semantic neutrality. Record that limit in the decision's Assurance section.

## Candidate search and incumbent exposure

Derive axes, named gaps, the proposition, and the shared round-one truth-source baseline only from the adopted neutral brief. Before producing positions, record one capability value:

- `incumbent-exposure: inaccessible` — the route structurally cannot receive or open the incumbent. This is required for audited challenger-independence claims.
- `incumbent-exposure: not-supplied` — the seat-facing prompt/pass omits the incumbent, but structural inaccessibility is not proven. Advisory only; record the `incumbent-exposure` assurance gap and do not call it blind.
- `incumbent-exposure: visible` — inherited/shared context, prompt content, or observed access exposes the incumbent. Continue as draft-visible advisory search and comparison.
- `incumbent-exposure: unknown` — exposure cannot be determined. Treat it like visible for claims.

For `inaccessible` and `not-supplied`, `Round-1 manifest:` and every first functional round-one prompt/pass, retry, and compliance re-dispatch exclude:

- the incumbent source locator, body, digest, and every declared fingerprint;
- draft-only assumptions or criteria;
- wording such as `incumbent`, `existing draft`, `current design`, or `challenge the current design`;
- another seat's candidate, return, path, or position.

For `visible` or `unknown`, still derive the question, hard constraints and shared criteria only from the adopted neutral brief. Incumbent knowledge may inform a candidate search but cannot promote a draft-only claim, narrow the search quota, change a shared criterion, or count as challenger independence.

Each round-one seat performs candidate search. Append this contract to the normal §2 position:

```text
Candidate search:
- considered: <candidate pattern> -> <qualifies | disqualified: criterion + evidence>
Candidate: <normalized candidate | NO QUALIFYING CANDIDATE>
```

A normalized candidate contains: candidate id; topology/components and data flow; how it satisfies each hard constraint; principal trade-offs; assumptions; and evidence or an observable falsifier. A seat may honestly return `NO QUALIFYING CANDIDATE`; it may not weaken a hard constraint or manufacture a straw candidate to fill the matrix. The ordinary compliance retry applies when search evidence or a required field is absent.

After every round-one seat/pass is terminal and compliance handling is complete, emit exactly one search-completion record with the included dispatch/pass ids or digests. For `inaccessible` or `not-supplied`, name it `Round-1 returns frozen:` and perform no later round-one retry before reveal. For `visible` or `unknown`, name it `Round-1 search complete:` and record `reveal: already-visible`; never claim freeze/reveal ordering proved candidate independence.

`Round-1 returns frozen` binds those returns, their shared inputs, and retry/reveal ordering — not unrelated repository paths. Apply the main skill's `Concurrent-write review` to any delta. An irrelevant Harness/external delta may be disclosed and rebaselined. A change to the adopted brief or shared baseline requires a fresh-nonce restart before reveal; a changed incumbent remains the existing non-waivable digest integrity failure.

## Normalize, qualify, and compare

After the search-completion record:

1. Emit `Incumbent reveal:` after `Round-1 returns frozen:` for `inaccessible`/`not-supplied`, or `Incumbent normalization (already visible):` for `visible`/`unknown`. Include the source locator, intake digest, current digest, and a source-cited normalized representation using the same candidate schema. A digest change is an integrity failure.
2. Deduplicate challengers without erasing their search provenance or exposure status. Build `Qualification ledger:` with every considered candidate and either `qualified` or the hard constraint/evidence that disqualified it. Zero qualified challengers is legal when every compliant seat searched and every rejection is recorded.
3. Produce one `kind: compare` position per compliant seat. Give each seat the adopted brief, unchanged shared criteria, equal-format incumbent and challenger representations, qualification ledger, its own round-one position, and all candidates' search provenance.
4. Require this compare return:

```text
Qualification corrections: <candidate + evidence | none>
Comparison matrix: <every qualified candidate × every shared criterion>
Preference: <keep | replace <candidate-id> | combine <candidate-ids> | unresolved>
Reasons: <1-3 labeled reasons under the main §2 contract>
Strongest argument against my preference: <mandatory>
What would change my mind: <main §2 form>
```

For this mode the **decision-base return** is each seat's compliant compare return, not its round-one candidate search. §3's bins, provenance, fact criteria, value mapping, cross-examination, DA, DA-final, and consensus quantifier consume decision-base returns. Only `incumbent-exposure: inaccessible` may support an audited challenger-independence claim; search is never a vote against the incumbent.

`combine` is not a compromise shortcut. Normalize the composite as its own candidate, check every hard constraint, score every shared criterion, and state integration and complexity costs. Otherwise the preference is non-compliant.

DA's additive targets also include the qualification ledger and any `no qualifying challenger` conclusion. It must attack search coverage and disqualification evidence. If those targets are broken, reopen candidate qualification before selection.

## Decision record and terminal semantics

Add these fields to §8:

```text
Decision mode: incumbent-draft
Incumbent decision: <keep|replace|combine|unresolved>
Incumbent exposure: <inaccessible|not-supplied|visible|unknown> · challenger independence claimed <yes|no>
Incumbent digest: intake sha256:<digest> · final sha256:<digest> · unchanged <yes|no>
Candidates: considered <n> · qualified <n> · disqualified <n>
```

The Decision section names the selected challenger or composite and traces it through the comparison matrix. `keep`, `replace`, `combine`, and `unresolved` are decision-record values, never terminal tokens. Assurance still uses only `CONVERGED`, `ADVISORY (…)`, `UNRESOLVED (…)`, or `STOPPED (…)`.

A council can debate-converge on `Incumbent decision: unresolved` when the decision-base positions leave no current candidate qualified. Do not convert agreement into support or the disposition into a fabricated selection. The record includes the adopted brief, adoption response, fingerprints, exposure, search-completion record, qualification ledger, matrix, and the explicit sentence `Incumbent draft edited: no`.

Append to the Quality line: `decision-mode incumbent-draft | incumbent <keep|replace|combine|unresolved> | challengers <qualified>/<considered> | incumbent-exposure <inaccessible|not-supplied|visible|unknown> | freeze <yes|no> | reveal <after-freeze|already-visible>`.

## Audit additions

In audited mode the fresh auditor runs the main A0–A9 checks plus this separate I0–I5 namespace:

- **I0 — blind ordering:** audited mode requires `incumbent-exposure: inaccessible`; verify the incumbent-procedure pin, adoption → manifest → round-one dispatches → freeze → reveal → compare ordering; `compare` is seat-facing. Exact-scan every round-one manifest/prompt for the locator, fingerprints, draft-only claims, and forbidden incumbent-hint wording. Leakage, another exposure value, or reveal before freeze is fabrication.
- **I1 — incumbent intake:** verify the neutral brief and platform-authored adoption predate seating; every hard constraint cites a brief source; every draft-origin claim is excluded or separately adopted in solution-neutral language. Fabricated or missing adoption is fabrication.
- **I2 — qualification:** recompute qualification and aggregation from candidate-search plus decision-base returns; verify incumbent, challengers, and composites use the same constraints and criteria.
- **I3 — source integrity:** compare incumbent quotations and normalized fields with the source at the intake digest.
- **I4 — adversarial coverage:** verify DA attacked the qualification ledger and any zero-challenger conclusion, and that every broken target reopened qualification.
- **I5 — record and read-only gate:** reconcile decision mode, counts, freeze/reveal, one compare dispatch per compliant seat, disposition, `compare` in the model census, and every `Concurrent-write review`; verify intake digest equals final digest, no tool wrote the incumbent, and the record says `Incumbent draft edited: no`.

I0 or I1 failure takes the main fabrication path with no re-audit. Exact scans cannot detect every paraphrase or moderator bias; disclose that audit floor rather than claiming perfect blindness. Advisory mode skips I0–I5 regardless of exposure and must not borrow their claims.
