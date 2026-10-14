--!strict
--[[
    MountainGenerator.lua
    Modular mountain terrain generator for "Don't Let the Fire Die".
    Developed for Fluenosity Studio.
]]

local Terrain = game:GetService("Workspace").Terrain

local MountainGenerator = {}
MountainGenerator.__index = MountainGenerator

function MountainGenerator.new(config)
	local self = setmetatable({}, MountainGenerator)
	self.Config = config or require(game:GetService("ReplicatedStorage").FluenosityShared:FindFirstChild("MountainConfig"))
	return self
end

function MountainGenerator:clearExistingTerrain()
	local Bounds = self.Config.WorldBounds
	local BW = self.Config.MountainBandWidth
	local VR = self.Config.VoxelResolution
	local ChunkVoxels = self.Config.ChunkSize
	
	local BandMinX = Bounds.MinX - BW
	local BandMaxX = Bounds.MaxX + BW
	local BandMinZ = Bounds.MinZ - BW
	local BandMaxZ = Bounds.MaxZ + BW
	
	local function isInBand(x, z)
		return x < Bounds.MinX or x > Bounds.MaxX or z < Bounds.MinZ or z > Bounds.MaxZ
	end
	
	local chunksX = math.ceil((BandMaxX - BandMinX) / (ChunkVoxels * VR))
	local chunksZ = math.ceil((BandMaxZ - BandMinZ) / (ChunkVoxels * VR))
	local voxY = math.ceil((self.Config.MaxHeight + 20) / VR)
	
	for cx = 0, chunksX - 1 do
		for cz = 0, chunksZ - 1 do
			local chunkMinX = BandMinX + cx * ChunkVoxels * VR
			local chunkMaxX = math.min(chunkMinX + ChunkVoxels * VR, BandMaxX)
			local chunkMinZ = BandMinZ + cz * ChunkVoxels * VR
			local chunkMaxZ = math.min(chunkMinZ + ChunkVoxels * VR, BandMaxZ)
			
			local voxX = math.ceil((chunkMaxX - chunkMinX) / VR)
			local voxZ = math.ceil((chunkMaxZ - chunkMinZ) / VR)
			
			local hasOutside = false
			for vx = 0, voxX - 1 do
				for vz = 0, voxZ - 1 do
					local wx = chunkMinX + vx * VR + VR / 2
					local wz = chunkMinZ + vz * VR + VR / 2
					if isInBand(wx, wz) then
						hasOutside = true
						break
					end
				end
				if hasOutside then break end
			end
			
			if hasOutside then
				local matArr = {}
				local occArr = {}
				for x = 1, voxX do
					matArr[x] = {}
					occArr[x] = {}
					for y = 1, voxY do
						matArr[x][y] = {}
						occArr[x][y] = {}
						for z = 1, voxZ do
							matArr[x][y][z] = Enum.Material.Air
							occArr[x][y][z] = 0
						end
					end
				end
				
				local region = Region3.new(
					Vector3.new(chunkMinX, Bounds.GroundTopY, chunkMinZ),
					Vector3.new(chunkMinX + voxX * VR, Bounds.GroundTopY + voxY * VR, chunkMinZ + voxZ * VR)
				)
				
				pcall(function()
					Terrain:WriteVoxels(region, VR, matArr, occArr)
				end)
			end
		end
	end
end

