# Open Questions Register — Project: Undecided

> **Status:** Active Tracking  
> **Last updated:** 2026-10-11  
> **Owner:** Lead Game Designer & Project Director  
> **Related Documents:** [DECISION_LOG.md](file:///i:/RobloxDev/docs/decisions/DECISION_LOG.md), [00_PROJECT_STATUS.md](file:///i:/RobloxDev/docs/00_PROJECT_STATUS.md)

---

## 1. Active Open Questions

| ID | Category | Question | Options Under Consideration | Current Recommendation | Decision Gate |
|:--:|:--------:|----------|-----------------------------|------------------------|:-------------:|
| **Q-01** | Branding | What should the official game title be? (Currently `Project: Undecided`) | 1. *Don't Let the Fire Die*<br>2. *Keep the Flame*<br>3. *Into the Ash*<br>4. *The Hollow Forest* | **Don't Let the Fire Die** (High search clarity, strong immediate player mandate) | Project Owner Signoff |
| **Q-02** | Campaign Length | Should the primary game mode be a finite 5-day escape or an endless survival mode? | 1. Strict 5-day escape campaign<br>2. Infinite survival until death<br>3. Hybrid (5-day story + Endless unlock) | **Hybrid:** 5-day campaign as core narrative experience, unlocking "Endless Survival" upon first clear | Project Owner Signoff |
| **Q-03** | Communication | Should spatial voice chat (Roblox Voice) be mandatory or supplemented with ping wheels? | 1. Voice chat priority<br>2. Universal ping wheel system | **Universal ping system** (Crucial because >60% of mobile players have voice chat disabled or are under 13) | Alpha Playtest |
| **Q-04** | Trader Presence | Does Silas the Trader stay at the shelter overnight if players give him shelter? | 1. Departs strictly before dusk<br>2. Can pay 2 Wood to board him inside shelter | **Departs before dusk:** Forces players into solitary night defense without relying on an invincible NPC | Vertical Slice Playtest |
| **Q-05** | Save Mid-Run | Should players be able to leave on Day 3 and resume later with the same party? | 1. Full run must be played in 1 session (50 mins)<br>2. Checkpoint saves at Day 3 dawn | **Run-based (single session)** for public matchmaking; Checkpoint saves reserved for Private/VIP servers | Production Phase 2 |

---

## 2. Decision Protocol

When an open question is resolved:
1. The resolution is moved into `DECISION_LOG.md` with full rationale and downstream impact.
2. The status is updated to `APPROVED` or `DEPRECATED`.
3. Related gameplay and technical specifications are updated to reflect the approved choice.
