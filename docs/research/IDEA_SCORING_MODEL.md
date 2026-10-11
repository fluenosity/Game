# Idea Scoring & Evaluation Model — Project: Undecided

> **Status:** `APPROVED`  
> **Last updated:** 2026-10-11  
> **Lead:** Lead Research Analyst & Systems Lead  
> **Related Documents:** [IDEA_TAXONOMY.md](file:///i:/RobloxDev/docs/research/IDEA_TAXONOMY.md), [TOP_10_RECOMMENDATIONS.md](file:///i:/RobloxDev/docs/research/TOP_10_RECOMMENDATIONS.md)

---

## 1. Weighted Evaluation Criteria

To systematically evaluate candidate ideas from the 10,000-idea research catalog, proposals are evaluated across 8 weighted criteria (scored 1 to 5):

| # | Evaluation Criterion | Weight | Scoring Focus (What a '5' Means) |
|---|----------------------|:------:|----------------------------------|
| **1** | **Meaningful Differentiation** | **20%** | Sets the game radically apart from *99 Nights* and standard clones. |
| **2** | **Fun & Horror Tension** | **20%** | Generates visceral suspense, dread, panic, or satisfying triumphs. |
| **3** | **Technical Feasibility** | **15%** | Readily implementable within Roblox engine constraints without extreme R&D. |
| **4** | **Mobile & Input Usability** | **10%** | Effortless and intuitive on touchscreen mobile devices (>=60% of player base). |
| **5** | **Co-op & Solo Parity** | **10%** | Equally compelling and balanced for 1 player or 5 players. |
| **6** | **Replayability & Retention**| **10%** | Drives desire to replay subsequent campaigns or try challenge mutators. |
| **7** | **Alignment with Vision** | **10%** | Strictly adheres to the 4 core design pillars (Show Don't Tell, Fire is Life). |
| **8** | **Performance & Efficiency** | **5%** | Negligible CPU/memory impact on budget smartphones (< 900 MB RAM budget). |
| | **TOTAL** | **100%** | |

---

## 2. Weighted Score Formula

```text
Weighted Score = SUM(Weight_i × (Rating_i / 5.0)) × 100
```
- The maximum possible score is **100.0**.
- Ideas scoring **>= 85.0** advance to the **Top 100 Shortlist**.
- Top 100 candidates undergo dependency synergy and conflict analysis to produce the **Top 30 Candidates** and final **Top 10 Recommendations**.

---

## 3. Mandatory Risk Gates (Disqualification Rules)

Regardless of aggregate score, an idea is immediately disqualified or flagged if it:
1. **Pay-to-Win:** Sells survival advantages, infinite fuel, or damage boosts for Robux.
2. **Performance Killer:** Exceeds mobile memory or draw call limits on low-end hardware.
3. **Severe Exploit Vector:** Relies on client physics authority or client-reported values.
4. **Complexity Bloat:** Adds excessive menu micro-management without adding fun survival decisions.
