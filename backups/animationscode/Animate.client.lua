local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local pose = "Standing"

local function getRigScale()
	return Character:GetScale()
end

local AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
local HumanoidHipHeight = 2

local FFlagUserAnimateRemoveEmoteChatHook
do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserAnimateRemoveEmoteChatHook")
	end)
	FFlagUserAnimateRemoveEmoteChatHook = success and result
end

local EMOTE_TRANSITION_TIME = 0.1

local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0

local runAnimTrack = nil
local runAnimKeyframeHandler = nil

local switchToAnim
local idleCycle = { 1, 2, 1, 3 } -- 1 = StaticIDLEMAIND (10s), 2 = IDLEMAIN2 (4s), 3 = IDLEMAIN3 (3.27s)
local idleStep = 1
local currentIdleToken = 0

local function getIdleAnimationForStep(step)
	local cycleNum = idleCycle[step] or 1
	local idleFolder = script:FindFirstChild("idle")
	if idleFolder then
		local namedAnim = idleFolder:FindFirstChild("Animation" .. cycleNum)
		if namedAnim and namedAnim:IsA("Animation") and namedAnim.AnimationId ~= "" then
			return namedAnim
		end
	end
	local animSet = animTable["idle"]
	if animSet and animSet.count and animSet.count > 0 then
		local target = animSet[cycleNum] or animSet[1]
		if target and target.anim then
			return target.anim
		end
	end
	if animNames.idle and animNames.idle[cycleNum] then
		local anim = Instance.new("Animation")
		anim.AnimationId = animNames.idle[cycleNum].id
		return anim
	end
	return nil
end

