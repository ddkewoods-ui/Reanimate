-- Universal Reanimate Script v2.0 - Works in Every Game
-- Made Compatible & Game-Independent

local Game = game
local RunService = Game:GetService("RunService")
local StartGui = Game:GetService("StarterGui")
local TestService = Game:GetService("TestService")
local Workspace = Game:GetService("Workspace")
local Players = Game:GetService("Players")
local PreSim = RunService.PreSimulation
local PostSim = RunService.PostSimulation
local CurrentCam = Workspace.CurrentCamera

local Speed = tick()
local Warn = warn
local Error = error

local Wait = task.wait
local Infinite = math.huge
local V3new = Vector3.new
local INew = Instance.new
local CFNew = CFrame.new
local CFAngles = CFrame.Angles
local MathRandom = math.random
local Insert = table.insert
local Clear = table.clear
local Type = type

local Global = (getgenv and getgenv()) or shared

if not Global.GelatekHubConfig then Global.GelatekHubConfig = {} end
local PermanentDeath = Global.GelatekHubConfig["Permanent Death"] or false
local CollideFling = Global.GelatekHubConfig["Torso Fling"] or false
local BulletEnabled = Global.GelatekHubConfig["Bullet Enabled"] or false
local KeepHairWelds = Global.GelatekHubConfig["Keep Hats On Head"] or false
local HeadlessPerma = Global.GelatekHubConfig["Headless On Perma"] or false
local DisableAnimations = Global.GelatekHubConfig["Disable Anims"] or false
local Collisions = Global.GelatekHubConfig["Enable Collisions"] or false
local AntiVoid = Global.GelatekHubConfig["Anti Void"] or false
if CollideFling and BulletEnabled then CollideFling = false end
if not Global.TableOfEvents then Global.TableOfEvents = {} end

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
if not Character then return end
if Character.Name == "GelatekReanimate" then Error("Reanimation Already Working") end

local Humanoid = Character:FindFirstChildOfClass("Humanoid")
if not Humanoid or Humanoid.Health == 0 then Error("Player Is Dead.") end

local PlayerDied = false
local IGNORETORSOCHECK = "Torso"
local Is_NetworkOwner = isnetworkowner or function(Part) return Part.ReceiveAge == 0 end
local HiddenProps = sethiddenproperty or function() end 

-- Try to find spawn point, fallback to default
local SpawnPoint = Workspace:FindFirstChildOfClass("SpawnLocation", true) or CFrame.new(0, 20, 0)
if type(SpawnPoint) ~= "userdata" then SpawnPoint = CFrame.new(0, 20, 0) end

local PostSimEvent
local PreSimEvent
local TorsoFlingEvent
local DeathEvent
local ResetEvent

local BulletInfo = nil
local HatData = nil

local CF0 = CFNew(0, 0, 0)
local Velocity = V3new(0, -26, 0)

Global.PartDisconnected = false
local RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso")
if not RootPart then return end

local R15 = Humanoid.RigType.Name == "R15" and true or false
local Sin, Cos, Inf, Clamp, Clock = math.sin, math.cos, math.huge, math.clamp, os.clock

-- Create fake hats folder
local FakeHats = INew("Folder")
FakeHats.Name = "FakeHats"
FakeHats.Parent = TestService

-- Make character archivable
Character.Archivable = true
pcall(function() Humanoid:ChangeState(16) end)

-- Remove ragdoll constraints
for _, RagdollStuff in pairs(Character:GetDescendants()) do
	if RagdollStuff:IsA("BallSocketConstraint") or RagdollStuff:IsA("HingeConstraint") then
		pcall(function() RagdollStuff:Destroy() end)
	end
end

-- Hat renaming system
local HatsNames = {}
for _, Accessory in pairs(Character:GetDescendants()) do
	if Accessory:IsA("Accessory") then
		if HatsNames[Accessory.Name] then
			if HatsNames[Accessory.Name] == "Unknown" then
				HatsNames[Accessory.Name] = {}
			end
			Insert(HatsNames[Accessory.Name], Accessory)
		else
			HatsNames[Accessory.Name] = "Unknown"
		end	
	end
end

for Index, Tables in pairs(HatsNames) do
	if Type(Tables) == "table" then
		local Number = 1
		for _, Names in ipairs(Tables) do
			Names.Name = Names.Name .. Number
			Number = Number + 1
		end		
	end
