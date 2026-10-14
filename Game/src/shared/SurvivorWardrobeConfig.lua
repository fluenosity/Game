--!strict
-- Curated R15 survivor roster and wardrobe options. All source assets live in
-- ReplicatedStorage.FluenosityShared.SurvivorRoster.

local Config = {}

Config.CharacterOrder = { "Leo", "Marcus", "Kai", "Maya", "Elena", "Chloe" }

Config.Characters = {
	Leo = { Gender = "Male", DisplayName = "Leo", Role = "THE TRACKER", Default = { Top = "leo_top", Pants = "leo_bottom", Shoes = "leo_shoes", Head = "leo_hair" } },
	Marcus = { Gender = "Male", DisplayName = "Marcus", Role = "THE LOOKOUT", Default = { Top = "marcus_top", Pants = "trail_pants", Shoes = "marcus_shoes", Head = "marcus_hair" } },
	Kai = { Gender = "Male", DisplayName = "Kai", Role = "THE RUNNER", Default = { Top = "kai_top", Pants = "trail_pants", Shoes = "kai_shoes", Head = "kai_hair" } },
	Maya = { Gender = "Female", DisplayName = "Maya", Role = "THE SCOUT", Default = { Top = "maya_top", Pants = "maya_bottom", Shoes = "maya_shoes", Head = "maya_hair" } },
	Elena = { Gender = "Female", DisplayName = "Elena", Role = "THE MEDIC", Default = { Top = "elena_top", Pants = "elena_bottom", Shoes = "elena_shoes", Head = "elena_hair" } },
	Chloe = { Gender = "Female", DisplayName = "Chloe", Role = "THE GUIDE", Default = { Top = "chloe_top", Pants = "chloe_bottom", Shoes = "chloe_shoes", Head = "chloe_hair" } },
}

