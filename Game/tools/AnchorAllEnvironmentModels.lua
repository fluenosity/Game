--[[
    AnchorAllEnvironmentModels.lua
    Run this in the Roblox Studio Command Bar (View -> Command Bar)
    while in Edit Mode to permanently lock and anchor all houses, props,
    sheds, chairs, barrels, and trees so they never collapse under physics.
]]

local count = 0
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") and not obj:IsA("Terrain") then
        if not obj.Anchored then
            obj.Anchored = true
            count = count + 1
        end
    end
end

print(string.format("✅ Successfully anchored %d unanchored parts across Workspace! Physics will never collapse them.", count))
