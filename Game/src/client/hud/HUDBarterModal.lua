--!strict
--[[
    HUDBarterModal.lua
    AAA Glassmorphic Barter Exchange Modal for Silas the Ash Trader.
    Developed for Fluenosity Studio.
    Matches the project's premium dark slate & gold survival theme.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local InventoryConfig = require(sharedFolder:WaitForChild("InventoryConfig"))
local TradingConfig = require(sharedFolder:WaitForChild("TradingConfig"))
local IconPack = require(sharedFolder:WaitForChild("IconPack"))
local AudioManager = require(script.Parent.Parent:WaitForChild("AudioManager"))

export type HUDBarterModalInstance = {
    Container: Frame,
    Open: () -> (),
    Close: () -> (),
    Toggle: () -> (),
    IsOpen: () -> boolean,
    UpdateInventory: (inventory: { [number]: { Id: string, Count: number }? }) -> (),
    Destroy: () -> (),
}

local HUDBarterModal = {}

function HUDBarterModal.Create(parent: Instance): HUDBarterModalInstance
    local requestBarterEvent = sharedFolder:WaitForChild("RequestBarterTrade", 5) :: RemoteEvent?
    local barterResultEvent = sharedFolder:WaitForChild("BarterResult", 5) :: RemoteEvent?

    -- Current inventory map: ItemId -> totalCount
    local currentItemCounts: { [string]: number } = {}

    -- Fullscreen backdrop veil
    local veil = Instance.new("TextButton")
    veil.Name = "BarterModalVeil"
    veil.Size = UDim2.fromScale(1, 1)
    veil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    veil.BackgroundTransparency = 1
    veil.BorderSizePixel = 0
    veil.Text = ""
    veil.AutoButtonColor = false
    veil.Visible = false
    veil.ZIndex = 85
    veil.Parent = parent

    -- Centered Main Modal Card
    local modalFrame = Instance.new("Frame")
    modalFrame.Name = "BarterModalCard"
    modalFrame.Size = UDim2.fromOffset(720, 560)
    modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    modalFrame.Position = UDim2.new(0.5, 0, 0.5, 25)
    modalFrame.BackgroundColor3 = Color3.fromRGB(18, 16, 22)
    modalFrame.BackgroundTransparency = 0.08
    modalFrame.BorderSizePixel = 0
    modalFrame.ClipsDescendants = true
    modalFrame.ZIndex = 86
    modalFrame.Parent = veil

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 14)
    modalCorner.Parent = modalFrame

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Thickness = 1.8
    modalStroke.Color = Color3.fromRGB(245, 185, 65) -- Rich frontier gold
    modalStroke.Transparency = 0.2
    modalStroke.Parent = modalFrame

    local modalGrad = Instance.new("UIGradient")
    modalGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(26, 22, 30)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(14, 13, 17)),
    })
    modalGrad.Rotation = 45
    modalGrad.Parent = modalFrame

    -- Header Bar
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, -36, 0, 68)
    headerFrame.Position = UDim2.new(0, 18, 0, 14)
    headerFrame.BackgroundTransparency = 1
    headerFrame.ZIndex = 87
    headerFrame.Parent = modalFrame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "★ SILAS — THE ASH TRADER ★"
    title.TextColor3 = Color3.fromRGB(255, 215, 80)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 87
    title.Parent = headerFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, -60, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 34)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "FRONTIER BARTER EXCHANGE • WHAT YOU SEE IS WHAT YOU GET"
    subtitle.TextColor3 = Color3.fromRGB(205, 185, 155)
    subtitle.Font = Enum.Font.GothamMedium
    subtitle.TextSize = 13
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 87
    subtitle.Parent = headerFrame

    local UI = require(script.Parent.Parent:WaitForChild("UI"))

    -- Close Button [X] using modular glassmorphic vector icon button
    local closeButton = UI.IconButton.Create({
        IconName = "x",
        IconSize = 14,
        Size = 34,
        IsCloseButton = true,
        Position = UDim2.new(1, 0, 0, 6),
        AnchorPoint = Vector2.new(1, 0),
        ZIndex = 88,
        Parent = headerFrame,
        OnClick = function()
            -- closeModal connected later
        end,
    })

    -- Player Stock Ribbon
    local ribbon = Instance.new("Frame")
    ribbon.Name = "PlayerStockRibbon"
    ribbon.Size = UDim2.new(1, -36, 0, 42)
    ribbon.Position = UDim2.new(0, 18, 0, 88)
    ribbon.BackgroundColor3 = Color3.fromRGB(28, 24, 32)
    ribbon.BackgroundTransparency = 0.3
    ribbon.ZIndex = 87
    ribbon.Parent = modalFrame

    local ribbonCorner = Instance.new("UICorner")
    ribbonCorner.CornerRadius = UDim.new(0, 8)
    ribbonCorner.Parent = ribbon

    local ribbonStroke = Instance.new("UIStroke")
    ribbonStroke.Thickness = 1
    ribbonStroke.Color = Color3.fromRGB(65, 55, 75)
    ribbonStroke.Transparency = 0.5
    ribbonStroke.Parent = ribbon

    local ribbonText = Instance.new("TextLabel")
    ribbonText.Name = "StockText"
    ribbonText.Size = UDim2.new(1, -20, 1, 0)
    ribbonText.Position = UDim2.new(0, 10, 0, 0)
    ribbonText.BackgroundTransparency = 1
    ribbonText.Text = "YOUR SUPPLIES:  Wood: 0/5  •  Scrap Metal: 0  •  Bandages: 0"
    ribbonText.TextColor3 = Color3.fromRGB(240, 225, 205)
    ribbonText.Font = Enum.Font.GothamBold
    ribbonText.TextSize = 13
    ribbonText.TextXAlignment = Enum.TextXAlignment.Left
    ribbonText.ZIndex = 88
    ribbonText.Parent = ribbon

    -- Scrollable Recipe List Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "RecipeList"
    scrollFrame.Size = UDim2.new(1, -36, 1, -150)
    scrollFrame.Position = UDim2.new(0, 18, 0, 138)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 5
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(245, 185, 65)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.ZIndex = 87
    scrollFrame.Parent = modalFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    -- Table of UI trade card updater functions
    local tradeCardUpdaters: { () -> () } = {}

    -- Build Trade Recipe Cards
    for idx, recipe in ipairs(TradingConfig.Recipes) do
        local card = Instance.new("Frame")
        card.Name = "Card_" .. recipe.Id
        card.Size = UDim2.new(1, -8, 0, 84)
        card.BackgroundColor3 = Color3.fromRGB(25, 22, 28)
        card.BackgroundTransparency = 0.25
        card.LayoutOrder = idx
        card.ZIndex = 87
        card.Parent = scrollFrame

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Thickness = 1.2
        cardStroke.Color = Color3.fromRGB(60, 52, 68)
        cardStroke.Parent = card

        -- Left Column: Input (YOU GIVE)
        local giveFrame = Instance.new("Frame")
        giveFrame.Name = "GiveSection"
        giveFrame.Size = UDim2.new(0.35, 0, 1, 0)
        giveFrame.Position = UDim2.new(0, 12, 0, 0)
        giveFrame.BackgroundTransparency = 1
        giveFrame.ZIndex = 88
        giveFrame.Parent = card

        local inputDef = InventoryConfig.Items[recipe.InputItemId]
        local inputName = inputDef and inputDef.Name or recipe.InputItemId

        local giveLabel = Instance.new("TextLabel")
        giveLabel.Name = "GiveTitle"
        giveLabel.Size = UDim2.new(1, 0, 0, 16)
        giveLabel.Position = UDim2.new(0, 0, 0, 12)
        giveLabel.BackgroundTransparency = 1
        giveLabel.Text = "YOU GIVE:"
        giveLabel.TextColor3 = Color3.fromRGB(175, 155, 140)
        giveLabel.Font = Enum.Font.GothamBold
        giveLabel.TextSize = 11
        giveLabel.TextXAlignment = Enum.TextXAlignment.Left
        giveLabel.ZIndex = 88
        giveLabel.Parent = giveFrame

        local giveItem = Instance.new("TextLabel")
        giveItem.Name = "GiveItem"
        giveItem.Size = UDim2.new(1, 0, 0, 22)
        giveItem.Position = UDim2.new(0, 0, 0, 28)
        giveItem.BackgroundTransparency = 1
        giveItem.Text = string.format("%dx %s", recipe.InputCount, inputName)
        giveItem.TextColor3 = Color3.fromRGB(255, 230, 200)
        giveItem.Font = Enum.Font.GothamBold
        giveItem.TextSize = 15
        giveItem.TextXAlignment = Enum.TextXAlignment.Left
        giveItem.ZIndex = 88
        giveItem.Parent = giveFrame

        local carryLabel = Instance.new("TextLabel")
        carryLabel.Name = "CarryCount"
        carryLabel.Size = UDim2.new(1, 0, 0, 16)
        carryLabel.Position = UDim2.new(0, 0, 0, 52)
        carryLabel.BackgroundTransparency = 1
        carryLabel.Text = "You have: 0"
        carryLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
        carryLabel.Font = Enum.Font.GothamMedium
        carryLabel.TextSize = 12
        carryLabel.TextXAlignment = Enum.TextXAlignment.Left
        carryLabel.ZIndex = 88
        carryLabel.Parent = giveFrame

        -- Center Arrow
        local arrowContainer = Instance.new("Frame")
        arrowContainer.Name = "ExchangeArrow"
        arrowContainer.Size = UDim2.new(0, 36, 1, 0)
        arrowContainer.Position = UDim2.new(0.37, 0, 0, 0)
        arrowContainer.BackgroundTransparency = 1
        arrowContainer.ZIndex = 88
        arrowContainer.Parent = card

        local arrowIcon = IconPack.CreateIcon("arrow-right", 20, Color3.fromRGB(245, 185, 65), 0)
        arrowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        arrowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
        arrowIcon.ZIndex = 89
        arrowIcon.Parent = arrowContainer

        -- Right Column: Output (YOU RECEIVE)
        local getFrame = Instance.new("Frame")
        getFrame.Name = "GetSection"
        getFrame.Size = UDim2.new(0.38, 0, 1, 0)
        getFrame.Position = UDim2.new(0.44, 0, 0, 0)
        getFrame.BackgroundTransparency = 1
        getFrame.ZIndex = 88
        getFrame.Parent = card

        local getTitle = Instance.new("TextLabel")
        getTitle.Name = "GetTitle"
        getTitle.Size = UDim2.new(1, 0, 0, 16)
        getTitle.Position = UDim2.new(0, 0, 0, 12)
        getTitle.BackgroundTransparency = 1
        getTitle.Text = "YOU RECEIVE:"
        getTitle.TextColor3 = Color3.fromRGB(175, 155, 140)
        getTitle.Font = Enum.Font.GothamBold
        getTitle.TextSize = 11
        getTitle.TextXAlignment = Enum.TextXAlignment.Left
        getTitle.ZIndex = 88
        getTitle.Parent = getFrame

        local getItem = Instance.new("TextLabel")
        getItem.Name = "GetItem"
        getItem.Size = UDim2.new(1, 0, 0, 22)
        getItem.Position = UDim2.new(0, 0, 0, 28)
        getItem.BackgroundTransparency = 1
        getItem.Text = string.format("%dx %s", recipe.OutputCount, recipe.Name)
        getItem.TextColor3 = recipe.AccentColor
        getItem.Font = Enum.Font.GothamBold
        getItem.TextSize = 15
        getItem.TextXAlignment = Enum.TextXAlignment.Left
        getItem.ZIndex = 88
        getItem.Parent = getFrame

        local getDesc = Instance.new("TextLabel")
        getDesc.Name = "GetDesc"
        getDesc.Size = UDim2.new(1, 0, 0, 18)
        getDesc.Position = UDim2.new(0, 0, 0, 52)
        getDesc.BackgroundTransparency = 1
        getDesc.Text = recipe.Subtitle
        getDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
        getDesc.Font = Enum.Font.Gotham
        getDesc.TextSize = 11
        getDesc.TextXAlignment = Enum.TextXAlignment.Left
        getDesc.ZIndex = 88
        getDesc.Parent = getFrame

        -- Far Right: Action Button [BARTER]
        local btn = Instance.new("TextButton")
        btn.Name = "BarterButton"
        btn.Size = UDim2.fromOffset(115, 42)
        btn.Position = UDim2.new(1, -12, 0.5, 0)
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.BackgroundColor3 = Color3.fromRGB(38, 125, 68) -- Emerald
        btn.Text = "BARTER"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.ZIndex = 89
        btn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local bScale = Instance.new("UIScale")
        bScale.Scale = 1.0
        bScale.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Thickness = 1.2
        btnStroke.Color = Color3.fromRGB(60, 185, 95)
        btnStroke.Parent = btn

        btn.Activated:Connect(function()
            local curCount = currentItemCounts[recipe.InputItemId] or 0
            TweenService:Create(bScale, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play()
            task.delay(0.08, function()
                TweenService:Create(bScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
            end)
            if curCount >= recipe.InputCount then
                AudioManager.Play("Click")
                if requestBarterEvent then
                    requestBarterEvent:FireServer(recipe.Id)
                end
            else
                AudioManager.Play("Click")
            end
        end)

        -- Updater function for this card
        local function updateCard()
            local curCount = currentItemCounts[recipe.InputItemId] or 0
            carryLabel.Text = string.format("You carry: %d", curCount)

            if curCount >= recipe.InputCount then
                carryLabel.TextColor3 = Color3.fromRGB(110, 220, 140)
                btn.BackgroundColor3 = Color3.fromRGB(38, 130, 68)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Text = "BARTER"
                btnStroke.Color = Color3.fromRGB(75, 200, 110)
                btn.AutoButtonColor = true
            else
                local missing = recipe.InputCount - curCount
                carryLabel.TextColor3 = Color3.fromRGB(235, 100, 90)
                btn.BackgroundColor3 = Color3.fromRGB(42, 38, 44)
                btn.TextColor3 = Color3.fromRGB(150, 140, 145)
                btn.Text = string.format("NEED %d MORE", missing)
                btnStroke.Color = Color3.fromRGB(60, 52, 64)
                btn.AutoButtonColor = false
            end
        end

        table.insert(tradeCardUpdaters, updateCard)
    end

    local isOpen = false
    local onOpenCallback: (() -> ())? = nil
    local onCloseCallback: (() -> ())? = nil

    -- Close Button Interaction
    local function closeModal()
        if not isOpen then return end
        isOpen = false
        veil.Modal = false
        AudioManager.Play("InventoryClose")

        if onCloseCallback then
            onCloseCallback()
        end

        TweenService:Create(modalFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0.5, 30),
            BackgroundTransparency = 1,
        }):Play()

        local fadeVeil = TweenService:Create(veil, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        })
        fadeVeil:Play()
        fadeVeil.Completed:Connect(function()
            veil.Visible = false
        end)
    end

    local lastOpenedAt = 0

    local function openModal()
        if isOpen then return end
        isOpen = true
        lastOpenedAt = tick()
        veil.Visible = true
        veil.Modal = true
        veil.BackgroundTransparency = 1
        modalFrame.Position = UDim2.new(0.5, 0, 0.5, 30)
        modalFrame.BackgroundTransparency = 1

        AudioManager.Play("InventoryOpen")

        if onOpenCallback then
            onOpenCallback()
        end

        TweenService:Create(veil, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.45,
        }):Play()

        TweenService:Create(modalFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 0.08,
        }):Play()
    end

    closeButton.MouseButton1Click:Connect(closeModal)
    closeButton.Activated:Connect(closeModal)

    -- ESC / E Key to Close (with debounce so holding E on prompt doesn't instantly close)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if isOpen then
            if input.KeyCode == Enum.KeyCode.Escape then
                closeModal()
            elseif input.KeyCode == Enum.KeyCode.E and not gameProcessed and (tick() - lastOpenedAt > 0.45) then
                closeModal()
            end
        end
    end)

    -- Update inventory items count across cards & ribbon
    local function updateInventoryState(inventory: { [number]: { Id: string, Count: number }? })
        table.clear(currentItemCounts)
        for _, slot in pairs(inventory) do
            if slot and slot.Id and slot.Count then
                currentItemCounts[slot.Id] = (currentItemCounts[slot.Id] or 0) + slot.Count
            end
        end

        local woodCount = currentItemCounts["standard_wood"] or currentItemCounts["wood"] or 0
        local scrapCount = currentItemCounts["metal_scrap"] or 0
        local bandageCount = currentItemCounts["bandage"] or 0

        ribbonText.Text = string.format("YOUR SUPPLIES:  Wood: %d/5  •  Scrap Metal: %d  •  Bandages: %d", woodCount, scrapCount, bandageCount)

        for _, updateFn in ipairs(tradeCardUpdaters) do
            updateFn()
        end
    end

    return {
        Container = veil,
        Open = openModal,
        Close = closeModal,
        Toggle = function()
            if isOpen then closeModal() else openModal() end
        end,
        IsOpen = function()
            return isOpen
        end,
        UpdateInventory = updateInventoryState,
        SetOnOpen = function(cb)
            onOpenCallback = cb
        end,
        SetOnClose = function(cb)
            onCloseCallback = cb
        end,
        Destroy = function()
            veil:Destroy()
        end,
    }
end

return HUDBarterModal