Config.Categories = {
	Top = {
		Label = "TOP",
		ManagedClasses = { "Shirt" },
		ManagedNames = { "Shirt", "Hoodie", "Roblox T-Shirt", "T-Shirt-LongSleeve_Raglan-BlackWhite" },
		Options = {
			{ Id = "leo_top", Gender = "Male", Label = "FIELD SHIRT", Source = "Leo", Items = { "Shirt" } },
			{ Id = "marcus_top", Gender = "Male", Label = "TRAIL HOODIE", Source = "Marcus", Items = { "Hoodie" } },
			{ Id = "kai_top", Gender = "Male", Label = "CAMP TEE", Source = "Kai", Items = { "Roblox T-Shirt" } },
			{ Id = "maya_top", Gender = "Female", Label = "RAGLAN TOP", Source = "Maya", Items = { "T-Shirt-LongSleeve_Raglan-BlackWhite" } },
			{ Id = "elena_top", Gender = "Female", Label = "CAMP TEE", Source = "Elena", Items = { "Roblox T-Shirt" } },
			{ Id = "chloe_top", Gender = "Female", Label = "CLASSIC TOP", Source = "Chloe", Items = { "Shirt" } },
		},
	},
	Pants = {
		Label = "PANTS",
		ManagedClasses = { "Pants" },
		ManagedNames = { "Shorts", "Pants-Sweatpants-Black_6984763785", "Shorts-Bermuda-Black_9174391966" },
		Options = {
			{ Id = "leo_bottom", Gender = "Male", Label = "FIELD SHORTS", Source = "Leo", Items = { "Shorts" } },
			{ Id = "trail_pants", Gender = "Male", Label = "TRAIL PANTS", Source = "Marcus", Items = { "Pants-Sweatpants-Black_6984763785" } },
			{ Id = "maya_bottom", Gender = "Female", Label = "CAMP SHORTS", Source = "Maya", Items = { "Shorts-Bermuda-Black_9174391966" } },
			{ Id = "elena_bottom", Gender = "Female", Label = "TRAIL PANTS", Source = "Elena", Items = { "Pants-Sweatpants-Black_6984763785" } },
			{ Id = "chloe_bottom", Gender = "Female", Label = "CLASSIC PANTS", Source = "Chloe", Items = { "Pants" } },
		},
	},
	Shoes = {
		Label = "SHOES",
		ManagedClasses = {},
		ManagedNames = { "LeftShoe", "RightShoe", "LeftFootwear", "RightFootwear", "Shoes-Sneakers-Gray_Left_7193165925", "Shoes-Sneakers-Gray_Right_7193166879" },
		Options = {
			{ Id = "leo_shoes", Gender = "Male", Label = "FIELD SNEAKERS", Source = "Leo", Items = { "LeftShoe", "RightShoe" } },
			{ Id = "marcus_shoes", Gender = "Male", Label = "TRAIL SNEAKERS", Source = "Marcus", Items = { "LeftShoe", "RightShoe" } },
			{ Id = "kai_shoes", Gender = "Male", Label = "LIGHT SNEAKERS", Source = "Kai", Items = { "LeftShoe", "RightShoe" } },
			{ Id = "maya_shoes", Gender = "Female", Label = "GRAY SNEAKERS", Source = "Maya", Items = { "Shoes-Sneakers-Gray_Left_7193165925", "Shoes-Sneakers-Gray_Right_7193166879" } },
			{ Id = "elena_shoes", Gender = "Female", Label = "FIELD SNEAKERS", Source = "Elena", Items = { "LeftShoe", "RightShoe" } },
			{ Id = "chloe_shoes", Gender = "Female", Label = "LIGHT SNEAKERS", Source = "Chloe", Items = { "LeftShoe", "RightShoe" } },
		},
	},
	Head = {
		Label = "HEAD",
		ManagedClasses = {},
		ManagedNames = { "Hair", "GirlHair", "Hair-Female-003-Black", "ROBLOXCap" },
		Options = {
			{ Id = "leo_hair", Gender = "Male", Label = "SHORT HAIR", Source = "Leo", Items = { "Hair" } },
			{ Id = "marcus_hair", Gender = "Male", Label = "TOUSLED HAIR", Source = "Marcus", Items = { "Hair" } },
			{ Id = "kai_hair", Gender = "Male", Label = "DARK HAIR", Source = "Kai", Items = { "Hair" } },
			{ Id = "maya_hair", Gender = "Female", Label = "BLACK HAIR", Source = "Maya", Items = { "Hair-Female-003-Black" } },
			{ Id = "elena_hair", Gender = "Female", Label = "LONG HAIR", Source = "Elena", Items = { "GirlHair" } },
			{ Id = "chloe_hair", Gender = "Female", Label = "LONG HAIR", Source = "Chloe", Items = { "GirlHair" } },
			{ Id = "maya_cap", Gender = "Female", Label = "CAMP CAP", Source = "Maya", Items = { "Hair-Female-003-Black", "ROBLOXCap" } },
		},
	},
}

local optionById: { [string]: any } = {}
for _, category in pairs(Config.Categories) do
	for _, option in ipairs(category.Options) do
		optionById[option.Id] = option
	end
end

function Config.GetDefaultSelection(characterId: string?): { [string]: string }
	local safeCharacterId = if characterId and Config.Characters[characterId] then characterId else "Leo"
	local definition = Config.Characters[safeCharacterId]
	return {
		CharacterId = safeCharacterId,
		Top = definition.Default.Top,
		Pants = definition.Default.Pants,
		Shoes = definition.Default.Shoes,
		Head = definition.Default.Head,
	}
end

function Config.ValidateSelection(value: any): { [string]: string }?
	if typeof(value) ~= "table" then return nil end
	local characterId = value.CharacterId
	local character = if typeof(characterId) == "string" then Config.Characters[characterId] else nil
	if not character then return nil end

	local clean = { CharacterId = characterId }
	for categoryName in pairs(Config.Categories) do
		local optionId = value[categoryName]
		local option = if typeof(optionId) == "string" then optionById[optionId] else nil
		if not option or option.Gender ~= character.Gender then return nil end
		clean[categoryName] = option.Id
	end
	return clean
end

return Config
