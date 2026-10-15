# Backup: 20261015_184000_MainMenu3DCampfire_Idles_Posture_Transition

## Timestamp
- 2026-10-15 18:40:00

## Description
Backup taken before fixing:
1. In-game idle animation freezing bug in `StarterPlayer.StarterCharacterScripts.Animate` (fixed track.Length check, looping safety, and {1,2,1,3} cycling).
2. Live 3D campfire simulation in MainMenu (removing static image/video backgrounds, positioning camera at `(0, 26, -385)` looking at `(2.5, 12, -430)`, setting night atmosphere at 22:00, adding subtle cinematic camera drift).
3. Smooth transition from Main Menu / Wardrobe into live game when PLAY is clicked, entering first-person perspective seamlessly.
4. Verified posture compensation (head back, neck upright) across all female and male rigs.
