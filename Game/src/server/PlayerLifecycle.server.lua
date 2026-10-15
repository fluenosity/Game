--!strict
-- Server-owned survivor spawning and wardrobe application.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

Players.CharacterAutoLoads = false

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local GameConfig = require(sharedFolder:WaitForChild("GameConfig"))
local WardrobeConfig = require(sharedFolder:WaitForChild("SurvivorWardrobeConfig"))
local WardrobeApplier = require(sharedFolder:WaitForChild("SurvivorWardrobeApplier"))
local SurvivorRigConfig = require(sharedFolder:WaitForChild("SurvivorRigConfig"))
local roster = sharedFolder:WaitForChild("SurvivorRoster")

local spawnRequest = sharedFolder:FindFirstChild("RequestSpawnCharacter")
if spawnRequest and not spawnRequest:IsA("RemoteFunction") then
	spawnRequest:Destroy()
	spawnRequest = nil
end
if not spawnRequest then
	local remote = Instance.new("RemoteFunction")
	remote.Name = "RequestSpawnCharacter"
	remote.Parent = sharedFolder
	spawnRequest = remote
end

local playersInSession: { [Player]: boolean } = {}
local savedSelections: { [Player]: { [string]: string } } = {}
local lastSpawnRequest: { [Player]: number } = {}

local function getGroundedSpawnCFrame(character: Model, spawnLocation: SpawnLocation?): CFrame
	if not spawnLocation then return CFrame.new(0, 10, 0) end

	local pivot = character:GetPivot()
	local lowestFootOffset = math.huge
	for _, footName in ipairs({ "LeftFoot", "RightFoot" }) do
		local foot = character:FindFirstChild(footName)
		if foot and foot:IsA("BasePart") then
			local bottom = foot.CFrame:PointToWorldSpace(Vector3.new(0, -foot.Size.Y * 0.5, 0))
			lowestFootOffset = math.min(lowestFootOffset, (bottom - pivot.Position):Dot(pivot.UpVector))
		end
	end
	if lowestFootOffset == math.huge then lowestFootOffset = 0 end

	local up = spawnLocation.CFrame.UpVector
	local spawnSurface = spawnLocation.Position + up * (spawnLocation.Size.Y * 0.5)
	local targetPivot = spawnSurface + up * (0.06 - lowestFootOffset)
	return CFrame.new(targetPivot) * spawnLocation.CFrame.Rotation
end

