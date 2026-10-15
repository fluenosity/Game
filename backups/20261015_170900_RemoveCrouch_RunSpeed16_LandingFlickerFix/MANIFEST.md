# Backup Manifest: 20261015_170900_RemoveCrouch_RunSpeed16_LandingFlickerFix
Date: 2026-10-15 17:08:48
Description: Snapshot prior to removing crouch, increasing sprint speed to 16 studs/s, and fixing landing transition flicker and Animate line 635 nil comparison.

## Target Changes:
1. Remove crouch completely (no crouch keybind 'C', no IsCrouching attribute, no crouch animation, no crouch speed).
2. Increase running speed to 16 studs/s (Walk remains 6 studs/s, sprint = 16 studs/s).
3. Recalibrate Animate normalized speeds (walk = 0.47, run = 1.25) and resolve module scope of speed variables to eliminate `attempt to compare number <= nil`.
4. Fix landing flicker when transitioning from jump/fall into locomotion: zero jumpAnimTime on Landed, smooth fade, eliminate duplicate bone hooks.
