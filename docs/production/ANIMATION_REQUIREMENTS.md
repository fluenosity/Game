# Animation Requirements Specification — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Lead 3D Animator & Technical Artist  
> **Related Documents:** [ART_DIRECTION.md](file:///i:/RobloxDev/docs/production/ART_DIRECTION.md), [MONSTER_AI_TECHNICAL_DESIGN.md](file:///i:/RobloxDev/docs/technical/MONSTER_AI_TECHNICAL_DESIGN.md)

---

## 1. Animation Vision & Rig Constraints

Animations must deliver physical weight, panic, and raw horror. First-person viewmodels and third-person spectator rigs must mirror each other's states seamlessly.

### Rig Specifications
- **Player Rigs:** Standard Roblox **R15** rig with weighted inverse kinematics (IK) for foot placement on uneven terrain.
- **First-Person Viewmodel:** Custom lightweight two-arm mesh rigged with tool bones for hatchet, torch, and flares.
- **The Monster ("The Hollow"):** Custom 28-bone humanoid-quadruped hybrid rig with elongated limbs, articulated neck, and twitching fingers.

---

## 2. Animation Catalog

### 2.1 Player Character Animations
| Animation Clip | Type | Loop? | Priority | Description |
|----------------|------|:-----:|----------|-------------|
| `Player_Walk` | Locomotion | Yes | Core | Steady cautious walk with slight weapon sway |
| `Player_Sprint` | Locomotion | Yes | Core | Heavy, hurried sprint with pronounced camera bob |
| `Player_ChopTree` | Action | Yes | Action | Rhythmic two-handed hatchet swing striking timber |
| `Player_CarryLog` | Stance | Yes | Overlay | Both arms wrapped around heavy wooden log, slowed gait |
| `Player_Downed_Crawl` | Downed | Yes | Action | Desperate one-handed forward crawling along dirt |
| `Player_RevivingTeammate` | Action | Yes | Action | Crouched forward applying pressure and bandages |
| `Player_DamageFlinch` | Reaction | No | Action | Sharp torso recoil backwards with screen camera shake |

### 2.2 Monster ("The Hollow") Animations
| Animation Clip | Type | Loop? | Priority | Description |
|----------------|------|:-----:|----------|-------------|
| `Monster_Prowl` | Locomotion | Yes | Core | Low-slung, creeping predatory gait, head swaying side to side |
| `Monster_Investigate` | Idle | Yes | Idle | Standing erect, tilting head inquisitively, twitching hands |
| `Monster_RoarAlert` | Reaction | No | Action | Torso snaps back, mouth distends wide, arms flare outward |
| `Monster_ChargeSprint` | Locomotion | Yes | Action | Terrifying quadrupedal gallop closing distance at high speed |
| `Monster_SwipeAttack` | Attack | No | Action | Vicious downward claw sweep with trailing shadow smear |
| `Monster_LightBlinded` | Stun | No | Action | Arms shielding face from bright flare, agonizing recoil step |
| `Monster_ShadowDissolve`| Fade | No | Action | Sinking into ground shadows, dissolving into black mist |

---

## 3. Viewmodel Animation Sync & Transitions

- Client `CameraController` binds the FPP viewmodel to camera CFrame every render stepped frame.
- Transitions between idle, swinging hatchet, and stoking fire use `AnimationTrack:CrossFade() = 0.15s` for snappy, fluid responsiveness without clipping.

---

## 4. Acceptance Criteria

- [ ] **AC-ANIM-01:** Chopping tree plays continuous looping swing animation synchronized with audio impact ticks.
- [ ] **AC-ANIM-02:** Downed players transition to crawling animation within 0.1s of HP reaching 0.
- [ ] **AC-ANIM-03:** Monster light stun animation interrupts active charge sprint immediately upon flare exposure.
