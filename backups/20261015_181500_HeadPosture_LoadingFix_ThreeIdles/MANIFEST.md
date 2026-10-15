# Backup Manifest: 20261015_181500_HeadPosture_LoadingFix_ThreeIdles
Date: 2026-10-15 18:14:29
Description: Snapshot after implementing:
1. Upright Head & Neck Posture Alignment:
   - Eliminated hunched forward posture in walk and idle poses.
   - Tilts mixamorig:Neck back (+6.0°) and mixamorig:Head back (+9.0°) in both CharacterAnimationController and SurvivorBoneSync.
   - Synchronized across local player and all remote players.
2. Loading Screen 88% Hang Fix:
   - Fixed capability PluginOrOpenCloud error in PlayerLifecycle (switched from .Source reading to clean :Clone()).
   - Added timeout-protected character resolution in LoadingManager so screen always advances to 100% and reveals wilderness.
3. Three Idle Animations Cycling ((1, 2, 1, 3)):
   - StaticIDLEMAIND: 103828063959982 (10.0s primary anchor idle)
   - IDLEMAIN2: 132876566376642 (4.0s flavor shift)
   - IDLEMAIN3: 137772468102995 (3.27s observant glance)
   - Alternating cycle with smooth 0.35s crossfade and instant movement cancel.
