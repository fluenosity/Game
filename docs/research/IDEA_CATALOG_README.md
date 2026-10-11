# Idea Research Catalog (10,000 Ideas) — Project: Undecided

> **Status:** Research Database  
> **Last updated:** 2026-10-11  
> **Database File:** [IDEA_CATALOG.csv](file:///i:/RobloxDev/docs/research/IDEA_CATALOG.csv)  
> **Related Documents:** [IDEA_QUALITY_REPORT.md](file:///i:/RobloxDev/docs/research/IDEA_QUALITY_REPORT.md), [IDEA_SCORING_MODEL.md](file:///i:/RobloxDev/docs/research/IDEA_SCORING_MODEL.md)

---

## 1. Database Overview

The Idea Catalog is a structured research repository containing **10,000 distinct candidate improvements** for *Project: Undecided*. It systematically explores design permutations across all 15 survival horror categories defined in [IDEA_TAXONOMY.md](file:///i:/RobloxDev/docs/research/IDEA_TAXONOMY.md).

---

## 2. Format & Schema Specifications

The database is stored in standard CSV format (`IDEA_CATALOG.csv`) with UTF-8 encoding:

| Field Index | Column Name | Type | Description |
|:-----------:|-------------|------|-------------|
| 1 | `id` | String | Sequential identifier (`IDEA-00001` through `IDEA-10000`) |
| 2 | `category` | String | One of the 15 research taxonomy categories |
| 3 | `title` | String | Searchable feature name |
| 4 | `mechanic` | String | Exact description of what the mechanic does |
| 5 | `player_value` | String | Psychological / survival value to the player |
| 6 | `differentiation` | String | Strategic differentiation factor |
| 7 | `effort` | String | Relative sizing: `S`, `M`, `L`, `XL` |
| 8 | `dependencies` | String | Required underlying systems or assets |
| 9 | `risk` | String | Principal design, balance, or exploit risk |
| 10 | `novelty_score` | Integer | Preliminary score from 1 to 5 |
| 11 | `fun_score` | Integer | Preliminary score from 1 to 5 |
| 12 | `feasibility_score` | Integer | Preliminary score from 1 to 5 |
| 13 | `status` | String | `candidate`, `shortlisted`, `rejected`, `approved` |

---

## 3. Auditing & Programmatic Verification

To verify the integrity and uniqueness of the catalog, run the automated Python audit script:

```bash
python scripts/validate_catalog.py
```

This verifies:
1. Exact row count equals 10,000 valid records.
2. Zero duplicate IDs.
3. Zero exact duplicate titles.
4. Zero missing or malformed fields.
5. All 15 taxonomy categories meet minimum representation quotas.
