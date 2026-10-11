# Playtest Plan & Feedback Protocol — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Game Producer & User Research Lead  
> **Related Documents:** [QA_AND_ACCEPTANCE_CRITERIA.md](file:///i:/RobloxDev/docs/production/QA_AND_ACCEPTANCE_CRITERIA.md), [TELEMETRY_AND_ANALYTICS.md](file:///i:/RobloxDev/docs/technical/TELEMETRY_AND_ANALYTICS.md)

---

## 1. Playtesting Strategy & Phases

Structured playtests validate player emotion, tension, pacing, and difficulty balance before releasing to the broader public.

```text
[Phase 1: Internal Dev Smoke] ──► Core mechanics & stability check (1–3 testers)
              │
[Phase 2: Closed Friends & Family] ──► Onboarding & mobile usability (10–15 testers)
              │
[Phase 3: Creator Alpha Cohort] ──► Horror pacing & replayability (50 Roblox horror fans)
              │
[Phase 4: Open Soft-Launch Beta] ──► Large-scale telemetry & server stress (500+ players)
```

---

## 2. Core Playtest Hypotheses to Validate

| # | Hypothesis Under Test | Verification Method | Target Metric |
|---|----------------------|---------------------|---------------|
| **H1** | New players intuitively understand that fire protects them without reading instructions. | Screen recording / Telemetry | >90% of players reach the fire within 45s of Day 1 dusk |
| **H2** | Fuel management feels tense rather than like a tedious chore. | Post-session questionnaire | >80% rate fuel mechanic as "Exciting / Tense" |
| **H3** | The Hollow creates genuine horror dread rather than frustrating annoyance. | Qualitative feedback + telemetry | <10% rage-quits following a monster encounter |
| **H4** | Solo players can survive Day 1 without unfair difficulty spikes. | Telemetry win/loss by party size | Solo Night 1 win rate between 65%–75% |
| **H5** | A 5-day campaign completion time lands within 45–65 minutes. | Session duration analytics | Median winning session duration = 52 minutes |

---

## 3. Post-Playtest Questionnaire (Standardized)

1. *On a scale of 1–5, how tense did you feel when night arrived?*
2. *Did you ever feel a monster attack was unfair or unavoidable? If yes, what happened?*
3. *Was it clear what resources were needed to upgrade the campfire and shelter?*
4. *Did you experience any lag, touch control issues, or confusion while playing on mobile?*
5. *Would you want to play another 5-day run immediately with friends? Why or why not?*

---

## 4. Acceptance Criteria

- [ ] **AC-TEST-01:** Closed Alpha test completes at least 25 full 5-day runs with telemetry logged.
- [ ] **AC-TEST-02:** At least 40% of playtesters are verified mobile device users.
- [ ] **AC-TEST-03:** Qualitative survey insights are compiled into a formal Playtest Summary Report within 48 hours of testing.
