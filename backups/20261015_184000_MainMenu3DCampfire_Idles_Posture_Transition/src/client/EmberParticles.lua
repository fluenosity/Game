--!strict
--[[
    EmberParticles.lua
    Lightweight, restrained floating embers and sparks for Don't Let the Fire Die.
    Built entirely with native UI frames and TweenService.
    Supports reduced motion mode for accessibility.
]]

local TweenService = game:GetService("TweenService")
local UITheme = require(script.Parent:WaitForChild("UITheme"))

local EmberParticles = {}
EmberParticles.__index = EmberParticles

export type EmberSystem = {
    Container: GuiObject,
    IsActive: boolean,
    ReducedMotion: boolean,
    ActiveEmbers: { [Instance]: boolean },
    SpawnConnection: thread?,
    
    Start: (self: EmberSystem) -> (),
    Stop: (self: EmberSystem) -> (),
    SetReducedMotion: (self: EmberSystem, enabled: boolean) -> (),
    Clear: (self: EmberSystem) -> (),
    Destroy: (self: EmberSystem) -> (),
}

function EmberParticles.new(container: GuiObject): EmberSystem
    local self = setmetatable({}, EmberParticles) :: any
    self.Container = container
    self.IsActive = false
    self.ReducedMotion = false
    self.ActiveEmbers = {}
    self.SpawnConnection = nil
    return self
end

function EmberParticles.SetReducedMotion(self: EmberSystem, enabled: boolean)
    self.ReducedMotion = enabled
    if enabled then
        self:Clear()
    end
end

local EMBER_COLORS = {
    UITheme.Colors.EmberPrimary,
    UITheme.Colors.EmberHot,
    UITheme.Colors.EmberGold,
    UITheme.Colors.EmberCrimson,
}

local function spawnSingleEmber(self: EmberSystem)
    if not self.IsActive or self.ReducedMotion or not self.Container.Parent then
        return
    end

    local size = math.random(2, 4)
    local startX = math.random(32, 68) / 100
    local startY = math.random(82, 96) / 100
    
    local driftX = (math.random(-14, 14) / 100)
    local targetY = startY - (math.random(35, 60) / 100)
    
    local lifetime = math.random(24, 42) / 10
    local color = EMBER_COLORS[math.random(1, #EMBER_COLORS)]

    local ember = Instance.new("Frame")
    ember.Name = "Ember"
    ember.Size = UDim2.fromOffset(size, size)
    ember.Position = UDim2.fromScale(startX, startY)
    ember.AnchorPoint = Vector2.new(0.5, 0.5)
    ember.BackgroundColor3 = color
    ember.BackgroundTransparency = 0.2
    ember.BorderSizePixel = 0
    ember.ZIndex = self.Container.ZIndex

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ember

    ember.Parent = self.Container
    self.ActiveEmbers[ember] = true

    local targetPos = UDim2.fromScale(startX + driftX, targetY)
    local tweenInfo = TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local tween = TweenService:Create(ember, tweenInfo, {
        Position = targetPos,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(math.max(1, size - 1), math.max(1, size - 1)),
    })

    tween.Completed:Connect(function()
        self.ActiveEmbers[ember] = nil
        ember:Destroy()
    end)

    tween:Play()
end

function EmberParticles.Start(self: EmberSystem)
    if self.IsActive then return end
    self.IsActive = true

    self.SpawnConnection = task.spawn(function()
        while self.IsActive do
            if not self.ReducedMotion then
                spawnSingleEmber(self)
            end
            task.wait(math.random(25, 55) / 100)
        end
    end)
end

function EmberParticles.Stop(self: EmberSystem)
    self.IsActive = false
    if self.SpawnConnection then
        task.cancel(self.SpawnConnection)
        self.SpawnConnection = nil
    end
end

function EmberParticles.Clear(self: EmberSystem)
    for ember in pairs(self.ActiveEmbers) do
        ember:Destroy()
    end
    table.clear(self.ActiveEmbers)
end

function EmberParticles.Destroy(self: EmberSystem)
    self:Stop()
    self:Clear()
end

return EmberParticles
