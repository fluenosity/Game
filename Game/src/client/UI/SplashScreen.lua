--!strict
--[[
    SplashScreen.lua
    Production-grade studio branding splash screen
    for "Don't Let the Fire Die" — Fluenosity Studio.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local SplashScreen = {}

function SplashScreen.Show(parent: Instance, onCompleted: () -> ())
    local screen = Instance.new("Frame")
    screen.Name = "StudioSplash"
    screen.Size = UDim2.fromScale(1, 1)
    screen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

    local studioTitle = Instance.new("TextLabel")
    studioTitle.Name = "StudioTitle"
    studioTitle.Size = UDim2.new(0.9, 0, 0, 36)
    studioTitle.Position = UDim2.fromScale(0.5, 0.5)
    studioTitle.AnchorPoint = Vector2.new(0.5, 0.5)
    studioTitle.BackgroundTransparency = 1
    studioTitle.Font = Enum.Font.GothamMedium
    studioTitle.Text = "A FLUENOSITY STUDIO PRODUCTION"
    studioTitle.TextColor3 = Color3.fromRGB(36, 36, 36)
    studioTitle.TextScaled = false
    studioTitle.TextSize = 20
    studioTitle.TextTransparency = 1
    studioTitle.ZIndex = 82
    studioTitle.Parent = screen

    local studioConstraint = Instance.new("UITextSizeConstraint")
    studioConstraint.MaxTextSize = 22
    studioConstraint.MinTextSize = 12
    studioConstraint.Parent = studioTitle

    local fadeIn = TweenService:Create(studioTitle, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
    })
    fadeIn:Play()
    fadeIn.Completed:Wait()

    local runningThread = if onCompleted == nil then coroutine.running() else nil

    local hasAdvanced = false
    local advanceConn: RBXScriptConnection? = nil
    local clickConn: RBXScriptConnection? = nil

    local function advance()
        if hasAdvanced then return end
        hasAdvanced = true
        if advanceConn then advanceConn:Disconnect() advanceConn = nil end
        if clickConn then clickConn:Disconnect() clickConn = nil end

        local fadeOutText = TweenService:Create(studioTitle, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1,
        })
        fadeOutText:Play()
        fadeOutText.Completed:Wait()

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

    task.delay(1.4, function()
        if not hasAdvanced then
            advance()
        end
    end)

    if onCompleted == nil then
        coroutine.yield()
    end
end

return SplashScreen
