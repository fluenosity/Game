--!strict
--[[
    SurvivorRigConfig.lua
    Universal profile and class configuration for all survivor character rigs.
    Supports gender archetypes (Male vs Female) and character-specific kinematic overrides.
]]

local SurvivorRigConfig = {}

export type SurvivorGender = "Male" | "Female"

export type LocomotionConfig = {
    Walk: string,
    Run: string,
    Jump: string,
    Fall: string,
    Swim: string?,
    SwimIdle: string?,
}

export type SurvivorProfile = {
    Id: string,
    DisplayName: string,
    Gender: SurvivorGender,
    Description: string,
    TargetHeight: number,          -- Strict 5.970 studs standard
    HipHeight: number,             -- Calibrated ground sneaker/boot contact
    LegCorrectionAngleDeg: number, -- Neutralized to prevent crossing
    LegClearanceAngleDeg: number,  -- Outward flare angle to prevent feet crossing during walk
    ArmClearanceAngleDeg: number,  -- Outward tilt so hands don't clip into thighs/shorts
    BoneNamespace: string?,        -- e.g. "mixamorig6" for JODY (auto-normalized to mixamorig)
    MeshParts: { string }?,        -- Expected constituent meshes
    Locomotion: LocomotionConfig,  -- Authored Mixamo locomotion asset IDs
    Facial: {
        HasSmile: boolean,
        MicroGazeRangeDeg: number, -- Subtle living eye/head saccade range in degrees
        HeadRestTiltDeg: number,   -- Subtle gentle resting tilt (warm, natural posture)
    },
}

-- ---------------------------------------------------------------------------
-- GENDER BASE ARCHETYPES
-- ---------------------------------------------------------------------------
local FemaleBase = {
    Gender = "Female" :: SurvivorGender,
    TargetHeight = 5.970,
    HipHeight = 1.90,              -- Calibrated for sneakers/shoes with zero hover
    LegCorrectionAngleDeg = 0.0,   -- Neutralized so legs don't scissor-cross
    LegClearanceAngleDeg = -5.5,   -- Athletic stance flare so feet stride parallel with 0 crossing frames
    ArmClearanceAngleDeg = 4.0,    -- Gives hands comfortable 2-inch clearance from shorts/hips
    Locomotion = {
        Walk = "rbxassetid://115531053004010", -- FemaleWalk
        Run = "rbxassetid://99676638771528",   -- RunningNewMain
        Jump = "rbxassetid://103074489051723", -- RunningJumpMain (moving jump)
        Fall = "rbxassetid://103074489051723", -- RunningJumpMain (moving fall)
        Swim = "rbxassetid://117791765615739", -- SwimmingMain
        SwimIdle = "rbxassetid://122627851214967", -- SwimmingIdleMain
    } :: LocomotionConfig,
    Facial = {
        HasSmile = true,
        MicroGazeRangeDeg = 1.2,
        HeadRestTiltDeg = 1.5,     -- Gentle warm posture
    },
}

local MaleBase = {
    Gender = "Male" :: SurvivorGender,
    TargetHeight = 5.970,
    HipHeight = 1.98,              -- Calibrated for combat boots/heavy shoes
    LegCorrectionAngleDeg = 0.0,   -- Neutralized
    LegClearanceAngleDeg = 0.0,    -- Athletic masculine rig already has wide hip separation
    ArmClearanceAngleDeg = 3.0,    -- Athletic arm drape
    Locomotion = {
        Walk = "rbxassetid://70412449762831",  -- MaleWalk
        Run = "rbxassetid://99676638771528",   -- RunningNewMain
        Jump = "rbxassetid://103074489051723", -- RunningJumpMain (moving jump)
        Fall = "rbxassetid://103074489051723", -- RunningJumpMain (moving fall)
        Swim = "rbxassetid://117791765615739", -- SwimmingMain
        SwimIdle = "rbxassetid://122627851214967", -- SwimmingIdleMain
    } :: LocomotionConfig,
    Facial = {
        HasSmile = false,
        MicroGazeRangeDeg = 1.0,
        HeadRestTiltDeg = 0.5,
    },
}

