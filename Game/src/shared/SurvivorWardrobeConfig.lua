--!strict
--[[
    SurvivorWardrobeConfig.lua
    Curated survivor roster configuration for the 4 imported characters:
    - Sophie (Female, Agile Scout)
    - Jody (Female, Combat Survivalist)
    - Bryce (Male, Combat Engineer)
    - Remy (Male, Frontline Defender)

    All characters are complete custom skinned rigs stored in:
    ReplicatedStorage.FluenosityShared.SurvivorRoster
]]

local Config = {}

export type SurvivorStats = {
	Agility: number,
	Combat: number,
	Endurance: number,
	Crafting: number,
}

export type SurvivorCharacter = {
	Id: string,
	DisplayName: string,
	Gender: "Female" | "Male",
	Role: string,
	Tagline: string,
	Description: string,
	Stats: SurvivorStats,
	Archetype: string,
	RecommendedIdle: string,
	AltIdles: { [string]: string },
}

Config.CharacterOrder = { "Sophie", "Jody", "Bryce", "Remy" }

Config.Characters = {
	Sophie = {
		Id = "Sophie",
		DisplayName = "Sophie",
		Gender = "Female",
		Role = "THE AGILE SCOUT",
		Tagline = "Quick on her feet, alert to the whispering winds.",
		Description = "Exceptional speed and wilderness awareness. Excels in foraging, reconnaissance, and evading forest threats before they strike.",
		Stats = {
			Agility = 95,
			Combat = 60,
			Endurance = 75,
			Crafting = 70,
		},
		Archetype = "Female Athletic Rig • Living Posture • 0.75 Stud Stance",
		RecommendedIdle = "rbxassetid://103828063959982", -- StaticIDLEMAIND (10s resting idle)
		AltIdles = {
			["Static Resting Idle"] = "rbxassetid://103828063959982",
			["Breathing Shift"] = "rbxassetid://132876566376642",
			["Observant Gaze"] = "rbxassetid://137772468102995",
		},
	} :: SurvivorCharacter,

	Jody = {
		Id = "Jody",
		DisplayName = "Jody",
		Gender = "Female",
		Role = "THE COMBAT SURVIVALIST",
		Tagline = "Fierce guardian hardened by cold winters.",
		Description = "Formidable close-quarters combatant with high resilience. Built to stand her ground and protect the team from lurking predators.",
		Stats = {
			Agility = 75,
			Combat = 90,
			Endurance = 85,
			Crafting = 65,
		},
		Archetype = "Female Combat Rig • Reinforced Posture • Normalized Armature",
		RecommendedIdle = "rbxassetid://103828063959982",
		AltIdles = {
			["Static Resting Idle"] = "rbxassetid://103828063959982",
			["Breathing Shift"] = "rbxassetid://132876566376642",
			["Observant Gaze"] = "rbxassetid://137772468102995",
		},
	} :: SurvivorCharacter,

	Bryce = {
		Id = "Bryce",
		DisplayName = "Bryce",
		Gender = "Male",
		Role = "THE COMBAT ENGINEER",
		Tagline = "Resourceful builder who turns scraps into salvation.",
		Description = "Specializes in tool craft, barrier reinforcement, and campfire efficiency. Keeps camp defenses robust when night falls.",
		Stats = {
			Agility = 70,
			Combat = 75,
			Endurance = 80,
			Crafting = 95,
		},
		Archetype = "Male Athletic Rig • Calibrated 1.98 Stud Contact • Zero Slide",
		RecommendedIdle = "rbxassetid://103828063959982",
		AltIdles = {
			["Static Resting Idle"] = "rbxassetid://103828063959982",
			["Breathing Shift"] = "rbxassetid://132876566376642",
			["Observant Gaze"] = "rbxassetid://137772468102995",
		},
	} :: SurvivorCharacter,

	Remy = {
		Id = "Remy",
		DisplayName = "Remy",
		Gender = "Male",
		Role = "THE FRONTLINE DEFENDER",
		Tagline = "Unshakable pillar against the encroaching dark.",
		Description = "Maximum physical resilience and defensive endurance. Capable of drawing predator aggro and carrying heavy supply loads.",
		Stats = {
			Agility = 60,
			Combat = 85,
			Endurance = 95,
			Crafting = 65,
		},
		Archetype = "Male Heavy Rig • Athletic Stance • Calibrated Boot Contact",
		RecommendedIdle = "rbxassetid://103828063959982",
		AltIdles = {
			["Static Resting Idle"] = "rbxassetid://103828063959982",
			["Breathing Shift"] = "rbxassetid://132876566376642",
			["Observant Gaze"] = "rbxassetid://137772468102995",
		},
	} :: SurvivorCharacter,
}

-- Backward-compatibility empty categories (models are self-contained skinned meshes)
Config.Categories = {}

function Config.GetDefaultSelection(characterId: string?): { [string]: string }
	local safeId = "Sophie"
	if characterId and Config.Characters[characterId] then
		safeId = characterId
	end
	return {
		CharacterId = safeId,
	}
end

function Config.ValidateSelection(value: any): { [string]: string }?
	if typeof(value) ~= "table" then return nil end
	local characterId = value.CharacterId
	if typeof(characterId) ~= "string" or not Config.Characters[characterId] then
		return nil
	end
	return {
		CharacterId = characterId,
	}
end

return Config