local function scheduleNextIdleCycle(token, track)
	task.spawn(function()
		local currentIdx = idleCycle[idleStep] or 1
		local baseDuration = (currentIdx == 1) and 9.5 or ((currentIdx == 2) and 3.8 or 3.1)
		local waitDuration = baseDuration
		if track and track.Length > 0.5 then
			waitDuration = math.max(2.0, track.Length - 0.3)
		else
			local t0 = os.clock()
			while track and track.Length <= 0.5 and (os.clock() - t0) < 0.6 do
				task.wait(0.1)
			end
			if track and track.Length > 0.5 then
				waitDuration = math.max(2.0, track.Length - 0.3)
			end
		end

		task.wait(waitDuration)

		if token == currentIdleToken and pose == "Standing" and currentAnim == "idle" then
			idleStep = (idleStep % #idleCycle) + 1
			local nextAnim = getIdleAnimationForStep(idleStep)
			if nextAnim then
				switchToAnim(nextAnim, "idle", 0.35, Humanoid)
			end
		end
	end)
end

local PreloadedAnims = {}

local animTable = {}
local animNames = {
	idle =     {
		{ id = "rbxassetid://103828063959982", weight = 10 }, -- StaticIDLEMAIND (10s primary static resting idle)
		{ id = "rbxassetid://132876566376642", weight = 10 }, -- IDLEMAIN2 (4s flavor idle)
		{ id = "rbxassetid://137772468102995", weight = 10 }, -- IDLEMAIN3 (3.27s flavor idle)
	},
	walk =     {
		{ id = "rbxassetid://115531053004010", weight = 10 }
	},
	run =     {
		{ id = "rbxassetid://99676638771528", weight = 10 }
	},
	jump = {
		{ id = "rbxassetid://103074489051723", weight = 10 }
	},
	fall =     {
		{ id = "rbxassetid://103074489051723", weight = 10 }
	},
	climb = {
		{ id = "http://www.roblox.com/asset/?id=507765644", weight = 10 }
	},
	sit =     {
		{ id = "http://www.roblox.com/asset/?id=2506281703", weight = 10 }
	},
	toolnone = {
		{ id = "http://www.roblox.com/asset/?id=507768375", weight = 10 }
	},
	toolslash = {
		{ id = "http://www.roblox.com/asset/?id=522635514", weight = 10 }
	},
	toollunge = {
		{ id = "http://www.roblox.com/asset/?id=522638767", weight = 10 }
	},
	wave = {
		{ id = "http://www.roblox.com/asset/?id=507770239", weight = 10 }
	},
	point = {
		{ id = "http://www.roblox.com/asset/?id=507770453", weight = 10 }
	},
	dance = {
		{ id = "http://www.roblox.com/asset/?id=507771019", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507771955", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507772104", weight = 10 }
	},
	dance2 = {
		{ id = "http://www.roblox.com/asset/?id=507776043", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507776720", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507776879", weight = 10 }
	},
	dance3 = {
		{ id = "http://www.roblox.com/asset/?id=507777268", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507777451", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507777623", weight = 10 }
	},
	laugh = {
		{ id = "http://www.roblox.com/asset/?id=507770818", weight = 10 }
	},
	cheer = {
		{ id = "http://www.roblox.com/asset/?id=507770677", weight = 10 }
	},
}

-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
local emoteNames = { wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

-- Variables used in tracking if the character is using a ControllerManager.
-- This implementation assumes the common case of the ControllerManager being a
-- child of the character, and that only one ControllerManager exists under a given
-- character. If a ControllerManager is not placed under its associated character,
-- then it will not be detected by this script.
-- The basis for this decision is performance: A ChildAdded listener on the
-- character is less of a performance hit than a ChildAdded listener on the
-- Workspace. And a FindFirstChild is more performant than checking for multiple
-- controllers via GetChildren.
local groundSensorChangedListener:RBXScriptSignal? = nil
local managerRootChangedListener:RBXScriptSignal? = nil
local managerParentChangedListener:RBXScriptSignal? = nil
local charGroundSensor:ControllerPartSensor? = nil
local charControllerManager:ControllerManager? = nil

local CCLAnimationFixed
do
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserAnimationAbilityManagerFixed")
	end)
	CCLAnimationFixed = success and result
end

-- Clean up listeners associated with the character's ControllerManager
function resetManagerListeners()
	if groundSensorChangedListener then
		groundSensorChangedListener:Disconnect()
		groundSensorChangedListener = nil
	end
	if managerRootChangedListener then
		managerRootChangedListener:Disconnect()
		managerRootChangedListener = nil
	end
	if managerParentChangedListener then
		managerParentChangedListener:Disconnect()
		managerParentChangedListener = nil
	end
end

-- Clean up all listeners and reset state.
function teardownManager()
	resetManagerListeners()
	charGroundSensor = nil
	charControllerManager = nil
end

-- Returns true if checkManager controls the character associated with this script
-- If so, then checkManager is assigned to charControllerManager.
-- TODO: Remove this method when UserAnimationAbilityManagerFixed is made permanently true.
function processIfManagerBelongsToCharacter(checkManager:ControllerManager):boolean
	if checkManager.RootPart == Character.PrimaryPart then
		if charControllerManager ~= checkManager then
			resetManagerListeners()
			charGroundSensor = checkManager.GroundSensor
			groundSensorChangedListener = checkManager:GetPropertyChangedSignal("GroundSensor"):Connect(function()
				if processIfManagerBelongsToCharacter(checkManager) then
					groundSensorChangedListener:Disconnect()
					groundSensorChangedListener = nil
				end
			end)
			managerRootChangedListener = checkManager:GetPropertyChangedSignal("RootPart"):Connect(function()
				if processIfManagerBelongsToCharacter(checkManager) then
					managerRootChangedListener:Disconnect()
					managerRootChangedListener = nil
				end
			end)
			managerParentChangedListener = checkManager.AncestryChanged:Connect(function(_, parent)
				if parent == nil then
					resetManagerListeners()
					lookForControllerManager()
				end
			end)
			charControllerManager = checkManager
		end
		return true
	end
	return false
end

-- Attach to a confirmed-valid manager: record it, read its current GroundSensor,
-- and watch for GroundSensor changes, RootPart changes, and removal.
function setupManager(manager:ControllerManager)
	charControllerManager = manager
	charGroundSensor = manager.GroundSensor

	groundSensorChangedListener = manager:GetPropertyChangedSignal("GroundSensor"):Connect(function()
		charGroundSensor = charControllerManager.GroundSensor
	end)

	managerRootChangedListener = manager:GetPropertyChangedSignal("RootPart"):Connect(function()
		if manager.RootPart ~= Character.PrimaryPart then
			teardownManager()
			lookForControllerManager()
		end
	end)

	managerParentChangedListener = manager.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			teardownManager()
			lookForControllerManager()
		end
	end)