-- ---------------------------------------------------------------------------
-- INDIVIDUAL SURVIVOR ROSTER
-- ---------------------------------------------------------------------------
SurvivorRigConfig.Profiles = {
    SOPHIE = {
        Id = "SOPHIE",
        DisplayName = "Sophie",
        Gender = FemaleBase.Gender,
        Description = "Agile Scout & Field Navigator",
        TargetHeight = FemaleBase.TargetHeight,
        HipHeight = FemaleBase.HipHeight,
        LegCorrectionAngleDeg = FemaleBase.LegCorrectionAngleDeg,
        LegClearanceAngleDeg = FemaleBase.LegClearanceAngleDeg,
        ArmClearanceAngleDeg = FemaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Ch02_Body", "Ch02_Cloth", "Ch02_Sneakers", "Ch02_Socks", "Ch02_Hair", "Ch02_Eyelashes" },
        Locomotion = FemaleBase.Locomotion,
        Facial = FemaleBase.Facial,
    } :: SurvivorProfile,

    JODY = {
        Id = "JODY",
        DisplayName = "Jody",
        Gender = FemaleBase.Gender,
        Description = "Combat Specialist & Survivalist",
        TargetHeight = FemaleBase.TargetHeight,
        HipHeight = 1.92,
        LegCorrectionAngleDeg = FemaleBase.LegCorrectionAngleDeg,
        LegClearanceAngleDeg = FemaleBase.LegClearanceAngleDeg,
        ArmClearanceAngleDeg = FemaleBase.ArmClearanceAngleDeg,
        BoneNamespace = "mixamorig6", -- Will be automatically normalized to mixamorig
        MeshParts = { "Ch37_Body" },
        Locomotion = FemaleBase.Locomotion,
        Facial = FemaleBase.Facial,
    } :: SurvivorProfile,

    BRYCE = {
        Id = "BRYCE",
        DisplayName = "Bryce",
        Gender = MaleBase.Gender,
        Description = "Craftsman & Combat Engineer",
        TargetHeight = MaleBase.TargetHeight,
        HipHeight = MaleBase.HipHeight,
        LegCorrectionAngleDeg = MaleBase.LegCorrectionAngleDeg,
        LegClearanceAngleDeg = MaleBase.LegClearanceAngleDeg,
        ArmClearanceAngleDeg = MaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Ch42_Body" },
        Locomotion = MaleBase.Locomotion,
        Facial = MaleBase.Facial,
    } :: SurvivorProfile,

    Remy = {
        Id = "Remy",
        DisplayName = "Remy",
        Gender = MaleBase.Gender,
        Description = "Heavy Scout & Frontline Defender",
        TargetHeight = MaleBase.TargetHeight,
        HipHeight = MaleBase.HipHeight,
        LegCorrectionAngleDeg = MaleBase.LegCorrectionAngleDeg,
        LegClearanceAngleDeg = MaleBase.LegClearanceAngleDeg,
        ArmClearanceAngleDeg = MaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Remy_Body", "Remy_Shoes" },
        Locomotion = MaleBase.Locomotion,
        Facial = MaleBase.Facial,
    } :: SurvivorProfile,

    Ch18 = {
        Id = "Ch18",
        DisplayName = "Leo (Infiltrator)",
        Gender = MaleBase.Gender,
        Description = "Stealth Tracker & Vanguard",
        TargetHeight = MaleBase.TargetHeight,
        HipHeight = MaleBase.HipHeight,
        LegCorrectionAngleDeg = MaleBase.LegCorrectionAngleDeg,
        LegClearanceAngleDeg = MaleBase.LegClearanceAngleDeg,
        ArmClearanceAngleDeg = MaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Ch18" },
        Locomotion = MaleBase.Locomotion,
        Facial = MaleBase.Facial,
    } :: SurvivorProfile,

    Beta_Surface = {
        Id = "Beta_Surface",
        DisplayName = "X Bot (Reference)",
        Gender = MaleBase.Gender,
        Description = "Prototyping Avatar Rig",
        TargetHeight = MaleBase.TargetHeight,
        HipHeight = MaleBase.HipHeight,
        LegCorrectionAngleDeg = 0.0,
        LegClearanceAngleDeg = 0.0,
        ArmClearanceAngleDeg = 0.0,
        MeshParts = { "Beta_Surface" },
        Locomotion = MaleBase.Locomotion,
        Facial = { HasSmile = false, MicroGazeRangeDeg = 0.0, HeadRestTiltDeg = 0.0 },
    } :: SurvivorProfile,
}

function SurvivorRigConfig.GetProfile(nameOrId: string, model: Model?): SurvivorProfile
    local clean = string.gsub(nameOrId or "", "%s+", "")
    if clean == "" or string.lower(clean) == "startercharacter" then
        return SurvivorRigConfig.Profiles.SOPHIE
    end
    for id, profile in pairs(SurvivorRigConfig.Profiles) do
        if string.lower(id) == string.lower(clean) or string.lower(profile.DisplayName) == string.lower(clean) then
            return profile
        end
    end
    -- Check model meshes if available
    if model and model:IsA("Model") then
        if model:FindFirstChild("Ch02_Body") or model:FindFirstChild("Ch37_Body") or model:FindFirstChild("mixamorig6:Hips", true) then
            return SurvivorRigConfig.Profiles.SOPHIE
        elseif model:FindFirstChild("Ch42_Body") or model:FindFirstChild("Ch18") then
            return SurvivorRigConfig.Profiles.BRYCE
        end
    end
    -- Fallback to Male or Female base depending on detection
    if string.find(string.lower(clean), "female") or string.find(string.lower(clean), "girl") or string.find(string.lower(clean), "sophie") or string.find(string.lower(clean), "jody") then
        return SurvivorRigConfig.Profiles.SOPHIE
    elseif string.find(string.lower(clean), "male") or string.find(string.lower(clean), "boy") or string.find(string.lower(clean), "bryce") or string.find(string.lower(clean), "remy") then
        return SurvivorRigConfig.Profiles.BRYCE
    end
    -- Default to active game survivor (Sophie)
    return SurvivorRigConfig.Profiles.SOPHIE
end

return SurvivorRigConfig
