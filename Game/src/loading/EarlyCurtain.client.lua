--!strict
--[[
    EarlyCurtain.client.lua
    Runs in ReplicatedFirst before any other game assets or scripts replicate.
    Immediately suppresses Roblox's default loading UI and shields the screen
    with an atmospheric dark curtain to prevent any asset pop-in, shader flickers,
    or raw baseplate rendering.
]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- 1. Suppress Roblox default loading screen
pcall(function()
    ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- 2. Create early seamless black curtain
local earlyGui = Instance.new("ScreenGui")
earlyGui.Name = "DontLetTheFireDie_EarlyCurtain"
earlyGui.IgnoreGuiInset = true
earlyGui.DisplayOrder = 999
earlyGui.ResetOnSpawn = false
earlyGui.Parent = playerGui

local curtain = Instance.new("Frame")
curtain.Name = "BlackCurtain"
curtain.Size = UDim2.fromScale(1, 1)
curtain.BackgroundColor3 = Color3.fromRGB(6, 7, 9)
curtain.BorderSizePixel = 0
curtain.Parent = earlyGui

-- 3. Listen for MainMenu or Loading Screen initialization to smoothly dissolve
task.spawn(function()
    local startTime = tick()
    while tick() - startTime < 8 do
        if playerGui:FindFirstChild("DontLetTheFireDie_MenuGui") or playerGui:FindFirstChild("DontLetTheFireDie_DevLoadingGui") then
            break
        end
        task.wait(0.04)
    end

    task.wait(0.1)
    local fade = TweenService:Create(curtain, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
    })
    fade:Play()
    fade.Completed:Wait()
    earlyGui:Destroy()
end)
