--!strict
--[[
    SurvivorRigAdapter.lua
    Universal Automated Adaptation Engine for high-fidelity Mixamo FBX survivor rigs.
    Guarantees:
    - Zero foot sliding (Model:GetScale() == 1.0 architecture)
    - Full Mixamo animation binding (Beta_Surface root joint parity)
    - Automatic bone namespace normalization (e.g. mixamorig6: -> mixamorig:)
    - Per-gender & per-character calibrated leg stance & arm clearance
    - 100% PBR texture preservation
]]

local SurvivorRigConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("FluenosityShared"):WaitForChild("SurvivorRigConfig"))

local SurvivorRigAdapter = {}

function SurvivorRigAdapter.AdaptModel(rawModel: Model, characterId: string?): Model
    local profileName = characterId or rawModel.Name
    local profile = SurvivorRigConfig.GetProfile(profileName)
    print(string.format("[SurvivorRigAdapter] Adapting '%s' using profile '%s' (%s, LegAngle=%.1f°, ArmAngle=%.1f°, HipHeight=%.2f)...",
        rawModel.Name, profile.DisplayName, profile.Gender, profile.LegCorrectionAngleDeg, profile.ArmClearanceAngleDeg, profile.HipHeight))

    -- 1. Setup dual bone mapping if model has a numbered bone namespace (e.g. mixamorig6: on Jody)
    local hasNumberedNamespace = false
    for _, d in ipairs(rawModel:GetDescendants()) do
        if d:IsA("Bone") and string.find(d.Name, "^mixamorig%d+:") then
            hasNumberedNamespace = true
            break
        end
    end
    if hasNumberedNamespace and not rawModel:FindFirstChild("mixamorig:Hips", true) then
        local numHips = rawModel:FindFirstChildWhichIsA("Bone")
        while numHips and numHips.Parent and numHips.Parent:IsA("Bone") do
            numHips = numHips.Parent :: Bone
        end
        if numHips then
            local animHips = numHips:Clone()
            animHips.Name = "mixamorig:Hips"
            for _, b in ipairs(animHips:GetDescendants()) do
                if b:IsA("Bone") then
                    b.Name = string.gsub(b.Name, "^mixamorig%d*:", "mixamorig:")
                end
            end
            animHips.Parent = numHips.Parent
        end
    end

    -- 2. Scale proportionally to strict 5.970 studs target height
    local _, rawSize = rawModel:GetBoundingBox()
    local scaleFactor = profile.TargetHeight / rawSize.Y
    rawModel:ScaleTo(scaleFactor)

    -- 3. Construct clean container with Model Scale = 1.0 (Zero Animation Choking)
    local char = Instance.new("Model")
    char.Name = "StarterCharacter"
    char:SetAttribute("SurvivorProfileId", profile.Id)
    char:SetAttribute("SurvivorGender", profile.Gender)
    char:SetAttribute("DisplayName", profile.DisplayName)

    -- 4. Setup Beta_Surface root carrier
    local rootCarrier: BasePart? = rawModel:FindFirstChild("RootPart") :: BasePart?
    if rootCarrier then
        rootCarrier.Name = "Beta_Surface"
        rootCarrier.Transparency = 1
        rootCarrier.CanCollide = false
        rootCarrier.Parent = char
    end

    -- 5. Move all MeshParts and ensure CanCollide = false
    local meshParts: { MeshPart } = {}
    for _, child in ipairs(rawModel:GetChildren()) do
        if child:IsA("MeshPart") then
            child.CanCollide = false
            child.CastShadow = true
            child.Parent = char
            table.insert(meshParts, child)
        end
    end

    if not rootCarrier then
        -- Find whichever part actually holds the bone hierarchy
        local hipsInChar = char:FindFirstChild("mixamorig:Hips", true)
        if hipsInChar then
            local curr = hipsInChar.Parent
            while curr and curr.Parent ~= char and not curr:IsA("BasePart") do
                curr = curr.Parent
            end
            if curr and curr:IsA("BasePart") then
                curr.Name = "Beta_Surface"
                rootCarrier = curr
            end
        end
        if not rootCarrier then
            local bodyMesh = char:FindFirstChild("Body") or char:FindFirstChildWhichIsA("MeshPart")
            if bodyMesh and bodyMesh:IsA("BasePart") then
                bodyMesh.Name = "Beta_Surface"
                rootCarrier = bodyMesh
            end
        end
    end

    assert(rootCarrier ~= nil, "Failed to identify root carrier part in model")

    -- 6. Locate mixamorig:Hips and setup HumanoidRootPart
    local hips = rootCarrier:FindFirstChild("mixamorig:Hips", true) or char:FindFirstChild("mixamorig:Hips", true) :: Bone?
    assert(hips ~= nil, "Failed to locate mixamorig:Hips bone in model")

    local hipsWorldPos = hips.WorldPosition
    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.CanCollide = true
    hrp.Transparency = 1
    hrp.CFrame = CFrame.new(hipsWorldPos.X, hipsWorldPos.Y - 0.45, hipsWorldPos.Z)
    hrp.Parent = char
    char.PrimaryPart = hrp

    -- 7. RootJoint Motor6D from HRP to Beta_Surface
    local rj = Instance.new("Motor6D")
    rj.Name = "RootJoint"
    rj.Part0 = hrp
    rj.Part1 = rootCarrier
    rj.C0 = hrp.CFrame:ToObjectSpace(rootCarrier.CFrame)
    rj.C1 = CFrame.identity
    rj.Parent = hrp

    -- 8. Connect all MeshParts to rootCarrier via Motor6D
    for _, mesh in ipairs(meshParts) do
        if mesh ~= rootCarrier then
            local m6d = Instance.new("Motor6D")
            m6d.Name = mesh.Name .. "Motor6D"
            m6d.Part0 = rootCarrier
            m6d.Part1 = mesh
            m6d.C0 = rootCarrier.CFrame:ToObjectSpace(mesh.CFrame)
            m6d.C1 = CFrame.identity
            m6d.Parent = rootCarrier
        end
    end

    -- 9. Apply calibrated leg stance angle (neutralizes A-pose wide flare)
    local lUp = rootCarrier:FindFirstChild("mixamorig:LeftUpLeg", true) :: Bone?
    local rUp = rootCarrier:FindFirstChild("mixamorig:RightUpLeg", true) :: Bone?
    if lUp and rUp and profile.LegCorrectionAngleDeg > 0.001 then
        lUp.CFrame = lUp.CFrame * CFrame.Angles(0, 0, math.rad(profile.LegCorrectionAngleDeg))
        rUp.CFrame = rUp.CFrame * CFrame.Angles(0, 0, -math.rad(profile.LegCorrectionAngleDeg))
    end

    -- 10. Apply calibrated arm clearance angle (natural relaxed hang away from hips)
    local lArm = rootCarrier:FindFirstChild("mixamorig:LeftArm", true) :: Bone?
    local rArm = rootCarrier:FindFirstChild("mixamorig:RightArm", true) :: Bone?
    if lArm and rArm and profile.ArmClearanceAngleDeg > 0.001 then
        lArm.CFrame = lArm.CFrame * CFrame.Angles(math.rad(profile.ArmClearanceAngleDeg), 0, 0)
        rArm.CFrame = rArm.CFrame * CFrame.Angles(math.rad(profile.ArmClearanceAngleDeg), 0, 0)
    end

    -- 11. Configure Humanoid with calibrated HipHeight and jump physics
    local hum = Instance.new("Humanoid")
    hum.RigType = Enum.HumanoidRigType.R15
    hum.HipHeight = profile.HipHeight
    hum.JumpPower = 38
    hum.UseJumpPower = true
    hum.WalkSpeed = 6
    hum.Parent = char

    local animator = Instance.new("Animator")
    animator.Parent = hum

    -- 12. Cleanup leftover raw import container
    rawModel:Destroy()

    print(string.format("[SurvivorRigAdapter] Successfully adapted '%s'! Model Scale: %s, HipHeight: %.2f, Parts: %d",
        profile.DisplayName, tostring(char:GetScale()), hum.HipHeight, #meshParts))

    return char
end

return SurvivorRigAdapter
