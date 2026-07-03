-- Universal Reanimate v3.0 - Works in EVERY Game
local pcall = pcall
local function SafeLoad()
    local Game = game
    local RunService = Game:GetService("RunService")
    local Workspace = Game:GetService("Workspace")
    local Players = Game:GetService("Players")
    local TestService = Game:GetService("TestService")
    
    local PreSim = RunService.PreSimulation
    local PostSim = RunService.PostSimulation
    local CurrentCam = Workspace.CurrentCamera
    
    local V3 = Vector3.new
    local CF = CFrame.new
    local CFAngles = CFrame.Angles
    local New = Instance.new
    
    local Player = Players.LocalPlayer
    if not Player or not Player.Character then return end
    
    local Character = Player.Character
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    
    if not Humanoid or Humanoid.Health <= 0 then return end
    if Character.Name == "GelatekReanimate" then return end
    
    local Global = (getgenv and getgenv()) or shared
    if not Global.GelatekHubConfig then Global.GelatekHubConfig = {} end
    
    local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso")
    if not RootPart then return end
    
    local R15 = Humanoid.RigType.Name == "R15"
    local Is_NetworkOwner = isnetworkowner or function(Part) return Part.ReceiveAge == 0 end
    local HiddenProps = sethiddenproperty or function() end
    
    -- Config
    local PermanentDeath = Global.GelatekHubConfig["Permanent Death"] or false
    local CollideFling = Global.GelatekHubConfig["Torso Fling"] or false
    local BulletEnabled = Global.GelatekHubConfig["Bullet Enabled"] or false
    local KeepHairWelds = Global.GelatekHubConfig["Keep Hats On Head"] or false
    local HeadlessPerma = Global.GelatekHubConfig["Headless On Perma"] or false
    local Collisions = Global.GelatekHubConfig["Enable Collisions"] or false
    local AntiVoid = Global.GelatekHubConfig["Anti Void"] or false
    
    if CollideFling and BulletEnabled then CollideFling = false end
    
    local Speed = tick()
    local FakeHats = New("Folder")
    FakeHats.Name = "FakeHats"
    FakeHats.Parent = TestService
    
    Character.Archivable = true
    pcall(function() Humanoid:ChangeState(16) end)
    
    -- Remove ragdoll constraints
    pcall(function()
        for _, v in pairs(Character:GetDescendants()) do
            if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then
                v:Destroy()
            end
        end
    end)
    
    -- Rename hats
    local HatsNames = {}
    for _, Accessory in pairs(Character:GetDescendants()) do
        if Accessory:IsA("Accessory") then
            if HatsNames[Accessory.Name] then
                if HatsNames[Accessory.Name] == "Unknown" then
                    HatsNames[Accessory.Name] = {}
                end
                table.insert(HatsNames[Accessory.Name], Accessory)
            else
                HatsNames[Accessory.Name] = "Unknown"
            end
        end
    end
    for Index, Tables in pairs(HatsNames) do
        if type(Tables) == "table" then
            local Number = 1
            for _, Names in ipairs(Tables) do
                Names.Name = Names.Name .. Number
                Number = Number + 1
            end
        end
    end
    table.clear(HatsNames)
    
    -- Create fake character
    local Figure = New("Model")
    local Limbs = {}
    local Attachments = {}
    
    local function CreateJoint(Name, Part0, Part1, C0, C1)
        local Joint = New("Motor6D")
        Joint.Name = Name
        Joint.Part0 = Part0
        Joint.Part1 = Part1
        Joint.C0 = C0
        Joint.C1 = C1
        Joint.Parent = Part0
    end
    
    for i = 0, 18 do
        local Attachment = New("Attachment")
        Attachment.Axis = V3(1, 0, 0)
        Attachment.SecondaryAxis = V3(0, 1, 0)
        table.insert(Attachments, Attachment)
    end
    
    for i = 0, 3 do
        local Limb = New("Part")
        Limb.Size = V3(1, 2, 1)
        Limb.CanCollide = false
        Limb.Parent = Figure
        table.insert(Limbs, Limb)
    end
    
    Limbs[1].Name = "Right Arm"
    Limbs[2].Name = "Left Arm"
    Limbs[3].Name = "Right Leg"
    Limbs[4].Name = "Left Leg"
    
    local Head = New("Part")
    Head.Size = V3(2, 1, 1)
    Head.Locked = true
    Head.CanCollide = false
    Head.Name = "Head"
    Head.Parent = Figure
    
    local Torso = New("Part")
    Torso.Size = V3(2, 2, 1)
    Torso.Locked = true
    Torso.CanCollide = false
    Torso.Name = "Torso"
    Torso.Parent = Figure
    
    local Root = Torso:Clone()
    Root.Transparency = 1
    Root.Name = "HumanoidRootPart"
    Root.Parent = Figure
    
    CreateJoint("Neck", Torso, Head, CF(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CF(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
    CreateJoint("RootJoint", Root, Torso, CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CF(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
    CreateJoint("Right Shoulder", Torso, Limbs[1], CF(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CF(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
    CreateJoint("Left Shoulder", Torso, Limbs[2], CF(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
    CreateJoint("Right Hip", Torso, Limbs[3], CF(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CF(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
    CreateJoint("Left Hip", Torso, Limbs[4], CF(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CF(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
    
    local FigureHumanoid = New("Humanoid")
    FigureHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    FigureHumanoid.Parent = Figure
    
    New("Animator", FigureHumanoid)
    New("HumanoidDescription", FigureHumanoid)
    
    local HeadMesh = New("SpecialMesh")
    HeadMesh.Scale = V3(1.25, 1.25, 1.25)
    HeadMesh.Parent = Head
    
    local Face = New("Decal")
    Face.Name = "face"
    Face.Texture = "http://www.roblox.com/asset/?id=158044781"
    Face.Parent = Head
    
    New("LocalScript", Figure).Name = "Animate"
    New("Script", Figure).Name = "Health"
    
    local AttachmentSetup = {
        {1, "FaceCenterAttachment", V3(0, 0, 0), Head},
        {2, "FaceFrontAttachment", V3(0, 0, -0.6), Head},
        {3, "HairAttachment", V3(0, 0.6, 0), Head},
        {4, "HatAttachment", V3(0, 0.6, 0), Head},
        {5, "RootAttachment", V3(0, 0, 0), Root},
        {6, "RightGripAttachment", V3(0, -1, 0), Limbs[1]},
        {7, "RightShoulderAttachment", V3(0, 1, 0), Limbs[1]},
        {8, "LeftGripAttachment", V3(0, -1, 0), Limbs[2]},
        {9, "LeftShoulderAttachment", V3(0, 1, 0), Limbs[2]},
        {10, "RightFootAttachment", V3(0, -1, 0), Limbs[3]},
        {11, "LeftFootAttachment", V3(0, -1, 0), Limbs[4]},
        {12, "BodyBackAttachment", V3(0, 0, 0.5), Torso},
        {13, "BodyFrontAttachment", V3(0, 0, -0.5), Torso},
        {14, "LeftCollarAttachment", V3(-1, 1, 0), Torso},
        {15, "NeckAttachment", V3(0, 1, 0), Torso},
        {16, "RightCollarAttachment", V3(1, 1, 0), Torso},
        {17, "WaistBackAttachment", V3(0, -1, 0.5), Torso},
        {18, "WaistCenterAttachment", V3(0, -1, 0), Torso},
        {19, "WaistFrontAttachment", V3(0, -1, -0.5), Torso}
    }
    
    for _, data in ipairs(AttachmentSetup) do
        Attachments[data[1]].Name = data[2]
        Attachments[data[1]].Position = data[3]
        Attachments[data[1]].Parent = data[4]
    end
    
    Figure.Name = "GelatekReanimate"
    Figure.PrimaryPart = Head
    Figure.Archivable = true
    Figure.Parent = Workspace
    Figure:MoveTo(RootPart.Position)
    
    local FigureHum = Figure:FindFirstChildWhichIsA("Humanoid")
    Figure:MoveTo(Character.Head.Position + V3(0, 2.5, 0))
    
    for _, v in pairs(Figure:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then
            v.Transparency = 1
        end
    end
    
    -- Copy accessories
    pcall(function()
        for _, v in pairs(Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.RootPriority = 127
            end
            
            if v:IsA("Motor6D") and v.Name ~= "Neck" then
                v:Destroy()
            end
            
            if v:IsA("Script") then
                v.Disabled = true
            end
            
            if v:IsA("Accessory") then
                local FakeAccessory = v:Clone()
                local Handle = FakeAccessory:FindFirstChild("Handle")
                pcall(function() Handle:FindFirstChildWhichIsA("Weld"):Destroy() end)
                
                local Weld = New("Weld")
                Weld.Name = "AccessoryWeld"
                Weld.Part0 = Handle
                
                local Attachment = Handle:FindFirstChildOfClass("Attachment")
                if Attachment then
                    Weld.C0 = Attachment.CFrame
                    Weld.C1 = Figure:FindFirstChild(tostring(Attachment), true).CFrame
                    Weld.Part1 = Figure:FindFirstChild(tostring(Attachment), true).Parent
                else
                    Weld.Part1 = Figure:FindFirstChild("Head")
                    Weld.C1 = CF(0, Figure:FindFirstChild("Head").Size.Y / 2, 0) * FakeAccessory.AttachmentPoint:Inverse()
                end
                
                Handle.CFrame = Weld.Part1.CFrame * Weld.C1 * Weld.C0:Inverse()
                Handle.Transparency = 1
                Weld.Parent = Handle
                FakeAccessory.Parent = Figure
            end
        end
    end)
    
    -- Stop animations
    pcall(function()
        for _, v in next, Humanoid:GetPlayingAnimationTracks() do
            v:Stop()
        end
    end)
    
    local FigureDescendants = Figure:GetDescendants()
    local CharacterChildren = Character:GetChildren()
    local CF0 = CF(0, 0, 0)
    local Velocity = V3(0, -26, 0)
    
    -- Align function
    local function Align(Part0, Part1, Offset)
        local CFOffset = Offset or CF0
        if Is_NetworkOwner(Part0) == true then
            Part0.AssemblyLinearVelocity = Velocity
            Part0.RotVelocity = Part1.RotVelocity
            Part0.CFrame = Part1.CFrame * CFOffset
        end
    end
    
    -- Create offsets table
    local Offsets = {}
    if not R15 then
        Offsets = {
            ["HumanoidRootPart"] = {Figure:FindFirstChild("HumanoidRootPart"), CF0},
            ["Torso"] = {Figure:FindFirstChild("Torso"), CF0},
            ["Right Arm"] = {Figure:FindFirstChild("Right Arm"), CF0},
            ["Left Arm"] = {Figure:FindFirstChild("Left Arm"), CF0},
            ["Right Leg"] = {Figure:FindFirstChild("Right Leg"), CF0},
            ["Left Leg"] = {Figure:FindFirstChild("Left Leg"), CF0},
        }
    else
        Offsets = {
            ["UpperTorso"] = {Figure:FindFirstChild("Torso"), CF(0, 0.194, 0)},
            ["LowerTorso"] = {Figure:FindFirstChild("Torso"), CF(0, -0.79, 0)},
            ["HumanoidRootPart"] = {Character:FindFirstChild("UpperTorso"), CF0},
            ["RightUpperArm"] = {Figure:FindFirstChild("Right Arm"), CF(0, 0.4085, 0)},
            ["RightLowerArm"] = {Figure:FindFirstChild("Right Arm"), CF(0, -0.184, 0)},
            ["RightHand"] = {Figure:FindFirstChild("Right Arm"), CF(0, -0.83, 0)},
            ["LeftUpperArm"] = {Figure:FindFirstChild("Left Arm"), CF(0, 0.4085, 0)},
            ["LeftLowerArm"] = {Figure:FindFirstChild("Left Arm"), CF(0, -0.184, 0)},
            ["LeftHand"] = {Figure:FindFirstChild("Left Arm"), CF(0, -0.83, 0)},
            ["RightUpperLeg"] = {Figure:FindFirstChild("Right Leg"), CF(0, 0.575, 0)},
            ["RightLowerLeg"] = {Figure:FindFirstChild("Right Leg"), CF(0, -0.199, 0)},
            ["RightFoot"] = {Figure:FindFirstChild("Right Leg"), CF(0, -0.849, 0)},
            ["LeftUpperLeg"] = {Figure:FindFirstChild("Left Leg"), CF(0, 0.575, 0)},
            ["LeftLowerLeg"] = {Figure:FindFirstChild("Left Leg"), CF(0, -0.199, 0)},
            ["LeftFoot"] = {Figure:FindFirstChild("Left Leg"), CF(0, -0.849, 0)}
        }
    end
    
    -- Connect post simulation
    PostSim:Connect(function()
        for i, v in pairs(Offsets) do
            if Character:FindFirstChild(i) then
                Align(Character:FindFirstChild(i), v[1], v[2])
            end
        end
        for _, v in pairs(CharacterChildren) do
            if v:IsA("Accessory") then
                pcall(function() Align(v.Handle, Figure[v.Name].Handle) end)
            end
        end
    end)
    
    -- Finalize
    Global.RealChar = Character
    Character.Parent = Figure
    Player.Character = Figure
    CurrentCam.CameraSubject = FigureHum
    
    -- Handle death
    FigureHum.Died:Connect(function()
        pcall(function()
            CurrentCam.FieldOfView = 70
            Character.Parent = Workspace
            Player.Character = Workspace[Character.Name]
            if Figure then Figure:Destroy() end
        end)
    end)
    
    warn("Reanimated in " .. string.sub(tostring(tick() - Speed), 1, 6) .. " seconds")
end

SafeLoad()