local function spawnCharacterForPlayer(player: Player, requestedSelection: any): (boolean, string?)
	if not player.Parent then return false, "Player left before spawn" end

	local useStarterCharacter = GameConfig.ShouldUseStarterCharacter()
	local template: Model? = nil
	local selection = nil

	if useStarterCharacter then
		local sc = StarterPlayer:FindFirstChild("StarterCharacter")
		if sc and sc:IsA("Model") then
			template = sc
		end
	end

	if not template then
		selection = WardrobeConfig.ValidateSelection(requestedSelection)
		if not selection then return false, "Invalid survivor or wardrobe selection" end
		template = roster:FindFirstChild(selection.CharacterId) :: Model?
		if not template or not template:IsA("Model") then
			return false, "Selected R15 survivor is missing from the roster"
		end
	end

	local templateHumanoid = template:FindFirstChildOfClass("Humanoid")
	if not templateHumanoid or templateHumanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return false, "Selected survivor is not a valid R15 character"
	end

	local character = template:Clone()
	character.Name = player.Name

	if not useStarterCharacter and selection then
		local applied, applyError = WardrobeApplier.Apply(character, selection, roster)
		if not applied then
			character:Destroy()
			return false, applyError
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not rootPart then
		character:Destroy()
		return false, "Selected R15 survivor is missing core rig parts"
	end

	if not humanoid:FindFirstChildOfClass("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local scs = StarterPlayer:FindFirstChild("StarterCharacterScripts")
	local standardAnimate = scs and scs:FindFirstChild("Animate")
	if not standardAnimate then
		local starterCharacter = StarterPlayer:FindFirstChild("StarterCharacter")
		standardAnimate = starterCharacter and starterCharacter:FindFirstChild("Animate")
	end

	local animateScript = character:FindFirstChild("Animate")
	if standardAnimate and standardAnimate:IsA("LocalScript") then
		if animateScript then
			animateScript:Destroy()
		end
		animateScript = standardAnimate:Clone()
		animateScript.Parent = character
	end
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Enabled = true
		for _, descendant in ipairs(animateScript:GetDescendants()) do
			if descendant:IsA("Animation") then
				local numericId = string.match(descendant.AnimationId, "(%d+)")
				if numericId then descendant.AnimationId = "rbxassetid://" .. numericId end
			end
		end

		-- Set survivor-specific signature idle and official Mixamo locomotion assets
		local charDef = selection and WardrobeConfig.Characters[selection.CharacterId]
		local profileId = (charDef and charDef.ProfileId) or (selection and selection.CharacterId) or "SOPHIE"
		character:SetAttribute("SurvivorProfileId", profileId)
		local profile = SurvivorRigConfig.GetProfile(profileId, character)
		local idleContainer = animateScript:FindFirstChild("idle")
		if not idleContainer then
			idleContainer = Instance.new("StringValue")
			idleContainer.Name = "idle"
			idleContainer.Parent = animateScript
		end
		local anim1 = idleContainer:FindFirstChild("Animation1")
		if not anim1 then
			anim1 = Instance.new("Animation")
			anim1.Name = "Animation1"
			anim1.Parent = idleContainer
		end
		anim1.AnimationId = "rbxassetid://103828063959982" -- StaticIDLEMAIND (10s primary static resting idle)

		local anim2 = idleContainer:FindFirstChild("Animation2")
		if not anim2 then
			anim2 = Instance.new("Animation")
			anim2.Name = "Animation2"
			anim2.Parent = idleContainer
		end
		anim2.AnimationId = "rbxassetid://132876566376642" -- IDLEMAIN2 (4s flavor idle)

		local anim3 = idleContainer:FindFirstChild("Animation3")
		if not anim3 then
			anim3 = Instance.new("Animation")
			anim3.Name = "Animation3"
			anim3.Parent = idleContainer
		end
		anim3.AnimationId = "rbxassetid://137772468102995" -- IDLEMAIN3 (3.27s flavor idle)

		local locomotion = profile and profile.Locomotion
		local isFemale = (profile and profile.Gender == "Female") or (charDef and charDef.Gender == "Female")
		if isFemale == nil then isFemale = true end

		local walkId = (locomotion and locomotion.Walk) or (isFemale and "rbxassetid://115531053004010" or "rbxassetid://70412449762831")
		local runId = (locomotion and locomotion.Run) or "rbxassetid://99676638771528"
		local jumpId = (locomotion and locomotion.Jump) or "rbxassetid://103074489051723"
		local fallId = (locomotion and locomotion.Fall) or "rbxassetid://103074489051723"

		local walkContainer = animateScript:FindFirstChild("walk")
		local walkAnim = walkContainer and walkContainer:FindFirstChild("WalkAnim")
		if walkAnim and walkAnim:IsA("Animation") then
			walkAnim.AnimationId = walkId
		end

		local runContainer = animateScript:FindFirstChild("run")
		local runAnim = runContainer and runContainer:FindFirstChild("RunAnim")
		if runAnim and runAnim:IsA("Animation") then
			runAnim.AnimationId = runId
		end

		local jumpContainer = animateScript:FindFirstChild("jump")
		local jumpAnim = jumpContainer and jumpContainer:FindFirstChild("JumpAnim")
		if jumpAnim and jumpAnim:IsA("Animation") then
			jumpAnim.AnimationId = jumpId
		end

		local fallContainer = animateScript:FindFirstChild("fall")
		local fallAnim = fallContainer and fallContainer:FindFirstChild("FallAnim")
		if fallAnim and fallAnim:IsA("Animation") then
			fallAnim.AnimationId = fallId
		end

		local swimContainer = animateScript:FindFirstChild("swim")
		local swimAnim = swimContainer and (swimContainer:FindFirstChild("Swim") or swimContainer:FindFirstChildOfClass("Animation"))
		if swimAnim and swimAnim:IsA("Animation") then
			swimAnim.AnimationId = "rbxassetid://117791765615739"
		end

		local swimIdleContainer = animateScript:FindFirstChild("swimidle")
		local swimIdleAnim = swimIdleContainer and (swimIdleContainer:FindFirstChild("SwimIdle") or swimIdleContainer:FindFirstChildOfClass("Animation"))
		if swimIdleAnim and swimIdleAnim:IsA("Animation") then
			swimIdleAnim.AnimationId = "rbxassetid://122627851214967"
		end

		local idleJumpContainer = animateScript:FindFirstChild("idlejump")
		if idleJumpContainer then
			idleJumpContainer:Destroy()
		end
	end

	humanoid.AutoRotate = true
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.WalkSpeed = 6
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 38
	if humanoid.HipHeight < 1 and not humanoid.AutomaticScalingEnabled then humanoid.HipHeight = 2.5 end

	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation") :: SpawnLocation?
	local spawnCFrame = getGroundedSpawnCFrame(character, spawnLocation)
	character:PivotTo(spawnCFrame)

	local previousCharacter = player.Character
	character.Parent = workspace
	player.Character = character
	if previousCharacter and previousCharacter ~= character then
		previousCharacter:Destroy()
	end
	task.defer(function()
		if humanoid.Parent == character then
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
	pcall(function()
		rootPart:SetNetworkOwner(player)
	end)

	local charId = selection and selection.CharacterId or "StarterCharacter"
	local definition = WardrobeConfig.Characters[charId]
	if definition then
		humanoid.DisplayName = definition.DisplayName
		player:SetAttribute("SelectedGender", definition.Gender)
		player:SetAttribute("CurrentCharacterGender", definition.Gender)
		player:SetAttribute("SelectedCharacterId", charId)
		player:SetAttribute("CurrentCharacterId", charId)
	else
		humanoid.DisplayName = "StarterCharacter"
		player:SetAttribute("SelectedGender", "Female")
		player:SetAttribute("CurrentCharacterGender", "Female")
		player:SetAttribute("SelectedCharacterId", "StarterCharacter")
		player:SetAttribute("CurrentCharacterId", "StarterCharacter")
	end
	playersInSession[player] = true
	savedSelections[player] = selection or WardrobeConfig.GetDefaultSelection("Sophie")
	return true, nil
end

local remoteFunction = spawnRequest :: RemoteFunction
remoteFunction.OnServerInvoke = function(player: Player, payload: any): (boolean, string?)
	local now = os.clock()
	local previousRequest = lastSpawnRequest[player]
	if previousRequest and now - previousRequest < 0.75 then
		return false, "Please wait before requesting another spawn"
	end
	lastSpawnRequest[player] = now
	if playersInSession[player] then
		if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
			return true, nil
		end
		return false, "Survivor selection is locked after entering the wilderness"
	end
	return spawnCharacterForPlayer(player, payload)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			humanoid.Died:Connect(function()
				task.wait(Players.RespawnTime)
				if player.Parent and playersInSession[player] then
					local selection = savedSelections[player] or WardrobeConfig.GetDefaultSelection("Sophie")
					local ok, err = spawnCharacterForPlayer(player, selection)
					if not ok then warn("[PlayerLifecycle] Respawn failed: " .. tostring(err)) end
				end
			end)
		end
	end)

	if GameConfig.ShouldDirectSpawn() then
		task.defer(function()
			if player.Parent and not playersInSession[player] then
				local selection = WardrobeConfig.GetDefaultSelection("Sophie")
				local ok, err = spawnCharacterForPlayer(player, selection)
				if not ok then warn("[PlayerLifecycle] Direct spawn failed: " .. tostring(err)) end
			end
		end)
	end
end

local function onPlayerRemoving(player: Player)
	playersInSession[player] = nil
	savedSelections[player] = nil
	lastSpawnRequest[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, existingPlayer in ipairs(Players:GetPlayers()) do
	onPlayerAdded(existingPlayer)
end
