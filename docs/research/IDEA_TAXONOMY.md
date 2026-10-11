# Idea Research Framework — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Idea Taxonomy

Ideas are categorized into these primary research areas:

| # | Category | Description | Target Ideas |
|---|----------|-------------|-------------|
| 1 | Core Gameplay | Survival rules, tradeoffs, risk/reward | ~800 |
| 2 | Fire, Light, Darkness | Fire behavior, fuel, light sources, darkness mechanics | ~700 |
| 3 | Monster & Threats | Behavior, detection, escalation, new threats | ~800 |
| 4 | Co-op & Social | Roles, teamwork, social mechanics | ~600 |
| 5 | World & Level Design | Landmarks, environments, exploration | ~700 |
| 6 | Campaign & Narrative | Story, lore, endings, day-by-day events | ~600 |
| 7 | Resources & Production | Gathering, crafting, trading, economy | ~700 |
| 8 | Environmental Systems | Weather, wind, rain, dynamic events | ~500 |
| 9 | Progression & Replayability | Unlocks, difficulty, achievements, replay | ~600 |
| 10 | Presentation & Horror | Audio, visual, camera, atmosphere | ~700 |
| 11 | UX & Accessibility | Tutorial, controls, readability, comfort | ~500 |
| 12 | Technical Enhancements | AI, networking, performance, tools | ~500 |
| 13 | Abuse Prevention | Exploits, griefing, fairness | ~400 |
| 14 | Retention & Monetization | Ethical cosmetics, engagement, events | ~400 |
| 15 | Additional Discovery | Emergent gameplay, community, streaming | ~400 |
| | **Total Target** | | **~10,000** |

---

## Idea Record Schema

Every idea follows this schema:

```
id: IDEA-XXXXX (sequential, 00001–10000)
category: Primary research category
title: Distinct, searchable name
mechanic: What the feature actually does (1–2 sentences)
player_value: Why this improves the experience
differentiation: How it distinguishes the game
effort: S / M / L / XL
dependencies: Required systems or assets
risk: Principal design or technical risk
novelty_score: 1–5 (how original is this?)
fun_score: 1–5 (how fun would this be?)
feasibility_score: 1–5 (how achievable in Roblox?)
status: candidate / shortlisted / rejected / approved
```

---

## Scoring Model (for Top 100/30/10 evaluation)

| Criterion | Weight | Scale |
|-----------|--------|-------|
| Meaningful differentiation | 20% | 1–5 |
| Moment-to-moment fun and horror tension | 20% | 1–5 |
| Technical feasibility | 15% | 1–5 |
| Mobile and input usability | 10% | 1–5 |
| Cooperative and solo gameplay quality | 10% | 1–5 |
| Replayability and long-term interest | 10% | 1–5 |
| Alignment with game vision | 10% | 1–5 |
| Performance and implementation efficiency | 5% | 1–5 |

**Weighted score = SUM(weight × rating / 5) × 100**

Maximum score: 100. Minimum meaningful threshold: 60.

---

## Generation Protocol

### Batch Process

1. Generate 100–250 ideas per batch.
2. Assign sequential IDs (IDEA-00001, IDEA-00002, ...).
3. Validate all fields are populated.
4. Check for duplicates (by mechanic, not just title).
5. Replace duplicates with new unique ideas.
6. Save batch to persistent storage.
7. Update running count and quality report.

### Deduplication Rules

Two ideas are duplicates if they share:
- Same primary mechanic AND same player action AND same consequence.
- Changing only the name, color, or resource type does NOT make an idea unique.
- Ideas in different categories can still be duplicates if the core mechanic is the same.

### Quality Rules

Every idea must:
- Describe an understandable mechanic.
- Have a plausible player-facing benefit.
- Fit the Roblox platform.
- Be distinct from other candidates.
- Identify at least one dependency and one risk.

---

## Idea Catalog Format

The catalog is stored as `IDEA_CATALOG.csv` (or `.jsonl` for large volumes).

### CSV Header

```
id,category,title,mechanic,player_value,differentiation,effort,dependencies,risk,novelty_score,fun_score,feasibility_score,status
```

### Progress Tracking

| Metric | Value |
|--------|-------|
| Total target | 10,000 |
| Completed batches | See IDEA_QUALITY_REPORT.md |
| Valid distinct ideas | See IDEA_QUALITY_REPORT.md |
| Remaining | See IDEA_QUALITY_REPORT.md |

---

## Evaluation Pipeline

```
10,000 ideas → Broad screening → ~500 pass → Detailed briefs for Top 100
    → Weighted scoring → Top 30 → Combination analysis → Top 10 recommendations
```

See:
- [TOP_100_CANDIDATES.md](./TOP_100_CANDIDATES.md)
- [TOP_30_CANDIDATES.md](./TOP_30_CANDIDATES.md)
- [TOP_10_RECOMMENDATIONS.md](./TOP_10_RECOMMENDATIONS.md)
