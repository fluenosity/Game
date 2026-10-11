# Top 10 Feature Recommendations — Project: Undecided

> **Status:** `RECOMMENDATIONS FOR PROJECT OWNER APPROVAL`  
> **Last updated:** 2026-10-11  
> **Scoring Standard:** [IDEA_SCORING_MODEL.md](file:///i:/RobloxDev/docs/research/IDEA_SCORING_MODEL.md) (Weights: Differentiation 20%, Fun 20%, Feasibility 15%, Mobile 10%, Co-op 10%, Replay 10%, Vision 10%, Perf 5%)  
> **Database Source:** [IDEA_CATALOG.csv](file:///i:/RobloxDev/docs/research/IDEA_CATALOG.csv) (500 Curated Deduplicated Ideas Evaluated)

---

## Executive Summary

From the 500 distinct candidate records analyzed in the research catalog, these ten proposals represent the highest-synergy, highest-differentiation features for *Project: Undecided*. Together, they form a cohesive, implementation-ready survival horror experience that sets the game decisively apart from competitors like *99 Nights in the Forest*.

---

## The Ten Signature Proposals

### 1. Noise meter (`IDEA-00003`)
- **Weighted Score:** **82.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Core Gameplay` | **Relative Effort:** `M`
- **The Core Mechanic:** A visible noise meter shows how much sound the player is making. Running/chopping raises it.
- **Player-Facing Value:** Adds stealth decision-making during monster encounters.
- **Competitive Differentiation:** Unique for Roblox survival horror.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Monster AI audio detection`
- **Principal Design Risk:** `May confuse new players; needs good UI`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 2. Risk vs reward chests (`IDEA-00010`)
- **Weighted Score:** **82.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Core Gameplay` | **Relative Effort:** `M`
- **The Core Mechanic:** Locked chests scattered in the forest. Opening takes 10s (loud noise attracts monster). Contains rare resources.
- **Player-Facing Value:** Creates high-tension decision moments: open the chest or run?
- **Competitive Differentiation:** Classic risk/reward that creates memorable moments.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Chest spawner; monster audio detection; loot tables`
- **Principal Design Risk:** `Loot might unbalance economy`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 3. Resource degradation (`IDEA-00018`)
- **Weighted Score:** **70.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Core Gameplay` | **Relative Effort:** `S`
- **The Core Mechanic:** Wood stored outside gets damp over multiple days. Must be stored properly to maintain quality.
- **Player-Facing Value:** Adds storage management and planning between days.
- **Competitive Differentiation:** Uncommon but realistic survival mechanic.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Storage system; resource quality attribute`
- **Principal Design Risk:** `Adds complexity without clear fun`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 4. Breaking point mechanic (`IDEA-00025`)
- **Weighted Score:** **78.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Core Gameplay` | **Relative Effort:** `S`
- **The Core Mechanic:** If the player takes damage their character visibly limps/slows. Healing removes the effect.
- **Player-Facing Value:** Visual damage feedback that increases tension during chases.
- **Competitive Differentiation:** Adds drama and stakes to monster encounters.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Animation; health system`
- **Principal Design Risk:** `Could frustrate already-damaged players trying to escape`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 5. Dynamic difficulty adjustment (`IDEA-00032`)
- **Weighted Score:** **75.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Core Gameplay` | **Relative Effort:** `L`
- **The Core Mechanic:** Server secretly tracks player performance and adjusts monster aggression and resource spawns.
- **Player-Facing Value:** Ensures the game is challenging but not impossible for any player.
- **Competitive Differentiation:** Invisible difficulty tuning is best-in-class game design.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Analytics; monster AI; resource spawner`
- **Principal Design Risk:** `Players might feel cheated if discovered; hard to balance`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 6. Last stand mechanic (`IDEA-00040`)
- **Weighted Score:** **83.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Core Gameplay` | **Relative Effort:** `M`
- **The Core Mechanic:** When a player dies their ghost can briefly distract the monster for 5s giving teammates time.
- **Player-Facing Value:** Even death has gameplay utility. Feels heroic.
- **Competitive Differentiation:** Unique death mechanic that reinforces co-op.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Death system; ghost state; monster AI`
- **Principal Design Risk:** `Complex implementation for edge cases`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 7. Smoke signals in co-op (`IDEA-00055`)
- **Weighted Score:** **74.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Fire, Light, Darkness` | **Relative Effort:** `S`
- **The Core Mechanic:** A large fire creates visible smoke during daytime. Co-op partners far away can see it as a beacon.
- **Player-Facing Value:** Visual communication tool for separated players.
- **Competitive Differentiation:** Natural emergent communication mechanic.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Particle system; fire intensity; visibility`
- **Principal Design Risk:** `Only useful in co-op; wasted for solo`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 8. Fire music box (`IDEA-00072`)
- **Weighted Score:** **74.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Fire, Light, Darkness` | **Relative Effort:** `M`
- **The Core Mechanic:** Craftable item that plays calming music and emits light (4 stud radius) for 180s. Placed at shelter or in forest.
- **Player-Facing Value:** Atmospheric defense tool with audio element.
- **Competitive Differentiation:** Charming item that fits the cozy-horror contrast.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Crafting; audio; light system`
- **Principal Design Risk:** `Music might break horror atmosphere`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 9. Offspring/lesser threats (`IDEA-00088`)
- **Weighted Score:** **83.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Monster & Threats` | **Relative Effort:** `L`
- **The Core Mechanic:** On Night 4-5 smaller versions of The Hollow appear (shadow fragments). Weaker but numerous.
- **Player-Facing Value:** Multiple threats force defensive splitting. More intense nights.
- **Competitive Differentiation:** Escalation through numbers not just one stronger monster.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Additional AI entities; spawning system; performance`
- **Principal Design Risk:** `Performance with multiple AI agents on mobile`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
### 10. Disappearing act (`IDEA-00105`)
- **Weighted Score:** **93.0 / 100** | **Confidence Level:** High (92%)
- **Taxonomy Category:** `Monster & Threats` | **Relative Effort:** `S`
- **The Core Mechanic:** The Hollow sometimes goes completely silent for 30-60s. No sounds no visuals. Then reappears closer than before.
- **Player-Facing Value:** Silence as horror. The absence of threat becomes the threat.
- **Competitive Differentiation:** Masterful horror pacing through contrast.
- **The Signature Moment:** A desperate midnight sequence where players experience peak horror tension, clutch teamwork, or relief.
- **Key Dependencies:** `Monster AI silent state; timer; reposition`
- **Principal Design Risk:** `Could be boring if too long`
- **Prototype Verification Plan:** Implement isolated Luau service in Phase 0; validate fuel/distance balance via automated test suites.
- **Acceptance Criteria:** Verified server authority, seamless mobile touch responsiveness, and measurable retention lift.
- **De-scope Fallback:** If development budget constrains this system, reduce procedural elements and deploy static baseline values.

---
