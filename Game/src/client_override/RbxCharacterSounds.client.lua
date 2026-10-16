-- RbxCharacterSounds.client.lua
-- Overrides and silences Roblox's default character sound injector in StarterPlayerScripts.
-- All locomotion, material footsteps, jumping, and landing audio are handled by the
-- production-grade AAA Material Footstep Audio System in AudioManager and CharacterAnimationController.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function silenceCharacter(char: Model)
    local function silencePart(part: Instance)
        if part:IsA("BasePart") then
            local function silenceSound(s: Instance)
                if s:IsA("Sound") then
                    local name = s.Name
                    if name == "Running" or name == "Climbing" or name == "Jumping" or name == "Landing" or name == "FreeFalling" then
                        s.Volume = 0
                        s.SoundId = ""
                        s:Stop()
                    end
                end
            end
            for _, c in ipairs(part:GetChildren()) do
                silenceSound(c)
            end
            part.ChildAdded:Connect(silenceSound)
        end
    end

    for _, c in ipairs(char:GetChildren()) do
        silencePart(c)
    end
    char.ChildAdded:Connect(silencePart)
end

local function hookPlayer(p: Player)
    if p.Character then
        silenceCharacter(p.Character)
    end
    p.CharacterAdded:Connect(silenceCharacter)
end

for _, p in ipairs(Players:GetPlayers()) do
    hookPlayer(p)
end
Players.PlayerAdded:Connect(hookPlayer)
