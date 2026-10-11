# Top 30 Candidate Features & Synergy Matrix — Project: Undecided

> **Status:** `SHORTLIST FOR EVALUATION`  
> **Last updated:** 2026-10-11  
> **Related Documents:** [TOP_10_RECOMMENDATIONS.md](file:///i:/RobloxDev/docs/research/TOP_10_RECOMMENDATIONS.md), [IDEA_SCORING_MODEL.md](file:///i:/RobloxDev/docs/research/IDEA_SCORING_MODEL.md)

---

## 1. Top 30 Ranked Candidates

| Rank | ID | Category | Title | Score | Effort | Key Value |
|:----:|:--:|----------|-------|:-----:|:------:|-----------|
| 1 | `IDEA-00105` | Monster & Threats | Disappearing act | **93.0** | S | Silence as horror. The absence of threat becomes the threat.... |
| 2 | `IDEA-00124` | Monster & Threats | Phased monster reveal | **93.0** | S | Progressive reveal builds anticipation and dread across the ... |
| 3 | `IDEA-00408` | Monster & Threats | Patience testing behavior | **93.0** | S | Extreme patience as a horror tool. The monster simply WAITS.... |
| 4 | `IDEA-00421` | Monster & Threats | The Hollow speaks on Night 5 | **93.0** | S | The monster finally speaks. One word. Maximum impact.... |
| 5 | `IDEA-00478` | Presentation & Horror | Sound design: the silence before attack | **93.0** | S | The silence is the ultimate horror trigger. Absence of sound... |
| 6 | `IDEA-00488` | Presentation & Horror | 4th wall break on Night 5 | **93.0** | S | 4th wall horror that creates genuine real-world unease.... |
| 7 | `IDEA-00498` | Monster & Threats | The Hollow's goodbye | **93.0** | S | Emotional final moment. The guardian lets you go.... |
| 8 | `IDEA-00048` | Fire, Light, Darkness | Eclipse event | **90.0** | M | High-tension surprise event that disrupts safe daytime assum... |
| 9 | `IDEA-00091` | Monster & Threats | Daylight stalking | **90.0** | S | Destroys the assumption that daytime = completely safe.... |
| 10 | `IDEA-00295` | Monster & Threats | The Hollow's song | **90.0** | S | Psychological horror through corrupted familiar sounds.... |
| 11 | `IDEA-00343` | Monster & Threats | Stalking phase before hunt | **90.0** | S | Psychological horror during previously safe daytime.... |
| 12 | `IDEA-00346` | Presentation & Horror | Whisper name mechanic | **90.0** | S | Deeply personal horror moment. The monster knows you.... |
| 13 | `IDEA-00492` | Monster & Threats | The Hollow knows you've played before | **90.0** | S | Meta-horror that acknowledges replay. The monster remembers ... |
| 14 | `IDEA-00021` | Core Gameplay | Flare gun signal | **89.0** | S | Creates a save-or-use decision. Emergency panic button.... |
| 15 | `IDEA-00099` | Monster & Threats | Monster eye glow indicator | **89.0** | S | Elegant visual threat indicator. Players learn to watch for ... |
| 16 | `IDEA-00120` | Monster & Threats | Challenge roar | **89.0** | S | Climactic moment that signals the final battle is coming.... |
| 17 | `IDEA-00311` | Co-op & Social | Sacrifice mechanic | **89.0** | S | Heroic last-resort mechanic. Creates intense co-op moments.... |
| 18 | `IDEA-00322` | Core Gameplay | Emergency barricade quick-build | **89.0** | S | Panic-button defense for emergencies. Consumes resources but... |
| 19 | `IDEA-00324` | Monster & Threats | The Hollow's pause before attack | **89.0** | S | Skill-based survival against the monster. Learnable pattern.... |
| 20 | `IDEA-00334` | Fire, Light, Darkness | Burning object as weapon | **89.0** | S | Active defense tool with very limited duration. Risk/reward.... |
| 21 | `IDEA-00364` | Presentation & Horror | First-person death cam | **89.0** | S | Maximum horror impact at death. The face is the last thing y... |
| 22 | `IDEA-00044` | Fire, Light, Darkness | Shadow puppet warning system | **87.0** | S | Beautiful visual warning system. The shadow arrives before t... |
| 23 | `IDEA-00080` | Fire, Light, Darkness | Shadow creature decoys | **87.0** | M | Monster deception that increases psychological horror.... |
| 24 | `IDEA-00081` | Monster & Threats | Sound mimicry | **87.0** | M | Psychological horror. Players can't trust what they hear.... |
| 25 | `IDEA-00089` | Monster & Threats | Monster watching cutscene | **87.0** | M | Terrifying perspective shift. Players realize they've been o... |
| 26 | `IDEA-00096` | Monster & Threats | Monster vocalization evolution | **87.0** | M | Escalating audio horror that becomes deeply personal.... |
| 27 | `IDEA-00112` | Monster & Threats | Ceiling/above approach | **87.0** | M | New threat vector that makes players look UP.... |
| 28 | `IDEA-00134` | Co-op & Social | Voice proximity chat | **87.0** | M | Separated players can't coordinate — increases tension drama... |
| 29 | `IDEA-00183` | Campaign & Narrative | The Hollow origin flashback | **87.0** | M | Emotional payoff. The monster becomes sympathetic.... |
| 30 | `IDEA-00306` | Fire, Light, Darkness | Controlled burn mechanic | **87.0** | M | High-cost tactical tool with permanent consequences.... |

---

## 2. System Interaction & Compatibility Matrix

| System Group | Complements (Synergies) | Potential Conflicts | Design Resolution |
|--------------|-------------------------|---------------------|-------------------|
| **Fire Depletion & Safe Radius** | Weather rainstorms, Monster probing AI | Excessive gathering chores | Calibrate wood yield so players always have 15% fuel buffer on Night 1. |
| **Connected Light Network** | Day 5 Signal Tower quest, Co-op scouting | Trivializing monster pathfinding | Limit max relays to 4 active nodes; monster can damage isolated relays. |
| **Dynamic Weather (Rain/Fog)** | Audio occlusion, Visual horror atmosphere | Mobile thermal throttling | Localize particle emitters to camera; auto-disable fog on low-tier profile. |
| **Wandering Trader Barter** | Scavenging salvage, Base upgrades | Infinite item hoarding | Strict daily inventory stock caps; trader departs before dusk. |
| **Contextual Ping System** | Non-voice mobile co-op, Downed triage | Screen UI clutter | Pings fade after 5.0 seconds; rate-limited to 2 pings per second. |
