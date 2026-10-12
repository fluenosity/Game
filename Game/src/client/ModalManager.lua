--!strict
--[[
    ModalManager.lua
    Global Client-Side Modal & Cursor Coordinator for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.

    Provides a clean, modular, and universally extensible registry for ANY modal,
    dialogue tree, crafting bench, shopkeeper, loot container, cutscene, or UI panel.

    When ANY registered modal opens:
      - Automatically frees the mouse cursor.
      - Automatically notifies the Camera / HUD controller to freeze camera rotation.
      - Automatically hides the center GTA V reticle.

    When all registered modals close:
      - Automatically re-locks cursor to center for First-Person Perspective (FPP).
      - Automatically unfreezes camera look.
      - Automatically restores the GTA V reticle without requiring an extra click.
]]

local ModalManager = {}

type ModalCheckFn = () -> boolean

local registeredModals: { [string]: ModalCheckFn } = {}
local activeOpenModals: { [string]: boolean } = {}
local stateChangeCallbacks: { (isAnyOpen: boolean) -> () } = {}

-- Register a dynamic modal query function (e.g. from an existing or future modal instance)
function ModalManager.Register(modalId: string, isOpenQuery: ModalCheckFn): () -> ()
    registeredModals[modalId] = isOpenQuery
    return function()
        registeredModals[modalId] = nil
        activeOpenModals[modalId] = nil
        ModalManager.NotifyStateChange()
    end
end

-- Manually set an open state by modal ID (e.g. ModalManager.SetOpen("DialogueSystem", true))
function ModalManager.SetOpen(modalId: string, isOpen: boolean)
    if activeOpenModals[modalId] == isOpen then return end
    activeOpenModals[modalId] = isOpen
    ModalManager.NotifyStateChange()
end

-- Check if any registered modal or manual state is currently open
function ModalManager.IsAnyModalOpen(): boolean
    for _, isOpen in pairs(activeOpenModals) do
        if isOpen == true then
            return true
        end
    end
    for _, queryFn in pairs(registeredModals) do
        local success, result = pcall(queryFn)
        if success and result == true then
            return true
        end
    end
    return false
end

-- Connect a listener that fires whenever modal state transitions between open and closed
function ModalManager.OnStateChanged(callback: (isAnyOpen: boolean) -> ()): () -> ()
    table.insert(stateChangeCallbacks, callback)
    return function()
        local idx = table.find(stateChangeCallbacks, callback)
        if idx then
            table.remove(stateChangeCallbacks, idx)
        end
    end
end

local lastKnownState: boolean? = nil

function ModalManager.NotifyStateChange()
    local currentState = ModalManager.IsAnyModalOpen()
    if lastKnownState ~= currentState then
        lastKnownState = currentState
        for _, cb in ipairs(stateChangeCallbacks) do
            task.spawn(cb, currentState)
        end
    end
end

return ModalManager
