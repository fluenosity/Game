import json

with open(r'i:\RobloxDev\scripts\Animate_ThreeIdles.lua', 'r', encoding='utf-8') as f:
    lua_source = f.read()

# Prepare Luau code that receives the source in chunks to avoid single string token limit
chunks = []
chunk_size = 4000
for i in range(0, len(lua_source), chunk_size):
    chunk = lua_source[i:i+chunk_size]
    # Escape quotes and backslashes for Luau string literal
    escaped = chunk.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')
    chunks.append(f'"{escaped}"')

chunks_luau = "{\n" + ",\n".join(chunks) + "\n}"

luau_script = f"""local chunks = {chunks_luau}
local fullSource = table.concat(chunks)

local updated = {{}}

local function updateAnimate(obj, label)
    if obj and obj:IsA("LocalScript") then
        obj.Source = fullSource
        table.insert(updated, label)
    end
end

local starterPlayer = game:GetService("StarterPlayer")
local scs = starterPlayer:FindFirstChild("StarterCharacterScripts")
if scs then
    updateAnimate(scs:FindFirstChild("Animate"), "StarterPlayer.StarterCharacterScripts.Animate")
end

for _, rigName in ipairs({{"NewFemaleRig", "NewMaleRig"}}) do
    local rig = workspace:FindFirstChild(rigName)
    if rig then
        updateAnimate(rig:FindFirstChild("Animate"), "Workspace." .. rigName)
    end
end

local serverStorage = game:GetService("ServerStorage")
local pack = serverStorage:FindFirstChild("RealismCharacterPack")
if pack then
    for _, gender in ipairs({{"Male", "Female"}}) do
        local model = pack:FindFirstChild(gender)
        if model then
            updateAnimate(model:FindFirstChild("Animate"), "ServerStorage.RealismCharacterPack." .. gender)
        end
    end
end

local replicatedStorage = game:GetService("ReplicatedStorage")
local sharedFolder = replicatedStorage:FindFirstChild("FluenosityShared")
local roster = sharedFolder and sharedFolder:FindFirstChild("SurvivorRoster")
if roster then
    for _, survivor in ipairs(roster:GetChildren()) do
        local anim = survivor:FindFirstChild("Animate")
        if anim then
            updateAnimate(anim, "SurvivorRoster." .. survivor.Name)
        end
    end
end

return "Successfully updated in Edit datamodel: " .. table.concat(updated, ", ")
"""

with open(r'i:\RobloxDev\scripts\update_animate_payload.lua', 'w', encoding='utf-8') as f:
    f.write(luau_script)

print("Payload written. Size:", len(luau_script))
