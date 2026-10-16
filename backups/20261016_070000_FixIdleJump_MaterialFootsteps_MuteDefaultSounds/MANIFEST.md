# Backup Manifest: 20261016_070000_FixIdleJump_MaterialFootsteps_MuteDefaultSounds
Date: 2026-10-16 06:55:43
Description:
1. Idle Jump Fix:
   - Proactive JumpPower = 0 and Jumping state disabled when stationary.
   - Clean debounce and jumpCooldownThread recovery so jumping in walk/run never breaks after idle attempts.
2. Default Roblox Sound Removal:
   - Silenced/removed default plastic footsteps and generic jump/landing sounds in HumanoidRootPart.
   - Added RbxCharacterSounds override in StarterPlayerScripts.
3. AAA Material-Based Footstep & Locomotion Audio System:
   - Dynamic floor material detection (Grass, Mud/Dirt, Stone, Wood, Water).
   - Multi-sample round-robin footstep pools with subtle pitch variations.
   - Speed-scaled volume and cadence for walk vs sprint.
   - Material-responsive landing and jump takeoff audio.
