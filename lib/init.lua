local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local DefaultIcon = require(script.DefaultIcon)
local GetPosition = require(script.Util.GetPosition)
local Janitor = require(script.Parent.Janitor)
local PartTemplate: Part = require(script.Part)
local Signal = require(script.Parent.Signal)
local Types = require(script.Types)

local Camera: Camera = workspace.CurrentCamera

local CreatedOrbs: {[Part]: Types.Orb} = {}

if (RunService:IsServer()) then
	PhysicsService:RegisterCollisionGroup("Orb")
	PhysicsService:CollisionGroupSetCollidable("Orb", "Orb", false)
end

local OrbClass = {}

function OrbClass.new(): Types.Orb
	local self = setmetatable(table.clone(OrbClass), {
		-- __index = function(this, Key: string)
		-- 	if Properties[Key] ~= nil then
		-- 		return Properties[Key][1]
		-- 	else
		-- 		return rawget(this, Key)
		-- 	end
		-- end;
		-- __newindex = function(this, Key: string, Value: any)
		-- 	if Properties[Key] ~= nil then
		-- 		Properties[Key] = {Value}
		-- 		this:set(Key, Value)
		-- 	else
		-- 		rawset(this, Key, Value)
		-- 	end
		-- end;
		__tostring = function()
			return "Orb"
		end;

		--> Properties
		Position = Vector3.new();
		Velocity = Vector3.new();

		Bounces = true;

		Parent = nil;

		Anchored = false;

		Target = nil;
		TargetRange = math.huge;
		PickupRange = 3;
		DestroyOnTargetReached = true;

		AutoMerge = true;
		MergeRange = 5;
		RequiredOrbsToMerge = 150;
		MergeCheckTimer = 5;
		CanMerge = function()
			return true
		end;

		DespawnTime = 300;

		DebugMode = false;
	})

	-- Events

	self.Merged = Signal.new()
	self.TargetReached = Signal.new()

	-- Other

	self.SpawnClock = os.clock()

	self.motionlessClock = 0
	self.secondsMotionless = 0
	self.motionlessGoal = 2
	self.lastMergeCheck = 0
	self.lastPosition = Vector3.new()
	self.isMoving = false
	self.didMerge = false
	self.didReachTarget = false

	self:construct()

	return self
end

-->-----------------<--
--> Private Methods <--
-->-----------------<--

function OrbClass:construct()
	self.Janitor = Janitor.new()

	self.Janitor:Add(task.delay(self.DespawnTime, self.Destroy, self), true)

	local Part: Part = PartTemplate:Clone()
	Part.Name = "Orb"
	Part.CollisionGroup = "Orb"
	Part:AddTag("Orb")
	Part.Parent = self.Parent
	self.Part = Part

	CreatedOrbs[Part] = self

	self.Janitor:LinkToInstance(Part)
	self.Janitor:Add(Part, "Destroy")
end

function OrbClass:step(DeltaTime: number)
	local Part: Part = self.Part

	Part.Position = self.Position
	Part.AssemblyLinearVelocity = self.Velocity
	Part.Anchored = (self.Anchored == true)
	Part.Parent = self.Parent

	self.Position = Part.CFrame.Position
	self.Velocity = Part.AssemblyLinearVelocity

	local Target: Vector3? = GetPosition(self.Target)
	local DistanceToTarget: number = if (Target) then (Target - self.Position).Magnitude else 0
	Target = if (Target) and (DistanceToTarget > self.TargetRange) then nil else Target

	local AlignPosition: AlignPosition = Part:FindFirstChildWhichIsA("AlignPosition")
	AlignPosition.Position = Target or Vector3.new()
	AlignPosition.Enabled = (Target ~= nil)
	-- AlignPosition.Responsiveness = 30

	Part.CanCollide = (Target == nil)

	if (Target) and (DistanceToTarget < self.PickupRange) then
		if not (self.didReachTarget) then
			self.TargetReached:Fire()
		end

		self.didReachTarget = true

		if (self.DestroyOnTargetReached) then
			self:Destroy()
		end
	else
		self.didReachTarget = false
	end

	if ((os.clock() - self.LastMergeCheck) >= self.MergeCheckTimer) and ((os.clock() - self.SpawnClock) >= 1.5) then
		self.LastMergeCheck = os.clock()
		self.didMerge = false

		local Orbs = self:getOrbs()

		if #Orbs >= self.RequiredOrbsToMerge then
			self:tryToMerge()
		end
	end

	if (self.LastPosition) and (self.LastPosition == self.Position) then
		self.isMoving = false

		self.secondsMotionless = (os.clock() - self.motionlessClock)
		if
			(self.secondsMotionless > self.motionlessGoal) and
			(self.Bounces) and
			(math.random() < .03) and
			(self:shouldRender())
		then
			self.Velocity = Vector3.new(0, 20, 0) -- Bounce
		end

		Part.Anchored = (Target == nil) and (self.Velocity.Magnitude == 0)
	else
		self.isMoving = true
		self.motionlessClock = os.clock()
		self.secondsMotionless = 0
	end

	self.LastPosition = self.Position
end

function OrbClass:set(Key: string, Value: any)
	local Part: Part = self.Part

	if (Key == "Position") then
		Part.Position = Value
	elseif (Key == "Velocity") then
		Part.AssemblyLinearVelocity = Value
	elseif (Key == "Anchored") then
		Part.Anchored = Value
	elseif (Key == "Parent") then
		Part.Parent = Value
	end
end

function OrbClass:merge(With: Types.Orb): boolean?
	if not With then return end

	self.didMerge = true
	With.didMerge = true

	self.Merged:Fire(With)
	With:Destroy()

	return true
end

function OrbClass:tryToMerge()
	if not self.Parent then return end
	if self.didMerge then return end

	local Orbs = self:getOrbs()

	for _, Orb: Types.Orb in Orbs do
		if not (Orb) then continue end
		if (Orb.DidMerge) then continue end

		if (self.Position - Orb.Position).Magnitude > self.MergeRange then continue end
		-- if ((os.clock() - Orb.LastMergeCheck) < Orb.MergeCheckTimer) then continue end
		if not (Orb.AutoMerge) then continue end
		if not (self.CanMerge(Orb)) then continue end

		if (self:merge(Orb)) then break end
	end
end

function OrbClass:getOrbs(): {Types.Orb}
	local Orbs = {}

	for _, OrbPart: Part in self.Parent:GetChildren() do
		if not (OrbPart:IsA("Part")) then continue end
		if not (OrbPart:HasTag("Orb")) then continue end

		if (OrbPart == self.Part) then continue end

		local Orb: Types.Orb = CreatedOrbs[OrbPart]
		if not (Orb) then continue end

		table.insert(Orbs, Orb)
	end

	return Orbs
end

function OrbClass:shouldRender(): boolean
	if (RunService:IsClient()) then
		local DistanceToCamera: number = (self.Position - Camera.CFrame.Position).Magnitude
		local _, OnScreen: boolean = Camera:WorldToScreenPoint(self.Position)

		return (OnScreen == true) and (DistanceToCamera <= 128)
	end

	return true
end

-->---------<--
--> Methods <--
-->---------<--

function OrbClass:Destroy()
	CreatedOrbs[self.Part] = nil
	self.Janitor:Destroy()
	self = nil
end

RunService.Heartbeat:Connect(function(DeltaTime: number)
	for Part: Part, Orb: Types.Orb in CreatedOrbs do
		Orb:step(DeltaTime)
	end
end)

return OrbClass :: Types.OrbModule