function MountainGenerator:Generate()
	local Config = self.Config
	local Bounds = Config.WorldBounds
	local BW = Config.MountainBandWidth
	local VR = Config.VoxelResolution
	local ChunkVoxels = Config.ChunkSize
	
	self:clearExistingTerrain()
	
	local BandMinX = Bounds.MinX - BW
	local BandMaxX = Bounds.MaxX + BW
	local BandMinZ = Bounds.MinZ - BW
	local BandMaxZ = Bounds.MaxZ + BW
	
	local function isInBand(x, z)
		return x < Bounds.MinX or x > Bounds.MaxX or z < Bounds.MinZ or z > Bounds.MaxZ
	end
	
	local function distanceFromEdge(x, z)
		local dx = 0
		if x < Bounds.MinX then dx = Bounds.MinX - x
		elseif x > Bounds.MaxX then dx = x - Bounds.MaxX end
		local dz = 0
		if z < Bounds.MinZ then dz = Bounds.MinZ - z
		elseif z > Bounds.MaxZ then dz = z - Bounds.MaxZ end
		return math.sqrt(dx * dx + dz * dz)
	end
	
	local function getMountainHeight(x, z)
		local d = distanceFromEdge(x, z)
		if d > BW then return 0 end
		local t = math.clamp(d / BW, 0, 1)
		local baseRamp = Config.MinHeight + (Config.MaxHeight - Config.MinHeight) * (t ^ 0.6)
		
		local noiseSum = 0
		for i, oct in ipairs(Config.Noise.Octaves) do
			noiseSum = noiseSum + math.noise(x * oct.Scale + Config.Noise.Seed + i * 100, z * oct.Scale + Config.Noise.Seed + i * 100, 0) * oct.Amplitude
		end
		
		local ridge = math.noise(x * Config.Noise.RidgeScale + Config.Noise.Seed + 9999, z * Config.Noise.RidgeScale + Config.Noise.Seed + 9999, 0)
		ridge = 1 - math.abs(ridge)
		ridge = ridge * Config.Noise.RidgeAmplitude
		
		local heightMod = (noiseSum + ridge) * 0.5
		heightMod = math.clamp(heightMod, 0, 1.5)
		local height = baseRamp * (0.4 + heightMod * 0.8)
		
		local edgeBlend = math.clamp(t / 0.15, 0, 1)
		height = height * edgeBlend
		
		if t > 0.9 then
			local outerBlend = math.clamp((1 - t) / 0.1, 0, 1)
			height = height * (0.7 + outerBlend * 0.3)
		end
		
		return math.max(0, math.floor(height / VR) * VR)
	end
	
	local totalChunks = 0
	local chunksX = math.ceil((BandMaxX - BandMinX) / (ChunkVoxels * VR))
	local chunksZ = math.ceil((BandMaxZ - BandMinZ) / (ChunkVoxels * VR))
	
	for cx = 0, chunksX - 1 do
		for cz = 0, chunksZ - 1 do
			local chunkMinX = BandMinX + cx * ChunkVoxels * VR
			local chunkMaxX = math.min(chunkMinX + ChunkVoxels * VR, BandMaxX)
			local chunkMinZ = BandMinZ + cz * ChunkVoxels * VR
			local chunkMaxZ = math.min(chunkMinZ + ChunkVoxels * VR, BandMaxZ)
			
			local voxX = math.ceil((chunkMaxX - chunkMinX) / VR)
			local voxZ = math.ceil((chunkMaxZ - chunkMinZ) / VR)
			
			local maxH = 0
			for vx = 0, voxX - 1 do
				for vz = 0, voxZ - 1 do
					local wx = chunkMinX + vx * VR + VR / 2
					local wz = chunkMinZ + vz * VR + VR / 2
					if isInBand(wx, wz) then
						local h = getMountainHeight(wx, wz)
						if h > maxH then maxH = h end
					end
				end
			end
			
			if maxH <= 0 then continue end
			
			local voxY = math.ceil(maxH / VR) + 1
			local matArray = {}
			local occArray = {}
			
			for x = 1, voxX do
				matArray[x] = {}
				occArray[x] = {}
				for y = 1, voxY do
					matArray[x][y] = {}
					occArray[x][y] = {}
					for z = 1, voxZ do
						local wx = chunkMinX + (x - 1) * VR + VR / 2
						local wz = chunkMinZ + (z - 1) * VR + VR / 2
						local voxelBottomY = Bounds.GroundTopY + (y - 1) * VR
						local voxelTopY = Bounds.GroundTopY + y * VR
						
						if not isInBand(wx, wz) then
							matArray[x][y][z] = Enum.Material.Air
							occArray[x][y][z] = 0
						else
							local h = getMountainHeight(wx, wz)
							local material = Enum.Material.Air
							local occupancy = 0
							
							if voxelTopY <= h then
								local hag = voxelTopY - Bounds.GroundTopY
								if hag < Config.MaterialThresholds.Grass then
									material = Enum.Material.Grass
								elseif hag < Config.MaterialThresholds.Rock then
									material = Enum.Material.Rock
								elseif hag < Config.MaterialThresholds.Snow then
									material = Enum.Material.Basalt
								else
									material = Enum.Material.Snow
								end
								occupancy = 1
							elseif voxelBottomY < h then
								local fillFrac = (h - voxelBottomY) / VR
								local hag = (voxelBottomY + h) / 2 - Bounds.GroundTopY
								if hag < Config.MaterialThresholds.Grass then
									material = Enum.Material.Grass
								elseif hag < Config.MaterialThresholds.Rock then
									material = Enum.Material.Rock
								elseif hag < Config.MaterialThresholds.Snow then
									material = Enum.Material.Basalt
								else
									material = Enum.Material.Snow
								end
								occupancy = math.clamp(fillFrac, 0.25, 1)
							else
								material = Enum.Material.Air
								occupancy = 0
							end
							
							matArray[x][y][z] = material
							occArray[x][y][z] = occupancy
						end
					end
				end
			end
			
			local region = Region3.new(
				Vector3.new(chunkMinX, Bounds.GroundTopY, chunkMinZ),
				Vector3.new(chunkMinX + voxX * VR, Bounds.GroundTopY + voxY * VR, chunkMinZ + voxZ * VR)
			)
			
			pcall(function()
				Terrain:WriteVoxels(region, VR, matArray, occArray)
			end)
			
			totalChunks = totalChunks + 1
		end
	end
	
	return "Generated mountain terrain in " .. totalChunks .. " chunks"
end

return MountainGenerator
