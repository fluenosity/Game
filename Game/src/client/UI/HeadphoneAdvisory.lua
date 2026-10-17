--!strict
--[[
    HeadphoneAdvisory.lua
    Atmospheric headphone & spatial audio advisory screen
    for "Don't Let the Fire Die" — Fluenosity Studio.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IconPack = require(ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("IconPack"))

local HeadphoneAdvisory = {}

function HeadphoneAdvisory.Show(parent: Instance, onCompleted: () -> ())
    local screen = Instance.new("Frame")
    screen.Name = "HeadphoneAdvisoryScreen"
    screen.Size = UDim2.fromScale(1, 1)
    screen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    screen.BorderSizePixel = 0
    screen.ZIndex = 80
    screen.Parent = parent

    local clickDetector = Instance.new("TextButton")
    clickDetector.Name = "SkipClickDetector"
    clickDetector.Size = UDim2.fromScale(1, 1)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.AutoButtonColor = false
    clickDetector.ZIndex = 85
    clickDetector.Parent = screen

    local container = Instance.new("Frame")
    container.Name = "AdvisoryContainer"
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.fromScale(0.5, 0.5)
    container.Size = UDim2.new(0.70, 0, 0.50, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 81
    container.Parent = screen

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 16)
    layout.Parent = container

    -- Headphone Icon (Strictly on top of text)
    local icon = IconPack.CreateIcon("headphones", 46, Color3.fromRGB(245, 140, 40), 1)
    icon.Name = "A_HeadphoneIcon"
    icon.LayoutOrder = 1
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.ZIndex = 82
    icon.Parent = container

    -- Advisory Header
    local title = Instance.new("TextLabel")
    title.Name = "B_AdvisoryTitle"
    title.LayoutOrder = 2
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "HEADPHONES RECOMMENDED"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.TextWrapped = true
    title.TextTransparency = 1
    title.ZIndex = 82
    title.Parent = container

    -- Advisory Body
    local body = Instance.new("TextLabel")
    body.Name = "C_AdvisoryBody"
    body.LayoutOrder = 3
    body.Size = UDim2.new(1, 0, 0, 48)
    body.BackgroundTransparency = 1
    body.Font = Enum.Font.Gotham
    body.Text = "Headphones are strongly recommended for the best experience.\n3D spatial audio provides crucial cues to survive the frozen wilderness."
    body.TextColor3 = Color3.fromRGB(190, 190, 190)
    body.TextSize = 13
    body.TextWrapped = true
    body.TextTransparency = 1
    body.ZIndex = 82
    body.Parent = container

    -- Preload the icon texture so it's guaranteed to be in GPU memory before fading in
    pcall(function()
        ContentProvider:PreloadAsync({ icon })
    end)

    -- Fade In simultaneously
    local fadeInInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(icon, fadeInInfo, { ImageTransparency = 0 }):Play()
    TweenService:Create(title, fadeInInfo, { TextTransparency = 0 }):Play()
    local lastTween = TweenService:Create(body, fadeInInfo, { TextTransparency = 0 })
    lastTween:Play()
    lastTween.Completed:Wait()

    local runningThread = if onCompleted == nil then coroutine.running() else nil

    local hasAdvanced = false
    local advanceConn: RBXScriptConnection? = nil
    local clickConn: RBXScriptConnection? = nil

    local function advance()
        if hasAdvanced then return end
        hasAdvanced = true
        if advanceConn then advanceConn:Disconnect() advanceConn = nil end
        if clickConn then clickConn:Disconnect() clickConn = nil end

        local fadeOutInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(icon, fadeOutInfo, { ImageTransparency = 1 }):Play()
        TweenService:Create(title, fadeOutInfo, { TextTransparency = 1 }):Play()
        local out = TweenService:Create(body, fadeOutInfo, { TextTransparency = 1 })
        out:Play()
        out.Completed:Wait()

        screen:Destroy()
        if onCompleted then
            onCompleted()
        elseif runningThread then
            task.spawn(runningThread)
        end
    end

    clickConn = clickDetector.MouseButton1Click:Connect(advance)
    advanceConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            advance()
        end
    end)

    -- Auto-advances smoothly after 2.2 seconds
    task.delay(2.2, function()
        if not hasAdvanced then
            advance()
        end
    end)

    if onCompleted == nil then
        coroutine.yield()
    end
end

return HeadphoneAdvisory
