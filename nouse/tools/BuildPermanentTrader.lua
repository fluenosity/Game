--!strict
--[[
    tools/BuildPermanentTrader.lua
    Permanently places Silas the Ash Trader inside the Trader House as an editable Model.
    Run this script in Roblox Studio Command Bar (Edit Mode).

    - Spawns Silas directly where your Studio Camera is looking!
    - Silas is a permanent Model in Workspace ("TraderSilas").
    - Automatically selected in the 3D Viewport with Move [Ctrl + 2] handles ready.
    - Preserved forever by server scripts at runtime.
]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

-- 1. Remove previous instance if re-running
local oldSilas = Workspace:FindFirstChild("TraderSilas")
if oldSilas then oldSilas:Destroy() end

-- 2. Find exact spot where user's Studio Editor Camera is looking
local cam = Workspace.CurrentCamera
local camCF = cam.CFrame
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local ray = Workspace:Raycast(camCF.Position, camCF.LookVector * 60, rayParams)
local hitPos = ray and ray.Position or (camCF.Position + camCF.LookVector * 10)

-- Raycast down to find floor surface
local floorRay = Workspace:Raycast(hitPos + Vector3.new(0, 5, 0), Vector3.new(0, -30, 0), rayParams)
local floorY = floorRay and floorRay.Position.Y or (hitPos.Y - 1.5)

-- Feet on floor, facing back towards the camera
local spawnPos = Vector3.new(hitPos.X, floorY + 3.2, hitPos.Z)
local lookDir = Vector3.new(camCF.Position.X - spawnPos.X, 0, camCF.Position.Z - spawnPos.Z).Unit
local spawnCF = CFrame.lookAt(spawnPos, spawnPos + lookDir)

-- 3. Build Model
local silas = Instance.new("Model")
silas.Name = "TraderSilas"
CollectionService:AddTag(silas, "TraderNPC")

local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(2, 2, 1)
hrp.CFrame = spawnCF
hrp.Transparency = 1
hrp.CanCollide = false
hrp.Anchored = true
hrp.Parent = silas
silas.PrimaryPart = hrp

local humanoid = Instance.new("Humanoid")
humanoid.Name = "Humanoid"
humanoid.MaxHealth = 100
humanoid.Health = 100
humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
humanoid.Parent = silas

local torso = Instance.new("Part")
torso.Name = "Torso"
torso.Size = Vector3.new(2.1, 2.2, 1.2)
torso.CFrame = spawnCF
torso.Color = Color3.fromRGB(48, 42, 38)
torso.Material = Enum.Material.Fabric
torso.Anchored = true
torso.CanCollide = false
torso.Parent = silas

local vest = Instance.new("Part")
vest.Name = "Vest"
vest.Size = Vector3.new(1.4, 1.8, 1.25)
vest.CFrame = spawnCF * CFrame.new(0, 0, 0.02)
vest.Color = Color3.fromRGB(92, 68, 48)
vest.Material = Enum.Material.Fabric
vest.Anchored = true
vest.CanCollide = false
vest.Parent = silas

local head = Instance.new("Part")
head.Name = "Head"
head.Size = Vector3.new(1.25, 1.25, 1.25)
head.CFrame = spawnCF * CFrame.new(0, 1.65, 0)
head.Color = Color3.fromRGB(224, 178, 142)
head.Material = Enum.Material.SmoothPlastic
head.Anchored = true
head.CanCollide = false
head.Parent = silas

local faceMesh = Instance.new("SpecialMesh")
faceMesh.MeshType = Enum.MeshType.Head
faceMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
faceMesh.Parent = head

local scarf = Instance.new("Part")
scarf.Name = "Scarf"
scarf.Size = Vector3.new(1.7, 0.5, 1.5)
scarf.CFrame = spawnCF * CFrame.new(0, 1.15, 0)
scarf.Color = Color3.fromRGB(165, 48, 40)
scarf.Material = Enum.Material.Fabric
scarf.Anchored = true
scarf.CanCollide = false
scarf.Parent = silas

local hatBrim = Instance.new("Part")
hatBrim.Name = "HatBrim"
hatBrim.Size = Vector3.new(2.4, 0.15, 2.4)
hatBrim.CFrame = spawnCF * CFrame.new(0, 2.25, 0)
hatBrim.Color = Color3.fromRGB(38, 32, 28)
hatBrim.Material = Enum.Material.Slate
hatBrim.Anchored = true
hatBrim.CanCollide = false
hatBrim.Parent = silas

local hatCrown = Instance.new("Part")
hatCrown.Name = "HatCrown"
hatCrown.Size = Vector3.new(1.4, 0.65, 1.4)
hatCrown.CFrame = spawnCF * CFrame.new(0, 2.60, 0)
hatCrown.Color = Color3.fromRGB(48, 40, 34)
hatCrown.Material = Enum.Material.Slate
hatCrown.Anchored = true
hatCrown.CanCollide = false
hatCrown.Parent = silas

for _, sideX in ipairs({ -1.35, 1.35 }) do
    local arm = Instance.new("Part")
    arm.Name = sideX < 0 and "LeftArm" or "RightArm"
    arm.Size = Vector3.new(0.9, 2.1, 0.9)
    arm.CFrame = spawnCF * CFrame.new(sideX, -0.05, 0)
    arm.Color = Color3.fromRGB(48, 42, 38)
    arm.Material = Enum.Material.Fabric
    arm.Anchored = true
    arm.CanCollide = false
    arm.Parent = silas
end

for _, sideX in ipairs({ -0.55, 0.55 }) do
    local leg = Instance.new("Part")
    leg.Name = sideX < 0 and "LeftLeg" or "RightLeg"
    leg.Size = Vector3.new(0.9, 2.2, 0.9)
    leg.CFrame = spawnCF * CFrame.new(sideX, -2.1, 0)
    leg.Color = Color3.fromRGB(34, 30, 28)
    leg.Material = Enum.Material.Fabric
    leg.Anchored = true
    leg.CanCollide = false
    leg.Parent = silas
end

local pack = Instance.new("Part")
pack.Name = "MerchantPack"
pack.Size = Vector3.new(1.8, 2.0, 0.9)
pack.CFrame = spawnCF * CFrame.new(0, 0.1, -0.9)
pack.Color = Color3.fromRGB(115, 82, 54)
pack.Material = Enum.Material.Wood
pack.Anchored = true
pack.CanCollide = false
pack.Parent = silas

local lantern = Instance.new("Part")
lantern.Name = "PackLantern"
lantern.Size = Vector3.new(0.4, 0.55, 0.4)
lantern.CFrame = spawnCF * CFrame.new(0.85, 0.5, -1.2)
lantern.Color = Color3.fromRGB(240, 190, 75)
lantern.Material = Enum.Material.Neon
lantern.Anchored = true
lantern.CanCollide = false
lantern.Parent = silas

local lanternLight = Instance.new("PointLight")
lanternLight.Color = Color3.fromRGB(255, 195, 80)
lanternLight.Range = 8
lanternLight.Brightness = 0.85
lanternLight.Parent = lantern

local bbg = Instance.new("BillboardGui")
bbg.Name = "Nameplate"
bbg.Size = UDim2.new(0, 240, 0, 75)
bbg.StudsOffset = Vector3.new(0, 3.6, 0)
bbg.AlwaysOnTop = true
bbg.MaxDistance = 60
bbg.Adornee = head
bbg.Parent = head

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 32)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "★ SILAS ★"
nameLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 22
nameLabel.TextStrokeColor3 = Color3.fromRGB(20, 15, 10)
nameLabel.TextStrokeTransparency = 0.2
nameLabel.Parent = bbg

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(1, 0, 0, 22)
subLabel.Position = UDim2.new(0, 0, 0, 32)
subLabel.BackgroundTransparency = 1
subLabel.Text = "Ash Trader • Barter [E]"
subLabel.TextColor3 = Color3.fromRGB(235, 220, 195)
subLabel.Font = Enum.Font.GothamMedium
subLabel.TextSize = 14
subLabel.TextStrokeColor3 = Color3.fromRGB(15, 10, 5)
subLabel.TextStrokeTransparency = 0.3
subLabel.Parent = bbg

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "SilasBarterPrompt"
prompt.ActionText = "Barter"
prompt.ObjectText = "Silas (Ash Trader)"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.HoldDuration = 0.2
prompt.MaxActivationDistance = 11.0
prompt.RequiresLineOfSight = false
prompt.Parent = torso

for _, p in ipairs(silas:GetDescendants()) do
    if p:IsA("BasePart") then p.Anchored = true end
end

silas.Parent = Workspace
Selection:Set({ silas })

print("----------------------------------------------------------------------")
print("✅ [SILAS SPAWNED DIRECTLY IN YOUR EDITOR VIEWPORT]")
print("👉 He is selected now! Press [Ctrl + 2] to move him or [Ctrl + 4] to rotate him.")
print("💾 Press [Ctrl + S] to save your place. He will stay there permanently!")
print("----------------------------------------------------------------------")
