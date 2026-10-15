# Active Locomotion Animations (Current Roster)
- **FemaleWalk**: `115531053004010` (Calibrated Walk @ 6 studs/s for Sophie & Jody)
- **MaleWalk**: `70412449762831` (Calibrated Walk @ 6 studs/s for Bryce & Remy)
- **RunningNewMain**: `99676638771528` (Sprint Run @ 16 studs/s, all characters)
- **RunningJumpMain**: `103074489051723` (Moving Jump & Fall leap arc, JumpPower = 38, requires active movement / sprint)
- **IdleJump**: *BLOCKED* (Characters cannot jump while standing still; must be actively moving or running)
- **Crouch**: *REMOVED* (Streamlined locomotion: Walk @ 6 studs/s, Sprint @ 16 studs/s)
- **MainIdle**: `79030538201747` (Male resting idle)
- **SlightTiltIdle**: `89629385542634` (Sophie female signature idle)
- **SittingMain**: `98264175486814`
- **SitToStandMain**: `97271955482381`
- **Stand to Sit Main**: `99867494141148`
- **SwimmingMain**: `117791765615739` (Water forward swimming locomotion)
- **SwimmingIdleMain**: `122627851214967` (Water surface treading idle)
IDLEMAIN2 - 132876566376642
StaticIDLEMAIND - 103828063959982
IDLEMAIN3 - 137772468102995
### Secondary / Overlay / Emote Animations:
- Movementoractiontoidle: `134245085026778`
- Repelling Insects idle: `105216910523835` (upper-body overlay)
- checking nails idle: `81640445815841`

## Character Rig Registry & Archetype System (`SurvivorRigConfig.lua`)
- **Archetype: FemaleBase** (LegClearance: `-5.5° outward flare` (0 crossing frames, parallel strides), LegCorrection: `0.0° neutral`, ArmClearance: `4.0° outward`, HipHeight: `1.90`, Living Gaze: `1.2°`)
- **Archetype: MaleBase** (LegClearance: `0.0° neutral` (+0.325 studs natural clearance), ArmClearance: `3.0° outward`, HipHeight: `1.98`, Living Gaze: `1.0°`)
- **Pelvic Root Motion Stabilizer**: `mixamorig:Hips.Transform.Z = 0` on `PreSimulation` (anchors pelvis to HumanoidRootPart, eliminating forward rubberbanding and horizontal air fling).

### Active Character:
- **`SOPHIE` (Female Survivor - Active `StarterCharacter`)**:
  - MeshParts: `Ch02_Body`, `Ch02_Cloth`, `Ch02_Sneakers`, `Ch02_Socks`, `Ch02_Hair`, `Ch02_Eyelashes`
  - Textures: ColorMap (`124049642897053`), NormalMap (`135712273662779`), RoughnessMap (`91480305724067`)
  - Calibration: Feet stance `0.745 studs`, Hand clearance `1.514 studs`, Living head gaze active.
  - Height: `5.970` studs (`Model:GetScale() == 1.0`, zero sliding)

### Configured Roster (Ready for Import / Storage):
- **`BRYCE` (Male Survivor)**: `I:\RobloxDev\Blender\BRYCE.fbx` (Profile ready, 66 bones, Male archetype)
- **`JODY` (Female Survivor)**: `I:\RobloxDev\Blender\JODY.fbx` (Profile ready, auto-normalizes `mixamorig6:`, Female archetype)
- **`Remy` (Male Survivor)**: `I:\RobloxDev\Blender\Remy.fbx` (Profile ready, 68 bones, Male archetype)
- **`Ch18` (Leo - Infiltrator)**: Stored in `game.ServerStorage.StarterCharacter_Backup_Ch18`
- **`Beta_Surface` (X Bot)**: Stored in `game.ServerStorage.StarterCharacter_Backup_BetaSurface`