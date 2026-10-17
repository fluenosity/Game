--!strict
--[[
    DayNightCycle.server.lua
    Custom day/night cycle & time progression driver
    for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Production Architecture:
    - Server maintains authoritative game clock progression across phases (Dawn -> Day -> Dusk -> Night)
    - Replicates current time & day state via ReplicatedStorage.FluenosityShared.TimeState attributes
    - Fires BindableEvents on phase and day changes for server systems (Survival, Wildlife, Audio)
    - Delegates visual rendering to shared TimeVisuals engine (with per-frame smoothing handled
      on the client via DayNightClient.client.lua on RunService.RenderStepped).
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load configuration & visual engine
local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local TimeConfig = require(sharedFolder:WaitForChild("TimeConfig"))
local TimeVisuals = require(sharedFolder:WaitForChild("TimeVisuals"))

-- Get or initialize TimeState folder and events
local timeState = sharedFolder:FindFirstChild("TimeState") :: Folder?
if not timeState then
	timeState = Instance.new("Folder")
	timeState.Name = "TimeState"
	timeState.Parent = sharedFolder
end

local phaseChangedEvent = timeState:FindFirstChild("PhaseChanged") :: BindableEvent?
if not phaseChangedEvent then
	phaseChangedEvent = Instance.new("BindableEvent")
	phaseChangedEvent.Name = "PhaseChanged"
	phaseChangedEvent.Parent = timeState
end

local dayChangedEvent = timeState:FindFirstChild("DayChanged") :: BindableEvent?
if not dayChangedEvent then
	dayChangedEvent = Instance.new("BindableEvent")
	dayChangedEvent.Name = "DayChanged"
	dayChangedEvent.Parent = timeState
end

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

local currentDay: number = TimeConfig.StartDay
local currentHour: number = TimeConfig.FreezeTime and (TimeConfig.FreezeHour or 14.0) or TimeConfig.StartHour
local currentPhase: string = "Day"
local phaseProgress: number = 0.0

local lastPhase: string = ""
local lastDay: number = -1
local visualSyncTimer: number = 0.0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function getPhaseFromHour(hour: number): string
	for _, phase in ipairs(TimeConfig.Phases) do
		if phase.Name == "Night" then
			if hour >= phase.StartHour or hour < phase.EndHour then
				return phase.Name
			end
		else
			if hour >= phase.StartHour and hour < phase.EndHour then
				return phase.Name
			end
		end
	end
	return "Day"
end

local function getPhaseDuration(phaseName: string): number
	return TimeConfig.PhaseDurations[phaseName] or 60
end

local function getPhaseHours(phaseName: string): number
	for _, phase in ipairs(TimeConfig.Phases) do
		if phase.Name == phaseName then
			if phase.Name == "Night" then
				return (24 - phase.StartHour) + phase.EndHour
			else
				return phase.EndHour - phase.StartHour
			end
		end
	end
	return 10
end

-- ---------------------------------------------------------------------------
-- Time advancement
-- ---------------------------------------------------------------------------

local function advanceTime(deltaTime: number)
	if TimeConfig.FreezeTime then
		currentHour = TimeConfig.FreezeHour or 14.0
		local newPhase = getPhaseFromHour(currentHour)
		currentPhase = newPhase
		phaseProgress = 0.5

		if timeState then
			timeState:SetAttribute("CurrentDay", currentDay)
			timeState:SetAttribute("CurrentHour", currentHour)
			timeState:SetAttribute("CurrentPhase", currentPhase)
			timeState:SetAttribute("PhaseProgress", phaseProgress)
		end

		visualSyncTimer = visualSyncTimer + deltaTime
		if visualSyncTimer >= 1.5 then
			visualSyncTimer = 0.0
			TimeVisuals.Apply(currentHour, currentDay)
		end
		return
	end

	local phaseName = getPhaseFromHour(currentHour)
	local duration = getPhaseDuration(phaseName)
	local phaseHours = getPhaseHours(phaseName)

	-- Advance game hours based on phase pacing with configurable speed multiplier
	local speedMult = TimeConfig.TimeSpeedMultiplier or 1.0
	local hoursPerSecond = (phaseHours / duration) * speedMult
	currentHour = currentHour + (hoursPerSecond * deltaTime)

	-- Wrap past midnight
	if currentHour >= 24 then
		currentHour = currentHour - 24
	end

	local newPhase = getPhaseFromHour(currentHour)

	-- Day increments when transitioning from Night to Dawn
	if lastPhase == "Night" and newPhase == "Dawn" then
		currentDay = currentDay + 1
	end

	-- Calculate phase progress (0-1)
	for _, phase in ipairs(TimeConfig.Phases) do
		if phase.Name == newPhase then
			if phase.Name == "Night" then
				if currentHour >= phase.StartHour then
					phaseProgress = (currentHour - phase.StartHour) / phaseHours
				else
					phaseProgress = ((24 - phase.StartHour) + currentHour) / phaseHours
				end
			else
				phaseProgress = (currentHour - phase.StartHour) / phaseHours
			end
			break
		end
	end

	local phaseChanged = (newPhase ~= lastPhase and lastPhase ~= "")
	local dayChanged = (currentDay ~= lastDay and lastDay ~= -1)

	-- Fire phase change event
	if phaseChanged then
		currentPhase = newPhase
		if phaseChangedEvent then
			phaseChangedEvent:Fire(currentPhase, currentDay)
		end
	end

	-- Fire day change event
	if dayChanged then
		if dayChangedEvent then
			dayChangedEvent:Fire(currentDay)
		end
	end

	lastPhase = newPhase
	lastDay = currentDay

	-- Update TimeState attributes for other systems and clients (continuous authority)
	if timeState then
		timeState:SetAttribute("CurrentDay", currentDay)
		timeState:SetAttribute("CurrentHour", currentHour)
		timeState:SetAttribute("CurrentPhase", newPhase)
		timeState:SetAttribute("PhaseProgress", phaseProgress)
	end

	-- Server baseline visual sync (throttled to 1.5s to prevent network property spam;
	-- clients render smoothly at 60/120 FPS on RenderStepped without packet jitter)
	visualSyncTimer = visualSyncTimer + deltaTime
	if phaseChanged or dayChanged or visualSyncTimer >= 1.5 then
		visualSyncTimer = 0.0
		TimeVisuals.Apply(currentHour, currentDay)
	end
end

-- ---------------------------------------------------------------------------
-- Initialization
-- ---------------------------------------------------------------------------

currentPhase = getPhaseFromHour(currentHour)
lastPhase = currentPhase
lastDay = currentDay

-- Ensure baseline visuals applied on server startup
TimeVisuals.Apply(currentHour, currentDay)

if timeState then
	timeState:SetAttribute("CurrentDay", currentDay)
	timeState:SetAttribute("CurrentHour", currentHour)
	timeState:SetAttribute("CurrentPhase", currentPhase)
	timeState:SetAttribute("PhaseProgress", 0.0)
end

RunService.Heartbeat:Connect(function(deltaTime: number)
	advanceTime(deltaTime)
end)
