--!strict
--[[
    WarningScreen.lua
    Production-grade two-part health & psychological advisory for
    "Don't Let the Fire Die" — Fluenosity Studio.

    Sequence on pure black background:
      Screen 1: Photosensitivity & Epilepsy Seizure Warning
      Screen 2: Atmospheric, Sudden Audio & Darkness Disclaimer
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local WarningScreen = {}

function WarningScreen.Show(parent: Instance, onCompleted: (() -> ())?)
    local runningThread = if onCompleted == nil then coroutine.running() else nil

    local screen = Instance.new("Frame")
    screen.Name = "WarningScreen"
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
    clickDetector.ZIndex = 89
    clickDetector.Parent = screen

    ----------------------------------------------------------------------------
    -- SCREEN 1: PHOTOSENSITIVITY & EPILEPSY WARNING
    ----------------------------------------------------------------------------
    local container1 = Instance.new("Frame")
    container1.Name = "PhotosensitivityContainer"
    container1.AnchorPoint = Vector2.new(0.5, 0.5)
    container1.Position = UDim2.fromScale(0.5, 0.5)
    container1.Size = UDim2.new(0.82, 0, 0.85, 0)
    container1.BackgroundTransparency = 1
    container1.ZIndex = 81
    container1.Parent = screen

    local constraint1 = Instance.new("UISizeConstraint")
    constraint1.MaxSize = Vector2.new(720, 1000)
    constraint1.MinSize = Vector2.new(280, 200)
    constraint1.Parent = container1

    local layout1 = Instance.new("UIListLayout")
    layout1.FillDirection = Enum.FillDirection.Vertical
    layout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout1.VerticalAlignment = Enum.VerticalAlignment.Center
    layout1.SortOrder = Enum.SortOrder.LayoutOrder
    layout1.Padding = UDim.new(0, 16)
    layout1.Parent = container1

    local photoTitle = Instance.new("TextLabel")
    photoTitle.Name = "A_PhotoTitle"
    photoTitle.LayoutOrder = 1
    photoTitle.Size = UDim2.new(1, 0, 0, 0)
    photoTitle.AutomaticSize = Enum.AutomaticSize.Y
    photoTitle.BackgroundTransparency = 1
    photoTitle.Font = Enum.Font.GothamBold
    photoTitle.Text = "WARNING: PHOTOSENSITIVITY / EPILEPSY SEIZURES"
    photoTitle.TextColor3 = Color3.fromRGB(245, 140, 40)
    photoTitle.TextSize = 20
    photoTitle.TextWrapped = true
    photoTitle.TextTransparency = 1
    photoTitle.ZIndex = 82
    photoTitle.Parent = container1

    local photoBody = Instance.new("TextLabel")
    photoBody.Name = "B_PhotoBody"
    photoBody.LayoutOrder = 2
    photoBody.Size = UDim2.new(1, 0, 0, 0)
    photoBody.AutomaticSize = Enum.AutomaticSize.Y
    photoBody.BackgroundTransparency = 1
    photoBody.Font = Enum.Font.Gotham
    photoBody.Text = "A very small percentage of people may experience epileptic seizures or blackouts when exposed to certain kinds of flashing lights or light patterns. These persons, or even people who have no history of seizures or epilepsy, may experience epileptic symptoms or seizures while playing video games.\n\nIf you or any of your relatives has an epileptic condition or has had seizures of any kind, consult your physician before playing any video game.\n\nIMMEDIATELY DISCONTINUE use and consult a physician if you experience any of the following symptoms: dizziness, altered vision, eye or muscle twitching, involuntary movements, loss of awareness, disorientation, or convulsions."
    photoBody.TextColor3 = Color3.fromRGB(195, 195, 195)
    photoBody.TextSize = 12
    photoBody.TextWrapped = true
    photoBody.TextTransparency = 1
    photoBody.ZIndex = 82
    photoBody.Parent = container1

    -- Fade in Screen 1
    local fadeIn1 = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(photoTitle, fadeIn1, { TextTransparency = 0 }):Play()
    local lastTween1 = TweenService:Create(photoBody, fadeIn1, { TextTransparency = 0 })
    lastTween1:Play()
    lastTween1.Completed:Wait()

    local step1Done = false
    local step1Conn: RBXScriptConnection? = nil
    local step1Click: RBXScriptConnection? = nil
    local thread1 = coroutine.running()

    local function advanceStep1()
        if step1Done then return end
        step1Done = true
        if step1Conn then step1Conn:Disconnect() step1Conn = nil end
        if step1Click then step1Click:Disconnect() step1Click = nil end

        local fadeOut1 = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(photoTitle, fadeOut1, { TextTransparency = 1 }):Play()
        local out1 = TweenService:Create(photoBody, fadeOut1, { TextTransparency = 1 })
        out1:Play()
        out1.Completed:Wait()
        container1:Destroy()

        task.spawn(thread1)
    end

    step1Click = clickDetector.MouseButton1Click:Connect(advanceStep1)
    step1Conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            advanceStep1()
        end
    end)

    -- Auto-advance after 3.2s
    task.delay(3.2, function()
        if not step1Done then
            advanceStep1()
        end
    end)

    coroutine.yield()

    ----------------------------------------------------------------------------
    -- SCREEN 2: ATMOSPHERIC & PSYCHOLOGICAL ADVISORY
    ----------------------------------------------------------------------------
    local container2 = Instance.new("Frame")
    container2.Name = "AtmosphereContainer"
    container2.AnchorPoint = Vector2.new(0.5, 0.5)
    container2.Position = UDim2.fromScale(0.5, 0.5)
    container2.Size = UDim2.new(0.80, 0, 0.60, 0)
    container2.BackgroundTransparency = 1
    container2.ZIndex = 81
    container2.Parent = screen

    local constraint2 = Instance.new("UISizeConstraint")
    constraint2.MaxSize = Vector2.new(680, 800)
    constraint2.MinSize = Vector2.new(280, 150)
    constraint2.Parent = container2

    local layout2 = Instance.new("UIListLayout")
    layout2.FillDirection = Enum.FillDirection.Vertical
    layout2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout2.VerticalAlignment = Enum.VerticalAlignment.Center
    layout2.SortOrder = Enum.SortOrder.LayoutOrder
    layout2.Padding = UDim.new(0, 16)
    layout2.Parent = container2

    local horrorTitle = Instance.new("TextLabel")
    horrorTitle.Name = "A_HorrorTitle"
    horrorTitle.LayoutOrder = 1
    horrorTitle.Size = UDim2.new(1, 0, 0, 0)
    horrorTitle.AutomaticSize = Enum.AutomaticSize.Y
    horrorTitle.BackgroundTransparency = 1
    horrorTitle.Font = Enum.Font.GothamBold
    horrorTitle.Text = "ATMOSPHERE & CONTENT ADVISORY"
    horrorTitle.TextColor3 = Color3.fromRGB(245, 140, 40)
    horrorTitle.TextSize = 18
    horrorTitle.TextTransparency = 1
    horrorTitle.ZIndex = 82
    horrorTitle.Parent = container2

    local horrorBody = Instance.new("TextLabel")
    horrorBody.Name = "B_HorrorBody"
    horrorBody.LayoutOrder = 2
    horrorBody.Size = UDim2.new(1, 0, 0, 0)
    horrorBody.AutomaticSize = Enum.AutomaticSize.Y
    horrorBody.BackgroundTransparency = 1
    horrorBody.Font = Enum.Font.GothamMedium
    horrorBody.Text = "Contains intense atmosphere, sudden loud audio, and complete darkness. Player discretion is advised."
    horrorBody.TextColor3 = Color3.fromRGB(230, 230, 230)
    horrorBody.TextSize = 14
    horrorBody.TextWrapped = true
    horrorBody.TextTransparency = 1
    horrorBody.ZIndex = 82
    horrorBody.Parent = container2

    -- Fade in Screen 2
    local fadeIn2 = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(horrorTitle, fadeIn2, { TextTransparency = 0 }):Play()
    local lastTween2 = TweenService:Create(horrorBody, fadeIn2, { TextTransparency = 0 })
    lastTween2:Play()
    lastTween2.Completed:Wait()

    local step2Done = false
    local step2Conn: RBXScriptConnection? = nil
    local step2Click: RBXScriptConnection? = nil

    local function advanceStep2()
        if step2Done then return end
        step2Done = true
        if step2Conn then step2Conn:Disconnect() step2Conn = nil end
        if step2Click then step2Click:Disconnect() step2Click = nil end

        local fadeOut2 = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(horrorTitle, fadeOut2, { TextTransparency = 1 }):Play()
        local out2 = TweenService:Create(horrorBody, fadeOut2, { TextTransparency = 1 })
        out2:Play()
        out2.Completed:Wait()

        screen:Destroy()

        if onCompleted then
            onCompleted()
        elseif runningThread then
            task.spawn(runningThread)
        end
    end

    step2Click = clickDetector.MouseButton1Click:Connect(advanceStep2)
    step2Conn = UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            advanceStep2()
        end
    end)

    -- Auto-advance after 2.6s
    task.delay(2.6, function()
        if not step2Done then
            advanceStep2()
        end
    end)

    if onCompleted == nil then
        coroutine.yield()
    end
end

return WarningScreen
