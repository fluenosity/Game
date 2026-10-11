# Production Risk Register — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Producer & Technical Director  
> **Related Documents:** [EXPLOIT_THREAT_MODEL.md](file:///i:/RobloxDev/docs/technical/EXPLOIT_THREAT_MODEL.md), [PERFORMANCE_AND_MOBILE.md](file:///i:/RobloxDev/docs/technical/PERFORMANCE_AND_MOBILE.md)

---

## 1. Risk Matrix & Scoring Methodology

Risks are evaluated by multiplying **Impact (1–5)** by **Likelihood (1–5)** to produce a Risk Severity Score (1–25):
- **16–25 (Critical):** Requires immediate active mitigation and technical safeguards.
- **10–15 (Major):** Actively monitored with documented contingency plans.
- **1–9 (Moderate/Minor):** Managed within standard development sprints.

---

## 2. Active Risk Register Table

| Risk ID | Category | Risk Description | Imp (1-5) | Lik (1-5) | Score (1-25) | Mitigation Strategy | Contingency Plan | Owner |
|:-------:|:--------:|------------------|:---------:|:---------:|:------------:|---------------------|------------------|:-----:|
| **RSK-01** | Platform / Mobile | Low-end mobile devices crash due to iOS/Android Out-of-Memory (OOM) errors during dense night scenes. | 5 | 4 | **20** (Critical) | Enforce `StreamingEnabled = true`, limit memory to < 900 MB, cap textures at 512×512, low-poly LOD models. | Automatic fallback to ShadowMap lighting and disabled fog on low-memory detection. | Client Lead |
| **RSK-02** | Design / Market | Accusations of copying competitor *99 Nights in the Forest*. | 4 | 4 | **16** (Critical) | Distinguish with active fuel depletion mechanic, 5-day escape arc (not 99 nights), urban prologue, and original monster ("The Hollow"). | Emphasize story and extraction mechanics in game trailers and branding. | Creative Director |
| **RSK-03** | Technical / AI | Monster pathfinding freezes or clips through shelter fences, ruining horror tension. | 4 | 3 | **12** (Major) | Server-side stuck detection routine automatically re-paths or shadow-teleports monster after 4.0s stall. | Hardcode invisible navmesh barriers and secondary raycast collision sweep. | AI Lead |
| **RSK-04** | Security / Economy | Item duplication or speed hacking breaks resource scarcity and trivialize survival. | 4 | 3 | **12** (Major) | 100% server-authoritative inventory transactions, transaction mutex locks, and movement velocity clamping. | Server-side kick/ban telemetry for flagrant remote event spamming. | Security Lead |
| **RSK-05** | Balancing | Solo gameplay is excessively punishing or 5-player co-op becomes trivially easy. | 3 | 4 | **12** (Major) | Dynamic party scaling: adjust wood yield, fuel burn rates, and monster stun thresholds based on player count. | Tuning values isolated in `BalanceConfig.lua` for zero-downtime hotfix updates. | Systems Lead |
| **RSK-06** | Data / Persistence | DataStore throttling or Roblox outage corrupts player profile balances. | 5 | 2 | **10** (Major) | Utilize `ProfileService` with session locking and 5-retry exponential backoff; write only on match end. | Staged rollback snapshots and automated profile repair scripts. | Backend Lead |

---

## 3. Monitoring & Review Frequency

- The Risk Register is reviewed weekly during production standups.
- Any risk with a score >= 16 triggers an immediate sprint priority spike to validate mitigation before feature work continues.