end
Clear(HatsNames)

-- Create the fake character model
local Figure = INew("Model")
do
	local Limbs = {}
	local Attachments = {}
	
	local function CreateJoint(Name, Part0, Part1, C0, C1)
		local Joint = INew("Motor6D")
		Joint.Name = Name
		Joint.Part0 = Part0
		Joint.Part1 = Part1
		Joint.C0 = C0
		Joint.C1 = C1
		Joint.Parent = Part0
	end
	
	-- Create attachments
	for i = 0, 18 do
		local Attachment = INew("Attachment")
		Attachment.Axis = V3new(1, 0, 0)
		Attachment.SecondaryAxis = V3new(0, 1, 0)
		Insert(Attachments, Attachment)
	end
	
	-- Create limbs
	for i = 0, 3 do
		local Limb = INew("Part")
		Limb.Size = V3new(1, 2, 1)
		Limb.CanCollide = false
		Limb.Parent = Figure
		Insert(Limbs, Limb)
	end
	
	Limbs[1].Name = "Right Arm"
	Limbs[2].Name = "Left Arm"
	Limbs[3].Name = "Right Leg"
	Limbs[4].Name = "Left Leg"
	
	-- Create head
	local Head = INew("Part")
	Head.Size = V3new(2, 1, 1)
	Head.Locked = true
	Head.CanCollide = false
	Head.Name = "Head"
	Head.Parent = Figure
	
	-- Create torso
	local Torso = INew("Part")
	Torso.Size = V3new(2, 2, 1)
	Torso.Locked = true
	Torso.CanCollide = false
	Torso.Name = "Torso"
	Torso.Parent = Figure
	
	-- Create root
	local Root = Torso:Clone()
	Root.Transparency = 1
	Root.Name = "HumanoidRootPart"
	Root.Parent = Figure
	
	-- Create joints
	CreateJoint("Neck", Torso, Head, CFNew(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFNew(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	CreateJoint("RootJoint", Root, Torso, CFNew(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), CFNew(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))
	CreateJoint("Right Shoulder", Torso, Limbs[1], CFNew(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFNew(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	CreateJoint("Left Shoulder", Torso, Limbs[2], CFNew(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFNew(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	CreateJoint("Right Hip", Torso, Limbs[3], CFNew(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), CFNew(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0))
	CreateJoint("Left Hip", Torso, Limbs[4], CFNew(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), CFNew(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0))
	
	-- Create humanoid
	local FigureHumanoid = INew("Humanoid")
	FigureHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	FigureHumanoid.Parent = Figure
	
	INew("Animator", FigureHumanoid)
	INew("HumanoidDescription", FigureHumanoid)
	
	-- Create head mesh and face
	local HeadMesh = INew("SpecialMesh")
	HeadMesh.Scale = V3new(1.25, 1.25, 1.25)
	HeadMesh.Parent = Head
	
	local Face = INew("Decal")
	Face.Name = "face"
	Face.Texture = "http://www.roblox.com/asset/?id=158044781"
	Face.Parent = Head
	
	INew("LocalScript", Figure).Name = "Animate"
	INew("Script", Figure).Name = "Health"
	
	-- Setup attachments
	local AttachmentData = {
		{1, "FaceCenterAttachment", V3new(0, 0, 0), Head},
		{2, "FaceFrontAttachment", V3new(0, 0, -0.6), Head},
		{3, "HairAttachment", V3new(0, 0.6, 0), Head},
		{4, "HatAttachment", V3new(0, 0.6, 0), Head},
		{5, "RootAttachment", V3new(0, 0, 0), Root},
		{6, "RightGripAttachment", V3new(0, -1, 0), Limbs[1]},
		{7, "RightShoulderAttachment", V3new(0, 1, 0), Limbs[1]},
		{8, "LeftGripAttachment", V3new(0, -1, 0), Limbs[2]},
		{9, "LeftShoulderAttachment", V3new(0, 1, 0), Limbs[2]},
		{10, "RightFootAttachment", V3new(0, -1, 0), Limbs[3]},
		{11, "LeftFootAttachment", V3new(0, -1, 0), Limbs[4]},
		{12, "BodyBackAttachment", V3new(0, 0, 0.5), Torso},
		{13, "BodyFrontAttachment", V3new(0, 0, -0.5), Torso},
		{14, "LeftCollarAttachment", V3new(-1, 1, 0), Torso},
		{15, "NeckAttachment", V3new(0, 1, 0), Torso},
		{16, "RightCollarAttachment", V3new(1, 1, 0), Torso},
		{17, "WaistBackAttachment", V3new(0, -1, 0.5), Torso},
		{18, "WaistCenterAttachment", V3new(0, -1, 0), Torso},
		{19, "WaistFrontAttachment", V3new(0, -1, -0.5), Torso}
	}
	
	for _, data in ipairs(AttachmentData) do
		Attachments[data[1]].Name = data[2]
		Attachments[data[1]].Position = data[3]
		Attachments[data[1]].Parent = data[4]
	end
	
	Figure.Name = "GelatekReanimate"
	Figure.PrimaryPart = Head
	Figure.Archivable = true
	Figure.Parent = Workspace
	Figure:MoveTo(RootPart.Position)
end

local FigureHum = Figure:FindFirstChildWhichIsA("Humanoid")
Figure:MoveTo(Character.Head.Position + V3new(0, 2.5, 0))

for _, v in pairs(Figure:GetDescendants()) do
	if v:IsA("BasePart") or v:IsA("Decal") then
		v.Transparency = 1
	end
end

local FigureDescendants = Figure:GetDescendants()
local CharacterChildren = Character:GetChildren()

-- Void event
local function VoidEvent()
	if AntiVoid == true then
		Figure:MoveTo(SpawnPoint.Position)
	else
		if PostSimEvent then PostSimEvent:Disconnect() end
		if PreSimEvent then PreSimEvent:Disconnect() end
		if DeathEvent then DeathEvent:Disconnect() end
		if TorsoFlingEvent then TorsoFlingEvent:Disconnect() end
		if ResetEvent then ResetEvent:Disconnect() end
		if FakeHats then pcall(function() FakeHats:Destroy() end) end
		
		pcall(function()
			CurrentCam.FieldOfView = 70
			Global.Stopped = true
			for _, e in pairs(Global.TableOfEvents) do 
				pcall(function() e:Disconnect() end)
			end
			Character.Parent = Workspace
			Player.Character = Workspace[Character.Name]
			pcall(function() Humanoid:ChangeState(15) end)
			if Figure then pcall(function() Figure:Destroy() end) end
			if TestService:FindFirstChild("ScriptCheck") then
				TestService:FindFirstChild("ScriptCheck"):Destroy()
			end
			Wait(0.125)
			Global.RealChar = nil
			Global.Stopped = false
		end)
	end
end

-- Disable character parts
for _, v in pairs(Character:GetDescendants()) do
	if v:IsA("BasePart") then
		v.RootPriority = 127
		local ClaimInfo = INew("SelectionBox")
		ClaimInfo.Adornee = v
		ClaimInfo.Name = "ClaimCheck"
		ClaimInfo.Transparency = 1
		ClaimInfo.Parent = v
	end
	
	if v:IsA("Motor6D") and v.Name ~= "Neck" then
		pcall(function() v:Destroy() end)
	end
	
	if v:IsA("Script") then
		v.Disabled = true
	end
	
	if v:IsA("Accessory") then
		local FakeAccessory = v:Clone()
		local Handle = FakeAccessory:FindFirstChild("Handle")
		pcall(function() Handle:FindFirstChildWhichIsA("Weld"):Destroy() end)
		
		local Weld = INew("Weld")
		Weld.Name = "AccessoryWeld"
		Weld.Part0 = Handle
		
		local Attachment = Handle:FindFirstChildOfClass("Attachment")
		if Attachment then
			Weld.C0 = Attachment.CFrame
			Weld.C1 = Figure:FindFirstChild(tostring(Attachment), true).CFrame
			Weld.Part1 = Figure:FindFirstChild(tostring(Attachment), true).Parent
		else
			Weld.Part1 = Figure:FindFirstChild("Head")
			Weld.C1 = CFNew(0, Figure:FindFirstChild("Head").Size.Y / 2, 0) * FakeAccessory.AttachmentPoint:Inverse()
		end
		
		Handle.CFrame = Weld.Part1.CFrame * Weld.C1 * Weld.C0:Inverse()
		Handle.Transparency = 1
		Weld.Parent = Handle
		FakeAccessory.Parent = Figure
		local FakeAccessory2 = FakeAccessory:Clone()
		FakeAccessory2.Parent = FakeHats
	end
end

-- Stop animations
for _, v in next, Humanoid:GetPlayingAnimationTracks() do
	v:Stop()
end

-- Bullet setup
if BulletEnabled == true then
	if R15 == false then
		if PermanentDeath == true then
			Character:FindFirstChild("HumanoidRootPart").Name = "Bullet"
			BulletInfo = {Character:FindFirstChild("Bullet"), Figure:FindFirstChild("HumanoidRootPart"), CF0}
			HatData = nil
		else
			Character:FindFirstChild("Right Leg").Name = "Bullet"
			BulletInfo = {Character:FindFirstChild("Bullet"), Figure:FindFirstChild("Right Leg"), CF0}
			if Character:FindFirstChild("Robloxclassicred") then
				HatData = {Character:FindFirstChild("Robloxclassicred"), Figure:FindFirstChild("Right Leg"), CFAngles(math.rad(90), 0, 0)}
				pcall(function() Character:FindFirstChild("Robloxclassicred").Handle:FindFirstChild("Mesh"):Destroy() end)
			else 
				HatData = nil 
			end
		end
	else
		Character:FindFirstChild("LeftUpperArm").Name = "Bullet"
		BulletInfo = {Character:FindFirstChild("Bullet"), Figure:FindFirstChild("Left Arm"), CFNew(0, 0.4085, 0)}
		if Character:FindFirstChild("SniperShoulderL") then
			HatData = {Character:FindFirstChild("SniperShoulderL"), Figure:FindFirstChild("Left Arm"), CFNew(0, 0.5, 0)}
		else 
			HatData = nil 
		end
	end
	
	if HatData then
		pcall(function() HatData[1].Handle:BreakJoints() end)
	end
	
	local Bullet = Character:FindFirstChild("Bullet")
	if Bullet then
		local Highlight = INew("SelectionBox")
		Highlight.Adornee = Bullet
		Highlight.Name = "Highlight"
		Highlight.Color3 = Color3.fromRGB(0, 223, 37)
		Highlight.Parent = Bullet
		
		local Extra = PreSim:Connect(function()
			if not Figure or not Figure.Parent then Extra:Disconnect() return end
			if (not TestService:FindFirstChild("ScriptCheck")) or Figure:FindFirstChild("AnimPlayer") then
				Highlight.Transparency = 1
			else
				Highlight.Transparency = 0
			end
		end)
	end
end

-- Torso fling setup
if CollideFling == true then
	if R15 == false then
		local Torso = Character:FindFirstChild("Torso")
		if PermanentDeath == true then
			IGNORETORSOCHECK = "adfasdkogpasdfjopghsfdjofipsdjghsfopgjospadgjsaj"
			task.spawn(function()
				Wait(1)
				local BodyAngularVelocity = INew("BodyAngularVelocity")
				BodyAngularVelocity.MaxTorque = V3new(1, 1, 1) * Infinite
				BodyAngularVelocity.P = math.huge
				BodyAngularVelocity.AngularVelocity = V3new(1950, 1950, 1950)
				BodyAngularVelocity.Name = "TorsoFlinger"
				BodyAngularVelocity.Parent = Character:FindFirstChild("HumanoidRootPart")
			end)
		else
			TorsoFlingEvent = PostSim:Connect(function()
				if FigureHum.MoveDirection.Magnitude < 0.1 then
					Torso.Velocity = Velocity
				elseif FigureHum.MoveDirection.Magnitude > 0.1 then
					Torso.Velocity = V3new(1250, 1250, 1250) + Velocity
				end
			end)
		end
	else
		local Torso = Character:FindFirstChild("UpperTorso")
		TorsoFlingEvent = PostSim:Connect(function()
			if FigureHum.MoveDirection.Magnitude < 0.1 then
				Torso.RotVelocity = V3new()
			elseif FigureHum.MoveDirection.Magnitude > 0.1 then
				Torso.RotVelocity = V3new(2500, 2500, 2500)
			end
		end)
	end
end

-- Ownership boost
if not TestService:FindFirstChild("OwnershipBoost") then
	local Part = INew("Part")
	Part.Name = "OwnershipBoost"
	Part.Parent = TestService
	PreSim:Connect(function()
		if HiddenProps then
			HiddenProps(Player, "MaximumSimulationRadius", 10e+5)
			HiddenProps(Player, "SimulationRadius", Player.MaximumSimulationRadius)
		end
	end)
end

local FallHeight = Workspace.FallenPartsDestroyHeight
local function MiniRandom() 
	return "0." .. MathRandom(6, 8) .. MathRandom(1, 9) .. MathRandom(1, 9) 
end

-- Pre-simulation
PreSimEvent = PreSim:Connect(function()
	local AntiVoidOffset = Global.GelatekHubConfig["Anti Void Offset"] or 75
	if Figure and Figure.HumanoidRootPart then
		if Figure.HumanoidRootPart.Position.Y <= FallHeight + AntiVoidOffset then 
			VoidEvent() 
		end
	end
	
	for _, v in pairs(CharacterChildren) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
	
	if not Collisions then
		for _, v in pairs(FigureDescendants) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end
end)

-- Break joints
for _, v in pairs(Character:GetDescendants()) do
	if v:IsA("Motor6D") and v.Name ~= "Neck" then
		pcall(function() v:Destroy() end)
	end
end

-- Break hat joints
for _, v in pairs(Character:GetChildren()) do
	if v:IsA("Accessory") then
		local Attachment = v.Handle:FindFirstChildWhichIsA("Attachment")
		if KeepHairWelds == true and Attachment and Attachment.Name ~= "HatAttachment" and Attachment.Name ~= "FaceFrontAttachment" and Attachment.Name ~= "HairAttachment" and Attachment.Name ~= "FaceCenterAttachment" then
			v.Handle:BreakJoints()
		end
		if KeepHairWelds == false or PermanentDeath == true then
			v.Handle:BreakJoints()
		end
	end
end

-- Align function
local function Align(Part0, Part1, Offset)
	local CFOffset = Offset or CF0
	local OwnerShip = Part0:FindFirstChild("ClaimCheck")
	if Is_NetworkOwner(Part0) == true then
		if OwnerShip then OwnerShip.Transparency = 1 end
		if (CollideFling and Part0.Name ~= IGNORETORSOCHECK) or not CollideFling then 
			Part0.AssemblyLinearVelocity = Velocity
		end
		if (CollideFling and Part0.Name ~= "HumanoidRootPart") or not CollideFling then 
			Part0.RotVelocity = Part1.RotVelocity 
		end
		Part0.CFrame = Part1.CFrame * CFOffset
	else
		if OwnerShip then OwnerShip.Transparency = 0 end
	end
end

-- Setup offsets
local Offsets
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
		["UpperTorso"] = {Figure:FindFirstChild("Torso"), CFNew(0, 0.194, 0)},
		["LowerTorso"] = {Figure:FindFirstChild("Torso"), CFNew(0, -0.79, 0)},
		["HumanoidRootPart"] = {Character:FindFirstChild("UpperTorso"), CF0},
		["RightUpperArm"] = {Figure:FindFirstChild("Right Arm"), CFNew(0, 0.4085, 0)},
		["RightLowerArm"] = {Figure:FindFirstChild("Right Arm"), CFNew(0, -0.184, 0)},
		["RightHand"] = {Figure:FindFirstChild("Right Arm"), CFNew(0, -0.83, 0)},
		["LeftUpperArm"] = {Figure:FindFirstChild("Left Arm"), CFNew(0, 0.4085, 0)},
		["LeftLowerArm"] = {Figure:FindFirstChild("Left Arm"), CFNew(0, -0.184, 0)},
		["LeftHand"] = {Figure:FindFirstChild("Left Arm"), CFNew(0, -0.83, 0)},
		["RightUpperLeg"] = {Figure:FindFirstChild("Right Leg"), CFNew(0, 0.575, 0)},
		["RightLowerLeg"] = {Figure:FindFirstChild("Right Leg"), CFNew(0, -0.199, 0)},
		["RightFoot"] = {Figure:FindFirstChild("Right Leg"), CFNew(0, -0.849, 0)},
		["LeftUpperLeg"] = {Figure:FindFirstChild("Left Leg"), CFNew(0, 0.575, 0)},
		["LeftLowerLeg"] = {Figure:FindFirstChild("Left Leg"), CFNew(0, -0.199, 0)},
		["LeftFoot"] = {Figure:FindFirstChild("Left Leg"), CFNew(0, -0.849, 0)}
	}
end

-- Post-simulation
local PostSimEvent = PostSim:Connect(function()
	for i, v in pairs(Offsets) do
		if Character:FindFirstChild(i) then
			Align(Character:FindFirstChild(i), v[1], v[2])
		end
	end
	
	for _, v in pairs(CharacterChildren) do
		if v:IsA("Accessory") then
			if (HatData and v.Name ~= HatData[1].Name) or not HatData then
				Align(v.Handle, Figure[v.Name].Handle)
			end
		end
	end
	
	if HatData then
		Align(HatData[1].Handle, HatData[2], HatData[3])
	end
	
	if BulletInfo then
		BulletInfo[1].Velocity = Velocity
		if Global.PartDisconnected == false then
			Align(BulletInfo[1], BulletInfo[2], BulletInfo[3])
		end
	end
end)

-- Permanent death
if PermanentDeath then
	task.spawn(function()
		Wait((game:FindFirstChildWhichIsA("Players") and game:FindFirstChildWhichIsA("Players").RespawnTime) or 5)
		if HeadlessPerma == true then
			pcall(function() Character:FindFirstChild("Head"):Remove() end)
		else
			pcall(function() 
				Character:FindFirstChild("Head"):BreakJoints() 
				Offsets["Head"] = {Figure:FindFirstChild("Head"), CF0}
			end)
		end
	end)
end

-- Finalize
Global.RealChar = Character	
Character.Parent = Figure
Player.Character = Figure
CurrentCam.CameraSubject = FigureHum

-- Death handling
DeathEvent = FigureHum.Died:Connect(function()
	if PostSimEvent then PostSimEvent:Disconnect() end
	if PreSimEvent then PreSimEvent:Disconnect() end
	if DeathEvent then DeathEvent:Disconnect() end
	if TorsoFlingEvent then TorsoFlingEvent:Disconnect() end
	if ResetEvent then ResetEvent:Disconnect() end
	if FakeHats then pcall(function() FakeHats:Destroy() end) end
	
	for _, e in pairs(Global.TableOfEvents) do 
		pcall(function() e:Disconnect() end)
	end
	
	pcall(function()
		CurrentCam.FieldOfView = 70
		Global.Stopped = true
		Character.Parent = Workspace
		Player.Character = Workspace[Character.Name]
		pcall(function() Humanoid:ChangeState(15) end)
		if Figure then pcall(function() Figure:Destroy() end) end
		if TestService:FindFirstChild("ScriptCheck") then
			TestService:FindFirstChild("ScriptCheck"):Destroy()
		end
		Wait(0.125)
		Global.RealChar = nil
		Global.Stopped = false
	end)
end)

-- Reset handling
ResetEvent = Character:GetPropertyChangedSignal("Parent"):Connect(function(Parent)
	if Parent == nil then
		if PostSimEvent then PostSimEvent:Disconnect() end
		if PreSimEvent then PreSimEvent:Disconnect() end
		if DeathEvent then DeathEvent:Disconnect() end
		if TorsoFlingEvent then TorsoFlingEvent:Disconnect() end
		if ResetEvent then ResetEvent:Disconnect() end
		if FakeHats then pcall(function() FakeHats:Destroy() end) end
		
		for _, e in pairs(Global.TableOfEvents) do 
			pcall(function() e:Disconnect() end)
		end
		
		pcall(function()
			if Figure then pcall(function() Figure:Destroy() end) end
			CurrentCam.FieldOfView = 70
			Global.RealChar = nil
			Global.Stopped = true
			if TestService:FindFirstChild("ScriptCheck") then 
				TestService:FindFirstChild("ScriptCheck"):Destroy() 
			end
			Wait(0.125)
			Global.Stopped = false
		end)
	end
end)

Warn("Reanimated in " .. string.sub(tostring(tick() - Speed), 1, string.find(tostring(tick() - Speed), ".") + 5) .. " seconds")

if not DisableAnimations then
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Gelatekussy/GelatekReanimate/main/Addons/Animations.lua"))()
	end)
end
