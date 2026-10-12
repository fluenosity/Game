--!strict
--[[
    VegetationLayer.lua
    Clean, high-performance ground ecology engine.
    Uses strictly authored models from DontLetTheFireDieAssets (0 external grass models).
]]

local GroundCover = require(script.Parent:WaitForChild("GroundCover"))

local VegetationLayer = {}

function VegetationLayer.Populate(folder: Folder, injectedCfg: any?, injectedPathSystem: any?)
    return GroundCover.Populate(folder, injectedCfg, injectedPathSystem)
end

return VegetationLayer
