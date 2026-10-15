# Backup Manifest: 20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker
**Timestamp:** 2026-10-15 16:48:00
**Backup Directory:** `I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker`

## State Before Changes:
- **WalkSpeed:** 12 studs/s
- **Sprint Speed:** 24 studs/s
- **Fatigued Speed:** 8 studs/s
- **Idle Jumping:** Allowed via asset `100945085841175` (`IdleJumpAnim`)
- **Jump-to-Walk Landing:** Subject to multi-track blend delay and potential weight overlap flicker

## Planned Changes:
1. **Reduce Walking and Running Speed by 50%:**
   - WalkSpeed: 12 -> 6 studs/s
   - Sprint Speed: 24 -> 12 studs/s
   - Fatigued Speed: 8 -> 4 studs/s
   - Recalibrate Animate normalization: `normalizedWalkSpeed = 0.47`, `normalizedRunSpeed = 0.94`
2. **Block Idle Jump Completely:**
   - Character must be moving/running (`MoveDirection.Magnitude > 0.05` or `horizontalSpeed > 1.2`) to jump.
   - Stationary jumping blocked via Humanoid:SetStateEnabled(Jumping, false) when idle.
3. **Eliminate Jump-to-Locomotion Landing Flicker:**
   - Pre-initialize correct walk/run weights on transition.
   - Smooth 0.14s fade on airborne track without multi-track weight spike.
   - Continuous speed sync in stepAnimate.
4. **Wire Swimming Animations:**
   - `SwimmingMain` = `117791765615739`
   - `SwimmingIdleMain` = `122627851214967`

## Backed Up Files:
- I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker\client\CharacterAnimationController.client.lua
- I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker\client\HUDController.client.lua
- I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker\server\PlayerLifecycle.server.lua
- I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker\server\SurvivorRigAdapter.lua
- I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker\shared\SurvivorRigConfig.lua
- I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker\shared\SurvivorBoneSync.lua
- I:\RobloxDev\backups\20261015_164800_Locomotion50Speed_BlockIdleJump_FixFlicker\main.md
