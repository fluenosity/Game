--!strict
-- Applies only server-approved, game-owned wardrobe choices to an R15 model.

local Config = require(script.Parent:WaitForChild("SurvivorWardrobeConfig"))

local Applier = {}

local function isManagedItem(item: Instance, category: any): boolean
	for _, className in ipairs(category.ManagedClasses) do
		if item.ClassName == className then return true end
	end
	for _, name in ipairs(category.ManagedNames) do
		if item.Name == name then return true end
	end
	return false
end

function Applier.Apply(character: Model, selection: any, roster: Instance): (boolean, string?)
	local clean = Config.ValidateSelection(selection)
	if not clean then return false, "Invalid survivor wardrobe selection" end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return false, "Survivor model must contain an R15 Humanoid"
	end

	for categoryName, category in pairs(Config.Categories) do
		local chosenId = clean[categoryName]
		local chosenOption = nil
		for _, option in ipairs(category.Options) do
			if option.Id == chosenId then chosenOption = option break end
		end
		if not chosenOption then return false, "Missing wardrobe option: " .. categoryName end

		local source = roster:FindFirstChild(chosenOption.Source)
		if not source or not source:IsA("Model") then
			return false, "Missing wardrobe source: " .. chosenOption.Source
		end

		for _, child in ipairs(character:GetChildren()) do
			if isManagedItem(child, category) then child:Destroy() end
		end

		for _, itemName in ipairs(chosenOption.Items) do
			local sourceItem = source:FindFirstChild(itemName)
			if not sourceItem then
				return false, "Missing wardrobe item " .. itemName .. " on " .. chosenOption.Source
			end
			local item = sourceItem:Clone()
			if item:IsA("Accessory") then
				humanoid:AddAccessory(item)
			else
				item.Parent = character
			end
		end
	end

	character:SetAttribute("SelectedCharacterId", clean.CharacterId)
	character:SetAttribute("WardrobeReady", true)
	return true
end

return Applier
