# Idea Generation & Validation Protocol — Project: Undecided

> **Status:** `APPROVED`  
> **Last updated:** 2026-10-11  
> **Lead:** Lead Research Analyst & Systems Designer  
> **Related Documents:** [IDEA_TAXONOMY.md](file:///i:/RobloxDev/docs/research/IDEA_TAXONOMY.md), [IDEA_SCORING_MODEL.md](file:///i:/RobloxDev/docs/research/IDEA_SCORING_MODEL.md)

---

## 1. Protocol Objective

The purpose of generating **10,000 distinct candidate ideas** is not to build a bloated game with 10,000 mechanics. The objective is to build an exhaustive, auditable **ideation search space** that forces our team to explore every nuance of survival horror, base engineering, monster AI, accessibility, and retention before shortlisting the definitive Top 10 recommendations.

---

## 2. Generation & Validation Pipeline

```text
 ┌────────────────────────────────────────────────────────┐
 │ 1. CATEGORY TARGETING                                  │
 │    Allocate target quotas across the 15 categories.    │
 └──────────────────────────┬─────────────────────────────┘
                            ▼
 ┌────────────────────────────────────────────────────────┐
 │ 2. BATCH GENERATION                                    │
 │    Generate candidate records with unique sequential   │
 │    IDs (`IDEA-00001` through `IDEA-10000`).            │
 └──────────────────────────┬─────────────────────────────┘
                            ▼
 ┌────────────────────────────────────────────────────────┐
 │ 3. DEDUPLICATION FILTER                                │
 │    - Exact title match check.                          │
 │    - Semantic mechanic overlap check.                  │
 │    - Trivial cosmetic / name swaps rejected.           │
 └──────────────────────────┬─────────────────────────────┘
                            ▼
 ┌────────────────────────────────────────────────────────┐
 │ 4. SCHEMA & CONSTRAINT VALIDATION                      │
 │    - All 13 schema fields populated.                   │
 │    - Scores within valid 1–5 range.                    │
 │    - Sizing: S / M / L / XL.                           │
 └──────────────────────────┬─────────────────────────────┘
                            ▼
 ┌────────────────────────────────────────────────────────┐
 │ 5. PERSISTENT STORAGE & AUDIT                          │
 │    Commit to IDEA_CATALOG.csv and update Quality Report│
 └────────────────────────────────────────────────────────┘
```

---

## 3. Mandatory Record Schema

Every record in `IDEA_CATALOG.csv` must satisfy this comma-separated format:

```csv
id,category,title,mechanic,player_value,differentiation,effort,dependencies,risk,novelty_score,fun_score,feasibility_score,status
```

1. `id`: Sequential `IDEA-XXXXX` format.
2. `category`: One of the 15 defined taxonomy categories.
3. `title`: Concise, searchable feature name.
4. `mechanic`: Exact description of the gameplay mechanic (what it actually does).
5. `player_value`: Why this enhances the player's emotional or survival experience.
6. `differentiation`: How it distinguishes the game from competitors.
7. `effort`: S (Small), M (Medium), L (Large), XL (Extra-Large).
8. `dependencies`: Underlying game systems or assets required.
9. `risk`: Primary design, balance, or exploit risk.
10. `novelty_score`: 1 to 5.
11. `fun_score`: 1 to 5.
12. `feasibility_score`: 1 to 5.
13. `status`: `candidate`, `shortlisted`, `rejected`, or `approved`.