end

-- Looks for the first ControllerManager directly childed to the character. If such
-- a controller does not exist or if it does not control that character, then a listener
-- is set up to check if a controller is ever added.
function lookForControllerManager()
	if CCLAnimationFixed then
		local child:ControllerManager? = Character:FindFirstChildOfClass("ControllerManager")
		if child then
			if child.RootPart == Character.PrimaryPart then
				setupManager(child)
			else
				-- Manager exists but RootPart not yet assigned; wait for it.
				local rootPartListener:RBXScriptSignal
				rootPartListener = child:GetPropertyChangedSignal("RootPart"):Connect(function()
					if child.RootPart == Character.PrimaryPart then
						rootPartListener:Disconnect()
						setupManager(child)
					end
				end)
			end
		else
			local managerAddedListener:RBXScriptSignal
			managerAddedListener = Character.ChildAdded:Connect(function(newChild)
				if newChild:IsA("ControllerManager") then
					managerAddedListener:Disconnect()
					lookForControllerManager()
				end
			end)
		end
	else
		charGroundSensor = nil
		charControllerManager = nil

		local child:ControllerManager? = Character:FindFirstChildOfClass("ControllerManager")
		if child then
			processIfManagerBelongsToCharacter(child)
		end
		-- The call to processIfManagerBelongsToCharacter above will have
		-- assigned charControllerManager on success
		if charControllerManager == nil then
			local managerAddedListener:RBXScriptSignal
			managerAddedListener = Character.ChildAdded:Connect(function(child)
				if child:IsA("ControllerManager") then
					if processIfManagerBelongsToCharacter(child) then
						managerAddedListener:Disconnect()
						managerAddedListener = nil
					end
				end
			end)
		end
	end
end
lookForControllerManager()

math.randomseed(tick())

function findExistingAnimationInSet(set, anim)
	if set == nil or anim == nil then
		return 0
	end

	for idx = 1, set.count, 1 do
		if set[idx].anim.AnimationId == anim.AnimationId then
			return idx
		end
	end

	return 0
end

function configureAnimationSet(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:disconnect()
		end
	end
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0
	animTable[name].connections = {}

	local allowCustomAnimations = true

	local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
	if not success then
		allowCustomAnimations = true
	end

	-- check for config values
	local config = script:FindFirstChild(name)
	if (allowCustomAnimations and config ~= nil) then
		table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))

		local idx = 0
		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				local newWeight = 1
				local weightObject = childPart:FindFirstChild("Weight")
				if (weightObject ~= nil) then
					newWeight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				idx = animTable[name].count
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				animTable[name][idx].weight = newWeight
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
				table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
				table.insert(animTable[name].connections, childPart.ChildAdded:connect(function(property) configureAnimationSet(name, fileList) end))
				table.insert(animTable[name].connections, childPart.ChildRemoved:connect(function(property) configureAnimationSet(name, fileList) end))
			end
		end
	end

	-- fallback to defaults
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
		end
	end

	-- preload anims
	for i, animType in pairs(animTable) do
		for idx = 1, animType.count, 1 do
			if PreloadedAnims[animType[idx].anim.AnimationId] == nil then
				Humanoid:LoadAnimation(animType[idx].anim)
				PreloadedAnims[animType[idx].anim.AnimationId] = true
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------

