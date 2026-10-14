--!strict
--[[
    SurvivorRigConfig.lua
    Universal profile and class configuration for all survivor character rigs.
    Supports gender archetypes (Male vs Female) and character-specific kinematic overrides.
]]

local SurvivorRigConfig = {}

export type SurvivorGender = "Male" | "Female"

export type SurvivorProfile = {
    Id: string,
    DisplayName: string,
    Gender: SurvivorGender,
    Description: string,
    TargetHeight: number,          -- Strict 5.970 studs standard
    HipHeight: number,             -- Calibrated ground sneaker/boot contact
    LegCorrectionAngleDeg: number, -- Inward tilt to eliminate Mixamo A-pose wide splay
    ArmClearanceAngleDeg: number,  -- Outward tilt so hands don't clip into thighs/shorts
    BoneNamespace: string?,        -- e.g. "mixamorig6" for JODY (auto-normalized to mixamorig)
    MeshParts: { string }?,        -- Expected constituent meshes
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
    LegCorrectionAngleDeg = 9.5,   -- Neutralizes wide 13.3° Mixamo A-pose flare to a relaxed 0.75 stud stance
    ArmClearanceAngleDeg = 4.0,    -- Gives hands comfortable 2-inch clearance from shorts/hips
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
    LegCorrectionAngleDeg = 3.5,   -- Athletic masculine stance (grounded parallel feet)
    ArmClearanceAngleDeg = 3.0,    -- Athletic arm drape
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
        ArmClearanceAngleDeg = FemaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Ch02_Body", "Ch02_Cloth", "Ch02_Sneakers", "Ch02_Socks", "Ch02_Hair", "Ch02_Eyelashes" },
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
        ArmClearanceAngleDeg = FemaleBase.ArmClearanceAngleDeg,
        BoneNamespace = "mixamorig6", -- Will be automatically normalized to mixamorig
        MeshParts = { "Ch37_Body" },
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
        ArmClearanceAngleDeg = MaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Ch42_Body" },
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
        ArmClearanceAngleDeg = MaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Remy_Body", "Remy_Shoes" },
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
        ArmClearanceAngleDeg = MaleBase.ArmClearanceAngleDeg,
        MeshParts = { "Ch18" },
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
        ArmClearanceAngleDeg = 0.0,
        MeshParts = { "Beta_Surface" },
        Facial = { HasSmile = false, MicroGazeRangeDeg = 0.0, HeadRestTiltDeg = 0.0 },
    } :: SurvivorProfile,
}

function SurvivorRigConfig.GetProfile(nameOrId: string): SurvivorProfile
    local clean = string.gsub(nameOrId, "%s+", "")
    for id, profile in pairs(SurvivorRigConfig.Profiles) do
        if string.lower(id) == string.lower(clean) or string.lower(profile.DisplayName) == string.lower(clean) then
            return profile
        end
    end
    -- Fallback to Male or Female base depending on detection
    if string.find(string.lower(clean), "female") or string.find(string.lower(clean), "girl") then
        return {
            Id = clean,
            DisplayName = clean,
            Gender = FemaleBase.Gender,
            Description = "Custom Female Survivor",
            TargetHeight = FemaleBase.TargetHeight,
            HipHeight = FemaleBase.HipHeight,
            LegCorrectionAngleDeg = FemaleBase.LegCorrectionAngleDeg,
            ArmClearanceAngleDeg = FemaleBase.ArmClearanceAngleDeg,
            Facial = FemaleBase.Facial,
        }
    end
    return {
        Id = clean,
        DisplayName = clean,
        Gender = MaleBase.Gender,
        Description = "Custom Male Survivor",
        TargetHeight = MaleBase.TargetHeight,
        HipHeight = MaleBase.HipHeight,
        LegCorrectionAngleDeg = MaleBase.LegCorrectionAngleDeg,
        ArmClearanceAngleDeg = MaleBase.ArmClearanceAngleDeg,
        Facial = MaleBase.Facial,
    }
end

return SurvivorRigConfig
