--!strict
-- Server-authoritative lobby roster, survivor selection sync, and host-only removal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local WardrobeConfig = require(sharedFolder:WaitForChild("SurvivorWardrobeConfig"))

local function getRemote(name: string, className: string): Instance
	local existing = sharedFolder:FindFirstChild(name)
	if existing and existing.ClassName ~= className then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		existing = Instance.new(className)
		existing.Name = name
		existing.Parent = sharedFolder
	end
	return existing
end

local getLobbySnapshot = getRemote("GetLobbySnapshot", "RemoteFunction") :: RemoteFunction
local lobbyStateChanged = getRemote("LobbyStateChanged", "RemoteEvent") :: RemoteEvent
local setLobbySelection = getRemote("SetLobbySelection", "RemoteEvent") :: RemoteEvent
local requestLobbyKick = getRemote("RequestLobbyKick", "RemoteFunction") :: RemoteFunction

local joinOrder: { [Player]: number } = {}
local nextJoinOrder = 0
local lastKickAt: { [Player]: number } = {}

local function getHost(): Player?
	local host: Player? = nil
	local hostOrder = math.huge
	for _, candidate in ipairs(Players:GetPlayers()) do
		local order = joinOrder[candidate] or math.huge
		if order < hostOrder then
			host = candidate
			hostOrder = order
		end
	end
	return host
end

local function makeSnapshot()
	local host = getHost()
	local members: { any } = {}
	for _, member in ipairs(Players:GetPlayers()) do
		local characterId = member:GetAttribute("SelectedCharacterId")
		if typeof(characterId) ~= "string" or not WardrobeConfig.Characters[characterId] then
			characterId = nil
		end
		table.insert(members, {
			UserId = member.UserId,
			Name = member.Name,
			DisplayName = member.DisplayName,
			CharacterId = characterId,
			IsHost = member == host,
			JoinOrder = joinOrder[member] or math.huge,
		})
	end
	table.sort(members, function(a, b)
		return a.JoinOrder < b.JoinOrder
	end)
	for _, member in ipairs(members) do member.JoinOrder = nil end
	return {
		HostUserId = host and host.UserId or 0,
		Capacity = 4,
		Members = members,
	}
end

local function publishSnapshot()
	local host = getHost()
	for _, member in ipairs(Players:GetPlayers()) do
		member:SetAttribute("IsLobbyHost", member == host)
	end
	lobbyStateChanged:FireAllClients(makeSnapshot())
end

getLobbySnapshot.OnServerInvoke = function(_requester: Player)
	return makeSnapshot()
end

setLobbySelection.OnServerEvent:Connect(function(requester: Player, characterId: any)
	if not requester.Parent or requester:GetAttribute("LobbyInGame") == true then return end
	if typeof(characterId) ~= "string" or #characterId > 24 then return end
	if not WardrobeConfig.Characters[characterId] then return end
	requester:SetAttribute("SelectedCharacterId", characterId)
	requester:SetAttribute("SelectedGender", WardrobeConfig.Characters[characterId].Gender)
	publishSnapshot()
end)

requestLobbyKick.OnServerInvoke = function(requester: Player, targetUserId: any): (boolean, string)
	local now = os.clock()
	if lastKickAt[requester] and now - lastKickAt[requester] < 1.5 then
		return false, "Please wait before trying again."
	end
	lastKickAt[requester] = now

	if requester ~= getHost() then
		return false, "Only the host can remove a player."
	end
	if requester:GetAttribute("LobbyInGame") == true then
		return false, "Players can only be removed from the lobby."
	end
	if typeof(targetUserId) ~= "number" or targetUserId % 1 ~= 0 or targetUserId <= 0 then
		return false, "Invalid player selection."
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == requester then
		return false, "That player is no longer in the lobby."
	end
	if target:GetAttribute("LobbyInGame") == true then
		return false, "That player has already entered the wilderness."
	end

	target:Kick("The lobby host removed you from the session.")
	return true, "Player removed."
end

local function onPlayerAdded(member: Player)
	if #Players:GetPlayers() > 4 then
		member:Kick("This session is full. Fireteam size is limited to four players.")
		return
	end
	nextJoinOrder += 1
	joinOrder[member] = nextJoinOrder
	member:SetAttribute("LobbyInGame", false)
	member:GetAttributeChangedSignal("SelectedCharacterId"):Connect(publishSnapshot)
	publishSnapshot()
end

local function onPlayerRemoving(member: Player)
	joinOrder[member] = nil
	lastKickAt[member] = nil
	task.defer(publishSnapshot)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, member in ipairs(Players:GetPlayers()) do
	if not joinOrder[member] then
		onPlayerAdded(member)
	end
end
