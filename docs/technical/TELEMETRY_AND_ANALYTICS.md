# Telemetry and Analytics Pipeline — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Data & Analytics Lead  
> **Related Documents:** [TECHNICAL_OVERVIEW.md](file:///i:/RobloxDev/docs/technical/TECHNICAL_OVERVIEW.md), [TEST_STRATEGY.md](file:///i:/RobloxDev/docs/testing/TEST_STRATEGY.md)

---

## 1. System Vision & Privacy Mandate

Data telemetry enables evidence-based balancing: discovering where players get frustrated, how often the campfire extinguishes, and whether solo difficulty matches co-op difficulty.

### Strict Privacy & Compliance Rules
1. **Zero Personal Identifiable Information (PII):** Never log chat messages, IP addresses, real names, or device hardware IDs.
2. **COPPA / GDPR / Roblox Compliance:** All telemetry uses Roblox native `AnalyticsService` APIs (`LogCustomEvent`, `LogFunnelStepEvent`, `LogEconomyEvent`).
3. **Aggregated Reporting:** Data is reviewed strictly in aggregate to evaluate design bottlenecks.

---

## 2. Core Telemetry Event Catalog

| Event Name | Trigger Condition | Parameters Logged | Product Question Answered |
|------------|-------------------|-------------------|---------------------------|
| `SessionStarted` | Match boots from lobby | `PlayerCount`, `GameMode`, `IsSolo` | What is the average party size? |
| `PrologueCompleted` | Cutscene finished / Forest reached | `TimeElapsedSeconds`, `Skipped` | Do players watch or skip Day 0? |
| `ShelterDiscovered` | First player enters shelter fence | `SecondsFromSpawn` | Is shelter navigation intuitive? |
| `FirstCampfireLit` | Day 1 fire ignited with wood | `SecondsBeforeNightfall` | Do new players beat the dusk timer? |
| `NightSurvived` | Dawn reaches 06:00 | `DayNumber`, `RemainingFuelPercent`, `PartyAliveCount` | How close to extinction are players? |
| `CampfireExtinguished`| Fuel hits 0 during night | `DayNumber`, `TimeIntoNight`, `MonsterProximity` | When and why does the fire fail? |
| `PlayerDowned` | Player HP hits 0 | `CauseOfDeath`, `DayNumber`, `DistanceToFire` | Are players dying while straying too far? |
| `PlayerRevived` | Teammate completes revive | `TimeInBleedout`, `UsedBandage` | Is co-op triage functioning properly? |
| `CampaignEscaped` | Extraction transport boards | `TotalSessionSeconds`, `EmbersEarned`, `PartySurvivors` | What is the win rate by party size? |
| `CampaignFailed` | Entire party wiped / surrender | `FailureDay`, `TotalWoodGathered`, `TotalScrap` | Where does the difficulty wall spike? |

---

## 3. Campaign Progression Funnel Analysis

Tracking player drop-off through standard 6-stage funnel:

```text
[Funnel Step 1] Prologue Complete ─────────────► (Benchmark: >95%)
                     │
[Funnel Step 2] Day 1 Campfire Lit ────────────► (Benchmark: >88%)
                     │
[Funnel Step 3] Night 1 Survived ──────────────► (Benchmark: >75%)
                     │
[Funnel Step 4] Day 3 Trader Encountered ──────► (Benchmark: >60%)
                     │
[Funnel Step 5] Night 4 Darkness Endured ──────► (Benchmark: >45%)
                     │
[Funnel Step 6] Day 5 Signal Escape Cleared ───► (Benchmark: ~25–35%)
```

---

## 4. Implementation: Server Analytics Service

```lua
-- Authoritative server telemetry wrapper
local AnalyticsService = game:GetService("AnalyticsService")

local TelemetryService = {}

function TelemetryService.LogNightSurvived(day: number, fuelPercent: number, aliveCount: number)
    local success, err = pcall(function()
        AnalyticsService:LogCustomEvent("NightSurvived", {
            Day = day,
            Fuel = math.floor(fuelPercent * 100),
            Survivors = aliveCount
        })
    end)
    if not success then
        warn("Analytics log failed:", err)
    end
end

return TelemetryService
```

---

## 5. Acceptance Criteria

- [ ] **AC-TEL-01:** Every night completion logs a clean `NightSurvived` event with accurate surviving player count.
- [ ] **AC-TEL-02:** Telemetry events contain zero PII and pass Roblox moderation checks.
- [ ] **AC-TEL-03:** Analytics calls fail silently without interrupting core game loop execution.
- [ ] **AC-TEL-04:** Funnel events trigger strictly in chronological order without duplicate steps.
