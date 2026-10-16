# Backup Manifest: 20261016_064500_MainIdleHeadPosture_LocomotionZeroOffset_DayLighting
Date: 2026-10-16 06:41:33
Description:
1. Locomotion Head Posture (Walk & Run):
   - Confirmed 100% author-authentic posture (0 deg neck/head offset).
   - CharacterAnimationController dynamically sets currentHeadPostureAlpha = 0 during movement.
   - SurvivorBoneSync skips posture offset during movement.
2. Main Idle Head Posture Calibration (StaticIDLEMAIND):
   - User requested a slight upward tweak to neutralize residual forward hunch in StaticIDLEMAIND.
   - Calibrated FemaleBase: NeckPostureBackDeg = 11.0°, HeadPostureBackDeg = 14.5°.
   - Calibrated MaleBase: NeckPostureBackDeg = 9.0°, HeadPostureBackDeg = 12.0°.
   - Applied strictly to StaticIDLEMAIND (103828063959982) only; flavor idles and locomotion remain unaffected.
3. Daytime Lock & Lighting:
   - DayNightClient MENU_HOUR set to 14.0 (daytime).
   - TimeConfig and EnvironmentConfig daylight preserved.
