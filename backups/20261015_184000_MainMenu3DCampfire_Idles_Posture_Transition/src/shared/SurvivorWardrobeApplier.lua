--!strict
--[[
    SurvivorWardrobeApplier.lua
    Applies server-approved survivor selection and ensures proper kinematic
    calibration (HipHeight, attributes) for complete skinned survivor rigs.
]]

local Config = require(script.Parent:WaitForChild("SurvivorWardrobeConfig"))
local SurvivorRigConfig = require(script.Parent:WaitForChild("SurvivorRigConfig"))

local Applier = {}

function Applier.Apply(character: Model, selection: any, roster: Instance?): (boolean, string?)
	local clean = Config.ValidateSelection(selection)
	if not clean then
		return false, "Invalid survivor selection"
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false, "Survivor model must contain a Humanoid"
	end

	-- Apply calibrated HipHeight based on survivor archetype
	local profile = SurvivorRigConfig.GetProfile(clean.CharacterId)
	if profile and profile.HipHeight then
		humanoid.HipHeight = profile.HipHeight
	end

	character:SetAttribute("SelectedCharacterId", clean.CharacterId)
	character:SetAttribute("WardrobeReady", true)
	return true, nil
end

return Applier