function configureAnimationSetOld(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:disconnect()
		end
	end
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0
	animTable[name].connections = {}

	local allowCustomAnimations = true

	local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
	if not success then
		allowCustomAnimations = true
	end

	-- check for config values
	local config = script:FindFirstChild(name)
	if (allowCustomAnimations and config ~= nil) then
		table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				local weightObject = childPart:FindFirstChild("Weight")
				if (weightObject == nil) then
					animTable[name][idx].weight = 1
				else
					animTable[name][idx].weight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
				idx = idx + 1
			end
		end
	end

	-- fallback to defaults
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
			-- print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
		end
	end

	-- preload anims
	for i, animType in pairs(animTable) do
		for idx = 1, animType.count, 1 do
			Humanoid:LoadAnimation(animType[idx].anim)
		end
	end
end

-- Setup animation objects
function scriptChildModified(child)
	local fileList = animNames[child.Name]
	if (fileList ~= nil) then
		configureAnimationSet(child.Name, fileList)
	end
end

script.ChildAdded:connect(scriptChildModified)
script.ChildRemoved:connect(scriptChildModified)

-- Clear any existing animation tracks
-- Fixes issue with characters that are moved in and out of the Workspace accumulating tracks
local animator = if Humanoid then Humanoid:FindFirstChildOfClass("Animator") else nil
if animator then
	local animTracks = animator:GetPlayingAnimationTracks()
	for i,track in ipairs(animTracks) do
		track:Stop(0)
		track:Destroy()
	end
end

for name, fileList in pairs(animNames) do
	configureAnimationSet(name, fileList)
end

-- ANIMATION

-- declarations
local toolAnim = "None"
local toolAnimTime = 0

local jumpAnimTime = 0
local jumpAnimDuration = 0.31

local toolTransitionTime = 0.1
local fallTransitionTime = 0.2

local currentlyPlayingEmote = false

-- functions

function stopAllAnimations()
	local oldAnim = currentAnim

	idleStep = 1
	currentIdleToken = currentIdleToken + 1

	-- return to idle if finishing an emote
	if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
		oldAnim = "idle"
	end

	if currentlyPlayingEmote then
		oldAnim = "idle"
		currentlyPlayingEmote = false
	end

	currentAnim = ""
	currentAnimInstance = nil
	if (currentAnimKeyframeHandler ~= nil) then
		currentAnimKeyframeHandler:disconnect()
	end

	if (currentAnimTrack ~= nil) then
		currentAnimTrack:Stop()
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end

	-- clean up walk if there is one
	if (runAnimKeyframeHandler ~= nil) then
		runAnimKeyframeHandler:disconnect()
	end

	if (runAnimTrack ~= nil) then
		runAnimTrack:Stop()
		runAnimTrack:Destroy()
		runAnimTrack = nil
	end

	return oldAnim
end

function getHeightScale()
	if Humanoid then
		if not Humanoid.AutomaticScalingEnabled then
			-- When auto scaling is not enabled, the rig scale stands in for
			-- a computed scale.
			return getRigScale()
		end

		local scale = Humanoid.HipHeight / HumanoidHipHeight
		if AnimationSpeedDampeningObject == nil then
			AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
		end
		if AnimationSpeedDampeningObject ~= nil then
			scale = 1 + (Humanoid.HipHeight - HumanoidHipHeight) * AnimationSpeedDampeningObject.Value / HumanoidHipHeight
		end
		return scale
	end
	return getRigScale()
end

local function rootMotionCompensation(speed)
	local speedScaled = speed * 1.25
	local heightScale = getHeightScale()
	local runSpeed = speedScaled / heightScale
	return runSpeed
end

local smallButNotZero = 0.0001
local normalizedWalkSpeed = 0.47 -- Calibrated for default WalkSpeed = 6 (walk weight = 1.0)
local normalizedRunSpeed  = 1.25 -- Calibrated for sprint WalkSpeed = 16 (run weight = 1.0)

local function setRunSpeed(speed)
	local runSpeed = rootMotionCompensation(speed)

	local walkAnimationWeight = smallButNotZero
	local runAnimationWeight = smallButNotZero
	local timeWarp = 1

	if runSpeed <= normalizedWalkSpeed then
		walkAnimationWeight = 1
		timeWarp = math.clamp(runSpeed/normalizedWalkSpeed, 0.70, 1.35)
	elseif runSpeed < normalizedRunSpeed then
		local fadeInRun = (runSpeed - normalizedWalkSpeed)/(normalizedRunSpeed - normalizedWalkSpeed)
		walkAnimationWeight = 1 - fadeInRun
		runAnimationWeight  = fadeInRun
	else
		timeWarp = math.clamp(runSpeed/normalizedRunSpeed, 0.75, 1.35)
		runAnimationWeight = 1
	end
	currentAnimTrack:AdjustWeight(walkAnimationWeight)
	runAnimTrack:AdjustWeight(runAnimationWeight)
	currentAnimTrack:AdjustSpeed(timeWarp)
	runAnimTrack:AdjustSpeed(timeWarp)
end

function setAnimationSpeed(speed)
	if currentAnim == "walk" then
		setRunSpeed(speed)
	else
		if speed ~= currentAnimSpeed then
			currentAnimSpeed = speed
			currentAnimTrack:AdjustSpeed(currentAnimSpeed)
		end
	end
end

function keyFrameReachedFunc(frameName)
	if (frameName == "End") then
		if currentAnim == "walk" then
			if runAnimTrack.Looped ~= true then
				runAnimTrack.TimePosition = 0.0
			end
			if currentAnimTrack.Looped ~= true then
				currentAnimTrack.TimePosition = 0.0
			end
		else
			local repeatAnim = currentAnim
			-- return to idle if finishing an emote
			if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
				repeatAnim = "idle"
			end

			if currentlyPlayingEmote then
				if currentAnimTrack.Looped then
					-- Allow the emote to loop
					return
				end

				repeatAnim = "idle"
				currentlyPlayingEmote = false
			end

			local animSpeed = currentAnimSpeed
			local blendTime = (repeatAnim == "idle") and 0.35 or 0.15
			currentIdleToken = currentIdleToken + 1
			playAnimation(repeatAnim, blendTime, Humanoid)
			setAnimationSpeed(animSpeed)
		end
	end
end

function rollAnimation(animName)
	local roll = math.random(1, animTable[animName].totalWeight)
	local origRoll = roll
	local idx = 1
	while (roll > animTable[animName][idx].weight) do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end
	return idx
end

switchToAnim = function(anim, animName, transitionTime, humanoid)
	-- switch animation
	if (anim ~= currentAnimInstance) then

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop(transitionTime)
		end

		if (runAnimTrack ~= nil) then
			runAnimTrack:Stop(transitionTime)
			runAnimTrack = nil
		end

		currentAnimSpeed = 1.0

		-- load it to the humanoid; get AnimationTrack
		currentAnimTrack = humanoid:LoadAnimation(anim)
		currentAnimTrack.Priority = Enum.AnimationPriority.Core

		if animName == "idle" then
			currentAnimTrack.Looped = true
			currentIdleToken = currentIdleToken + 1
			scheduleNextIdleCycle(currentIdleToken, currentAnimTrack)
		elseif animName == "walk" or animName == "run" then
			currentAnimTrack.Looped = true
			idleStep = 1
			currentIdleToken = currentIdleToken + 1
		end

		-- check to see if we need to blend a walk/run animation
		if animName == "walk" then
			local runAnimName = "run"
			local runIdx = rollAnimation(runAnimName)

			runAnimTrack = humanoid:LoadAnimation(animTable[runAnimName][runIdx].anim)
			runAnimTrack.Priority = Enum.AnimationPriority.Core
			runAnimTrack.Looped = true

			-- Calculate exact initial blend weights so both tracks don't spike to 1.0
			local hrp = humanoid.RootPart
			local moveVel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
			local currentSpeed = Vector3.new(moveVel.X, 0, moveVel.Z).Magnitude
			local rSpeed = rootMotionCompensation(currentSpeed / 16.0)
			local initWalkWeight = 1.0
			local initRunWeight = smallButNotZero
			local timeWarp = 1.0
			if rSpeed <= normalizedWalkSpeed then
				initWalkWeight = 1.0
				timeWarp = math.clamp(rSpeed / normalizedWalkSpeed, 0.7, 1.4)
			elseif rSpeed < normalizedRunSpeed then
				local f = (rSpeed - normalizedWalkSpeed) / (normalizedRunSpeed - normalizedWalkSpeed)
				initWalkWeight = 1.0 - f
				initRunWeight = f
			else
				initWalkWeight = smallButNotZero
				initRunWeight = 1.0
				timeWarp = math.clamp(rSpeed / normalizedRunSpeed, 0.7, 1.4)
			end

			currentAnimTrack:Play(transitionTime, initWalkWeight, timeWarp)
			runAnimTrack:Play(transitionTime, initRunWeight, timeWarp)

			if (runAnimKeyframeHandler ~= nil) then
				runAnimKeyframeHandler:disconnect()
			end
			runAnimKeyframeHandler = runAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
		else
			currentAnimTrack:Play(transitionTime)
		end

		currentAnim = animName
		currentAnimInstance = anim

		-- set up keyframe name triggers
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
	elseif animName == "idle" and currentAnimTrack ~= nil and not currentAnimTrack.IsPlaying then
		currentAnimTrack:Play(transitionTime)
	end
end

function playAnimation(animName, transitionTime, humanoid)
	local anim = nil
	if animName == "idle" then
		if currentAnim == "idle" and currentAnimTrack ~= nil and currentAnimTrack.IsPlaying then
			return
		end
		anim = getIdleAnimationForStep(idleStep)
	else
		local idx = rollAnimation(animName)
		anim = animTable[animName][idx].anim
	end

	if anim then
		switchToAnim(anim, animName, transitionTime, humanoid)
	end
	currentlyPlayingEmote = false
end

function playEmote(emoteAnim, transitionTime, humanoid)
	switchToAnim(emoteAnim, emoteAnim.Name, transitionTime, humanoid)
	currentlyPlayingEmote = true
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local toolAnimName = ""
local toolAnimTrack = nil
local toolAnimInstance = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
	if (frameName == "End") then
		playToolAnimation(toolAnimName, 0.0, Humanoid)
	end
end


function playToolAnimation(animName, transitionTime, humanoid, priority)
	local idx = rollAnimation(animName)
	local anim = animTable[animName][idx].anim

	if (toolAnimInstance ~= anim) then

		if (toolAnimTrack ~= nil) then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			transitionTime = 0
		end

		-- load it to the humanoid; get AnimationTrack
		toolAnimTrack = humanoid:LoadAnimation(anim)
		if priority then
			toolAnimTrack.Priority = priority
		end

		-- play the animation
		toolAnimTrack:Play(transitionTime)
		toolAnimName = animName
		toolAnimInstance = anim

		currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
	end
end

function stopToolAnimations()
	local oldAnim = toolAnimName

	if (currentToolAnimKeyframeHandler ~= nil) then
		currentToolAnimKeyframeHandler:disconnect()
	end

	toolAnimName = ""
	toolAnimInstance = nil
	if (toolAnimTrack ~= nil) then
		toolAnimTrack:Stop()
		toolAnimTrack:Destroy()
		toolAnimTrack = nil
	end

	return oldAnim
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- STATE CHANGE HANDLERS

function onRunning(speed)
	local heightScale = getHeightScale()

	-- Adjust the walking speed if a ControllerManager is being used.
	-- "speed" is world speed, whereas we want local speed.
	-- IE, do not animate a walk if the character is stationary atop
	-- a moving platform.
	if charGroundSensor ~= nil and Humanoid.EvaluateStateMachine == false then
		local hrp = Humanoid.RootPart
		local sensedPart = charGroundSensor.SensedPart
		if sensedPart then
			local pos = charGroundSensor.HitFrame.Position
			local floorVel = sensedPart:GetVelocityAtPosition(pos)
			local assemblyVel = hrp.AssemblyLinearVelocity
			-- Ignore y-velocity, so that jumping does not influence the animation speed
			local relVel = Vector3.new(assemblyVel.X - floorVel.X, 0, assemblyVel.Z - floorVel.Z)
			local relSpeed = relVel.Magnitude
			local moveMag = charControllerManager.MovingDirection.Magnitude
			if moveMag < 0.1 then
				relSpeed = 0
				moveMag = 0
			elseif moveMag > 1.0 then
				moveMag = 1.0
			end
			speed = relSpeed * moveMag
		end
	end

	local movedDuringEmote = currentlyPlayingEmote and Humanoid.MoveDirection == Vector3.new(0, 0, 0)
	local speedThreshold = movedDuringEmote and (Humanoid.WalkSpeed / heightScale) or 0.75
	local hasMoveIntent = Humanoid.MoveDirection.Magnitude > 0.05
	if speed > speedThreshold * heightScale or hasMoveIntent then
		local scale = 16.0
		playAnimation("walk", 0.2, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Running"
	else
		if emoteNames[currentAnim] == nil and not currentlyPlayingEmote then
			playAnimation("idle", 0.2, Humanoid)
			pose = "Standing"
		end
	end
end

function onDied()
	pose = "Dead"
end

function onJumping()
	local hrp = Humanoid.RootPart
	local moveVel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
	local horizontalSpeed = Vector3.new(moveVel.X, 0, moveVel.Z).Magnitude
	local isMoving = horizontalSpeed > 1.2 or Humanoid.MoveDirection.Magnitude > 0.05
	if not isMoving then
		-- Idle jumping is strictly blocked: character must be moving/running
		Humanoid:ChangeState(Enum.HumanoidStateType.Running)
		return
	end
	playAnimation("jump", 0.12, Humanoid)
	jumpAnimTime = jumpAnimDuration
	pose = "Jumping"
end

function onClimbing(speed)
	speed /= getHeightScale()
	local scale = 5.0
	playAnimation("climb", 0.1, Humanoid)
	setAnimationSpeed(speed / scale)
	pose = "Climbing"
end

function onGettingUp()
	pose = "GettingUp"
end

function onFreeFall()
	if (jumpAnimTime <= 0) then
		if currentAnim ~= "jump" then
			playAnimation("fall", fallTransitionTime, Humanoid)
		end
	end
	pose = "FreeFall"
end

function onFallingDown()
	pose = "FallingDown"
end

function onSeated()
	pose = "Seated"
end

function onPlatformStanding()
	pose = "PlatformStanding"
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

function onSwimming(speed)
	speed /= getHeightScale()
	if speed > 1.00 then
		local scale = 10.0
		playAnimation("swim", 0.4, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Swimming"
	else
		playAnimation("swimidle", 0.4, Humanoid)
		pose = "Standing"
	end
end

function animateTool()
	if (toolAnim == "None") then
		playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
		return
	end

	if (toolAnim == "Slash") then
		playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end

	if (toolAnim == "Lunge") then
		playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end
end

function getToolAnim(tool)
	for _, c in ipairs(tool:GetChildren()) do
		if c.Name == "toolanim" and c.className == "StringValue" then
			return c
		end
	end
	return nil
end

local lastTick = 0

function stepAnimate(currentTime)
	local amplitude = 1
	local frequency = 1
	local deltaTime = currentTime - lastTick
	lastTick = currentTime

	local climbFudge = 0
	local setAngles = false

	if (jumpAnimTime > 0) then
		jumpAnimTime = jumpAnimTime - deltaTime
	end

	if (pose == "FreeFall" and jumpAnimTime <= 0) then
		if currentAnim ~= "jump" and currentAnim ~= "fall" then
			playAnimation("fall", fallTransitionTime, Humanoid)
		end
	elseif (pose == "Seated") then
		playAnimation("sit", 0.5, Humanoid)
		return
	elseif (pose == "Running") then
		playAnimation("walk", 0.14, Humanoid)
		local hrp = Humanoid.RootPart
		local moveVel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
		local hSpeed = Vector3.new(moveVel.X, 0, moveVel.Z).Magnitude
		setAnimationSpeed(hSpeed / 16.0)
	elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
		stopAllAnimations()
		amplitude = 0.1
		frequency = 1
		setAngles = true
	end

	-- Tool Animation handling
	local tool = Character:FindFirstChildOfClass("Tool")
	if tool and tool:FindFirstChild("Handle") then
		local animStringValueObject = getToolAnim(tool)

		if animStringValueObject then
			toolAnim = animStringValueObject.Value
			-- message recieved, delete StringValue
			animStringValueObject.Parent = nil
			toolAnimTime = currentTime + .3
		end

		if currentTime > toolAnimTime then
			toolAnimTime = 0
			toolAnim = "None"
		end

		animateTool()
	else
		stopToolAnimations()
		toolAnim = "None"
		toolAnimInstance = nil
		toolAnimTime = 0
	end
end

-- connect events
Humanoid.Died:connect(onDied)
Humanoid.Running:connect(onRunning)
Humanoid.Jumping:connect(onJumping)
Humanoid.Climbing:connect(onClimbing)
Humanoid.GettingUp:connect(onGettingUp)
Humanoid.FreeFalling:connect(onFreeFall)
Humanoid.FallingDown:connect(onFallingDown)
Humanoid.Seated:connect(onSeated)
Humanoid.PlatformStanding:connect(onPlatformStanding)
Humanoid.Swimming:connect(onSwimming)

-- Smooth landing transition: immediately reset jumpAnimTime and transition seamlessly to locomotion/idle
local function onLanded()
	jumpAnimTime = 0
	if currentAnimTrack and (currentAnim == "jump" or currentAnim == "fall") then
		currentAnimTrack:Stop(0.08)
	end
	local hrp = Humanoid.RootPart
	local moveVel = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
	local hSpeed = Vector3.new(moveVel.X, 0, moveVel.Z).Magnitude
	if hSpeed > 0.75 or Humanoid.MoveDirection.Magnitude > 0.05 then
		onRunning(hSpeed)
	else
		playAnimation("idle", 0.12, Humanoid)
		pose = "Standing"
	end
end

Humanoid.StateChanged:Connect(function(oldState, newState)
	if newState == Enum.HumanoidStateType.Landed then
		onLanded()
	end
end)

if not FFlagUserAnimateRemoveEmoteChatHook then
	-- setup emote chat hook
	game:GetService("Players").LocalPlayer.Chatted:connect(function(msg)
		local emote = ""
		if (string.sub(msg, 1, 3) == "/e ") then
			emote = string.sub(msg, 4)
		elseif (string.sub(msg, 1, 7) == "/emote ") then
			emote = string.sub(msg, 8)
		end

		if (pose == "Standing" and emoteNames[emote] ~= nil) then
			playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)
		end
	end)
end
	
-- emote bindable hook
script:WaitForChild("PlayEmote").OnInvoke = function(emote)
	-- Only play emotes when idling
	if pose ~= "Standing" then
		return
	end

	if emoteNames[emote] ~= nil then
		-- Default emotes
		playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)

		return true, currentAnimTrack
	elseif typeof(emote) == "Instance" and emote:IsA("Animation") then
		-- Non-default emotes
		playEmote(emote, EMOTE_TRANSITION_TIME, Humanoid)

		return true, currentAnimTrack
	end

	-- Return false to indicate that the emote could not be played
	return false
end

if Character.Parent ~= nil then
	-- initialize to idle
	playAnimation("idle", 0.1, Humanoid)
	pose = "Standing"
end

-- loop to handle timed state transitions and tool animations
while Character.Parent ~= nil do
	local _, currentGameTime = wait(0.1)
	stepAnimate(currentGameTime)
end