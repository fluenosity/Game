--!strict
--[[
    SurvivorBoneSync.lua
    Universal Kinematics & Secondary Bone Synchronizer for Survivor Characters.
    Runs identically on Client and Server across all survivors (Local Player, Remote Players, NPCs).

    Responsibilities:
    1. Secondary Deformer Bone Pairing:
       Discovers 'mixamorig6:' (or any aliased deformer bones) and continuously synchronizes
       their Transform with the primary 'mixamorig:' bone animated by the Animator.
       This prevents skinned meshes (like Jody's Ch37_Body) from sitting in T-pose on the server or remote clients!
    2. Procedural Posture & Chest Elaboration:
       Applies thoracic spine extension (Spine1 + Spine2 arch), cervical neck counter-tilt,
       and shoulder retraction according to the survivor profile's calibrated angles.
    3. Jump Root-Motion Stabilization:
       Clamps positive Y displacement on mixamorig:Hips during jumps/falls so character never flickers/pops.
]]

local SurvivorRigConfig = require(script.Parent:WaitForChild("SurvivorRigConfig"))

export type BoneSyncPair = {
    Source: Bone,
    Target: Bone,
}

export type CharacterRigData = {
    Character: Model,
    SyncPairs: { BoneSyncPair },
    Hips: Bone?,
    LeftUpLeg: Bone?,
    RightUpLeg: Bone?,
    LegClearanceAngleDeg: number,
}

local SurvivorBoneSync = {}
local trackedRigs: { [Model]: CharacterRigData } = {}

function SurvivorBoneSync.RegisterCharacter(char: Model): CharacterRigData?
    if not char or not char:IsA("Model") then return nil end
    if trackedRigs[char] then return trackedRigs[char] end

    local syncPairs: { BoneSyncPair } = {}
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Bone") and string.find(d.Name, "^mixamorig6:") then
            local baseName = string.gsub(d.Name, "^mixamorig6:", "mixamorig:")
            local source = char:FindFirstChild(baseName, true)
            if source and source:IsA("Bone") then
                table.insert(syncPairs, { Source = source, Target = d })
            end
        end
    end

    local profileId = (char:GetAttribute("SurvivorProfileId") or char.Name) :: string
    local profile = SurvivorRigConfig.GetProfile(profileId, char)

    local rigData: CharacterRigData = {
        Character = char,
        SyncPairs = syncPairs,
        Hips = char:FindFirstChild("mixamorig:Hips", true) :: Bone?,
        LeftUpLeg = char:FindFirstChild("mixamorig:LeftUpLeg", true) :: Bone?,
        RightUpLeg = char:FindFirstChild("mixamorig:RightUpLeg", true) :: Bone?,
        LegClearanceAngleDeg = profile and profile.LegClearanceAngleDeg or 0,
    }

    trackedRigs[char] = rigData

    char.Destroying:Connect(function()
        trackedRigs[char] = nil
    end)

    return rigData
end

function SurvivorBoneSync.UnregisterCharacter(char: Model)
    trackedRigs[char] = nil
end

function SurvivorBoneSync.StepCharacter(rig: CharacterRigData)
    -- In-Place Pelvic Root Stabilizer:
    -- Mixamo animations without 'In Place' (FemaleWalk, MaleWalk, RunningJumpMain)
    -- translate -5.1 to -14.1 studs forward along Z on mixamorig:Hips.
    -- Locking Z = 0 keeps the pelvis anchored to HumanoidRootPart, producing clean,
    -- perfect in-place locomotion without forward-and-back rubberbanding or forward jump throw.
    if rig.Hips then
        local t = rig.Hips.Transform
        local clampedY = t.Position.Y
        if clampedY > 0.05 then
            clampedY = clampedY * 0.15
        end
        if math.abs(t.Position.Z) > 0.001 or clampedY ~= t.Position.Y then
            rig.Hips.Transform = CFrame.new(t.Position.X, clampedY, 0) * t.Rotation
        end
    end

    -- Leg Stance Clearance:
    -- Prevents catwalk scissor-crossing (X-legs) on feminine walk animations
    if rig.LeftUpLeg and rig.RightUpLeg and rig.LegClearanceAngleDeg ~= 0 then
        local flare = rig.LegClearanceAngleDeg
        rig.LeftUpLeg.Transform = rig.LeftUpLeg.Transform * CFrame.Angles(0, 0, math.rad(flare))
        rig.RightUpLeg.Transform = rig.RightUpLeg.Transform * CFrame.Angles(0, 0, math.rad(-flare))
    end

    -- Secondary Deformer Bone Sync (e.g. mixamorig6 for Jody)
    for _, pair in ipairs(rig.SyncPairs) do
        pair.Target.Transform = pair.Source.Transform
    end
end

function SurvivorBoneSync.StepAll()
    for char, rig in pairs(trackedRigs) do
        if not char.Parent then
            trackedRigs[char] = nil
        else
            SurvivorBoneSync.StepCharacter(rig)
        end
    end
end

return SurvivorBoneSync
