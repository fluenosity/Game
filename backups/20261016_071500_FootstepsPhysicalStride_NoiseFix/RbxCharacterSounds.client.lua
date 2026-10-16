-- RbxCharacterSounds.client.lua
-- Overrides and silences Roblox's default character sound injector.
-- All locomotion, material footsteps, jumping, and landing audio are handled by the
-- production-grade AAA Material Footstep Audio System in AudioManager and CharacterAnimationController.

local character = script.Parent
local function silenceRootPart(hrp: Instance)
    if not hrp:IsA("BasePart") then return end
    local function cleanSound(child: Instance)
        if child:IsA("Sound") then
            local name = child.Name
            if name == "Running" or name == "Climbing" or name == "Jumping" or name == "Landing" or name == "FreeFalling" then
                child.Volume = 0
                child.SoundId = ""
                child:Stop()
            end
        end
    end
    for _, c in ipairs(hrp:GetChildren()) do
        cleanSound(c)
    end
    hrp.ChildAdded:Connect(cleanSound)
end

local hrp = character:FindFirstChild("HumanoidRootPart")
if hrp then
    silenceRootPart(hrp)
else
    character.ChildAdded:Connect(function(c)
        if c.Name == "HumanoidRootPart" then
            silenceRootPart(c)
        end
    end)
end
