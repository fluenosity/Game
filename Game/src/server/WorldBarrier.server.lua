--!strict
--[[
    WorldBarrier.server.lua
    Production-Grade Server-Side World Boundary & Smooth Return Engine.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Features:
    - Continuous proximity detection with early warning threshold
    - Smooth teleport & return pushback with zeroed momentum
    - Safe ground raycasting so players never clip under terrain
    - Client event synchronization for smooth cinematic vignette transitions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FluenosityShared = ReplicatedStorage:WaitForChild("FluenosityShared")
local MountainConfig = require(FluenosityShared:WaitForChild("MountainConfig"))

local function getOrCreateRemote(name: string, parent: Instance): RemoteEvent
	local remote = parent:FindFirstChild(name) :: RemoteEvent?
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = parent
	end
	return remote
end

local warnRemote = getOrCreateRemote("WorldBarrierWarning", FluenosityShared)
local returnRemote = getOrCreateRemote("WorldBarrierReturn", FluenosityShared)

local Bounds = MountainConfig.WorldBounds
local Barrier = MountainConfig.Barrier

-- Circular & Box barrier bounds
local BarrierRadius = Barrier.Radius or 720
local WarningRadius = Barrier.WarningRadius or 640

-- Track players currently returning to avoid duplicate teleports
local returningPlayers: { [Player]: boolean } = {}

-- Safe ground height check
local function getSafeGroundY(x: number, z: number, currentY: number): number
	local rayOrigin = Vector3.new(x, currentY + 40, z)
	local rayDir = Vector3.new(0, -120, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	local terrain = Workspace.Terrain
	if terrain then
		rayParams.FilterDescendantsInstances = { terrain }
	end
	local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
	if hit then
		return hit.Position.Y + 3.2
	end
	return math.max(currentY, Bounds.GroundTopY + 5)
end

-- Teleports player smoothly back inside
local function smoothReturnPlayer(player: Player, character: Model)
	if returningPlayers[player] then return end
	returningPlayers[player] = true

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		returningPlayers[player] = nil
		return
	end

	local pos = hrp.Position
	local planarVec = Vector2.new(pos.X, pos.Z)
	local dist = planarVec.Magnitude
	local dir = dist > 0.01 and planarVec.Unit or Vector2.new(0, 1)

	-- Push back safely along radial vector towards camp center
	local pushbackDist = Barrier.TeleportDistance or 35
	local targetPlanar = dir * math.max(0, dist - pushbackDist)
	local targetX = targetPlanar.X
	local targetZ = targetPlanar.Y

	local safeY = getSafeGroundY(targetX, targetZ, pos.Y)
	local targetCFrame = CFrame.new(targetX, safeY, targetZ)

	-- 1. Notify client to begin smooth cinematic fog blackout
	returnRemote:FireClient(player, "start_fade", Barrier.Message)

	-- 2. Give client brief 0.25s moment for vignette fade before position update
	task.delay(0.25, function()
		if hrp and hrp.Parent then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.CFrame = targetCFrame
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		
		-- 3. Notify client position has updated so it can smoothly fade back in
		returnRemote:FireClient(player, "complete_fade")
		
		task.delay(1.5, function()
			returningPlayers[player] = nil
		end)
	end)
end

-- Check player position
local function checkPlayer(player: Player)
	if returningPlayers[player] then return end

	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local pos = hrp.Position
	local distFromCenter = Vector2.new(pos.X, pos.Z).Magnitude

	if distFromCenter >= BarrierRadius then
		smoothReturnPlayer(player, char)
		return
	end

	-- Check warning proximity in the outer forest zone (640 to 720 studs)
	if distFromCenter > WarningRadius then
		local warningRatio = math.clamp((distFromCenter - WarningRadius) / (BarrierRadius - WarningRadius), 0, 1)
		warnRemote:FireClient(player, "proximity", warningRatio, Barrier.WarningMessage)
	else
		warnRemote:FireClient(player, "clear")
	end
end

-- Main barrier loop
task.spawn(function()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			checkPlayer(player)
		end
		task.wait(Barrier.CheckInterval)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	returningPlayers[player] = nil
end)

print(string.format("🛡️ [WorldBarrier] Active & Protected. Mountain Caldera Radius: %.0f studs (Warning at %.0f)", BarrierRadius, WarningRadius))

