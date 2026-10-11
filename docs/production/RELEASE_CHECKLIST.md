# Launch & Release Checklist — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Release Manager & Operations Lead  
> **Related Documents:** [QA_AND_ACCEPTANCE_CRITERIA.md](file:///i:/RobloxDev/docs/production/QA_AND_ACCEPTANCE_CRITERIA.md), [RISK_REGISTER.md](file:///i:/RobloxDev/docs/production/RISK_REGISTER.md)

---

## 1. Technical & Engineering Gate

- [ ] **DataStore Persistence:** `ProfileService` session locking tested against rapid multi-server joins.
- [ ] **BindToClose Graceful Shutdown:** Tested with simulated server crash; all active profiles flush within 30s.
- [ ] **StreamingEnabled Active:** Verified `StreamingMinRadius = 96` and `StreamingTargetRadius = 320`.
- [ ] **Network Remotes Sanitized:** All client requests pass strict server boundary, rate-limit, and range checks.
- [ ] **Zero Unhandled Errors:** Script error rate < 0.1% per 1,000 player sessions in error telemetry.
- [ ] **Memory & FPS Verification:** Low-end mobile device achieves >= 30 FPS with memory footprint < 900 MB.

---

## 2. Platform Compliance & Creator Dashboard Gate

- [ ] **Age Recommendation Questionnaire:** Completed on Creator Dashboard (Expected: Moderate / 9+ for Mild Horror).
- [ ] **Spatial Voice / Chat:** Configured with proper Roblox moderation filter bindings.
- [ ] **Roblox Terms of Use:** Verified zero off-platform links, gambling mechanics, or unapproved third-party branding.
- [ ] **Game Icon & Thumbnails:** 512×512 icon and 1920×1080 high-contrast thumbnails rendered and uploaded.
- [ ] **Localization Readiness:** Dynamic strings mapped through Roblox LocalizationTable.

---

## 3. Gameplay & Balancing Verification

- [ ] **Day 0–Day 5 Campaign Cleared:** End-to-end victory verified in solo, 2-player, and 5-player configurations.
- [ ] **Campfire Fuel Curve:** Verified that standard wood gathering leaves players with a 15%–25% fuel buffer on Night 1.
- [ ] **Monster Pathfinding:** Zero occurrences of monster walking through active light or getting stuck in trees.
- [ ] **Extraction Trigger:** Day 5 dawn evacuation transport departs and awards campaign badge reliably.

---

## 4. LiveOps & Post-Launch Monitoring

- [ ] **Live Telemetry Active:** `AnalyticsService` events streaming into creator analytics dashboard.
- [ ] **Rollback Plan:** Staged previous stable place version ready to deploy within 5 minutes if game-breaking bug emerges.
- [ ] **Community Support Channels:** Bug report webhook configured for rapid feedback triage.
