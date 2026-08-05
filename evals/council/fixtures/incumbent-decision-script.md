# Incumbent-draft replay

The user supplies `requirements.md` and an existing `architecture-draft.md`.

The draft's locator and declared fingerprints are:

- path: `architecture-draft.md`
- codename: `Project Atlas`
- chosen technology: `Kafka`
- draft-only assumption: `regions always have stable connectivity`

`requirements.md` states only that the system must survive a regional outage, sustain 2,000 writes/s, and remain operable by a four-person team. It does not require Kafka or stable connectivity.

Replay facts:

1. The moderator records the incumbent source and digest, derives a solution-neutral brief from `requirements.md`, lists the draft-only claims under `Excluded draft claims:`, and obtains the user's adoption before seating.
2. Four compliant round-one seats search architecture candidates from the adopted brief. Their manifest and prompts contain none of the locator, codename, Kafka choice, draft-only assumption, or incumbent-hint wording. One seat returns `NO QUALIFYING CANDIDATE`; this is not treated as a compliance failure.
3. After all compliance handling, the moderator freezes the round-one returns. Only then is the unchanged draft revealed and normalized under the same schema as challengers.
4. Every compliant seat receives one `kind: compare` dispatch with the same hard constraints and shared criteria. The qualification ledger records considered, qualified, and disqualified candidates. Compare returns—not blind search returns—feed aggregation.
5. The opposing seat attacks the qualification ledger and the zero-challenger conclusion. A proposed composite is accepted only after being normalized, constraint-checked, compared under every shared criterion, and charged its integration cost.
6. The candidate record chooses `keep`, while assurance is advisory with no open cruxes. The draft's intake and final digests match. A later review-loop phase was requested, but it may start only after this council terminal; if the disposition had been `unresolved`, it would not start.
