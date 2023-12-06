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

local OrbClass = {}

function OrbClass.new(Icon: BillboardGui?): Types.Orb
	local Properties = {
		Position = {Vector3.new()};
		Velocity = {Vector3.new()};

		Bounces = {true};

		Parent = {nil};

		Anchored = {false};

		Target = {nil};
		TargetRange = {math.huge};
		PickupRange = {3};
		DestroyOnTargetReached = {true};

		AutoMerge = {true};
		MergeRange = {5};
		RequiredOrbsToMerge = {150};
		MergeCheckTimer = {5};
		CanMerge = {
			function()
				return true
			end;
		};

		DespawnTime = {300};

		Icon = {if Icon then Icon:Clone() else DefaultIcon:Clone()};

		DebugMode = {false};
	}

	local self = setmetatable(table.clone(OrbClass), {
		__index = function(this, Key: string)
			if Properties[Key] ~= nil then
				return Properties[Key][1]
			else
				return rawget(this, Key)
			end
		end;
		__newindex = function(this, Key: string, Value: any)
			if Properties[Key] ~= nil then
				Properties[Key] = {Value}
				this:set(Key, Value)
			else
				rawset(this, Key, Value)
			end
		end;
		__tostring = function()
			return "Orb"
		end;
	})

	-- Events

	self.Merged = Signal.new()
	self.TargetReached = Signal.new()

	-- Other

	self.SpawnClock = os.clock()

	self.Properties = Properties
	self.MotionlessClock = 0
	self.SecondsMotionless = 0
	self.MotionlessGoal = 2
	self.LastMergeCheck = 0
	self.LastPosition = Vector3.new()
	self.NotMoving = false
	self.DidMerge = false
	self.DidReachTarget = false

	self:construct()

	return self
end

-->-----------------<--
--> Private Methods <--
-->-----------------<--

function OrbClass:construct()
	rawset(self, "Janitor", Janitor.new())

	if RunService:IsServer() then
		PhysicsService:RegisterCollisionGroup("Orb")
		PhysicsService:CollisionGroupSetCollidable("Orb", "Orb", false)
	end

	self.Janitor:Add(task.delay(self.DespawnTime, self.Destroy, self), true)

	local Part: Part = PartTemplate:Clone()
	Part.Name = "Orb"
	Part.CollisionGroup = "Orb"
	CollectionService:AddTag(Part, "Orb")
	Part.Parent = self.Parent
	rawset(self, "Part", Part)

	CreatedOrbs[Part] = self

	self.Janitor:LinkToInstance(Part)
	self.Janitor:Add(Part, "Destroy")

	self.Janitor:Add(RunService.Heartbeat:Connect(function(DeltaTime: number)
		self:step(DeltaTime)
	end),"Disconnect")
end

function OrbClass:step(DeltaTime: number)
	local Part: Part = self.Part
	local AlignPosition: AlignPosition = Part:FindFirstChildWhichIsA("AlignPosition")

	self:silentSet("Position", Part.CFrame.Position)
	self:silentSet("Velocity", Part.AssemblyLinearVelocity)

	local Target: Vector3? = GetPosition(self.Target)
	Target = if Target and ((Target - self.Position).Magnitude > self.TargetRange) then nil else Target

	AlignPosition.Position = Target or Vector3.new()
	AlignPosition.Enabled = (Target ~= nil)
	-- AlignPosition.Responsiveness = 30
	Part.CanCollide = (Target == nil)

	local Icon: BillboardGui? = self.Icon
	if Icon then
		Icon.Parent = Part

		if self.DebugMode then
			Icon.Brightness = if self:shouldRender() then 1 else 0
		end
	end

	if Target and ((Target - self.Position).Magnitude < self.PickupRange) then
		if not self.DidReachTarget then
			self.TargetReached:Fire()
		end

		self.DidReachTarget = true

		if self.DestroyOnTargetReached then
			self:Destroy()
		end
	else
		self.DidReachTarget = false
	end

	if ((os.clock() - self.LastMergeCheck) >= self.MergeCheckTimer) and ((os.clock() - self.SpawnClock) >= 1.5) then
		self.LastMergeCheck = os.clock()
		self.DidMerge = false

		local Orbs = self:getOrbs()

		if #Orbs >= self.RequiredOrbsToMerge then
			self:tryToMerge()
		end
	end

	if self.LastPosition and (self.LastPosition == self.Position) then
		self.NotMoving = true

		self.SecondsMotionless = (os.clock() - self.MotionlessClock)
		if
			(self.SecondsMotionless > self.MotionlessGoal)
			and self.Bounces
			and (math.random() < 0.03)
			and (self:shouldRender())
		then
			self.Velocity = Vector3.new(0, 20, 0)
		end

		Part.Anchored = (Target == nil) and (self.Velocity.Magnitude == 0)
	else
		self.NotMoving = false
		self.MotionlessClock = os.clock()
		self.SecondsMotionless = 0
	end

	self.LastPosition = self.Position
end

function OrbClass:set(Key: string, Value: any)
	local Part: Part = self.Part

	if Key == "Position" then
		Part.Position = Value
	elseif Key == "Velocity" then
		Part.AssemblyLinearVelocity = Value
	elseif Key == "Anchored" then
		Part.Anchored = Value
	elseif Key == "Parent" then
		Part.Parent = Value
	end
end

function OrbClass:silentSet(Key: string, Value: any)
	self.Properties[Key] = {Value}
end

function OrbClass:merge(With: Types.Orb): boolean?
	if not With then return end

	self.DidMerge = true
	With.DidMerge = true

	self.Merged:Fire(With)
	With:Destroy()

	return true
end

function OrbClass:tryToMerge()
	if not self.Parent then return end
	if self.DidMerge then return end

	local Orbs = self:getOrbs()

	for _, Orb: Types.Orb in Orbs do
		if not Orb then continue end
		if Orb.DidMerge then continue end

		if (self.Position - Orb.Position).Magnitude > self.MergeRange then continue end
		-- if ((os.clock() - Orb.LastMergeCheck) < Orb.MergeCheckTimer) then continue end
		if not Orb.AutoMerge then continue end
		if not (self.CanMerge(Orb)) then continue end

		if self:merge(Orb) then break end
	end
end

function OrbClass:getOrbs(): {Types.Orb}
	local Orbs = {}

	for _, OrbPart: Part in self.Parent:GetChildren() do
		if not (OrbPart:IsA("Part")) then
			continue
		end
		if not (CollectionService:HasTag(OrbPart, "Orb")) then
			continue
		end

		if OrbPart == self.Part then
			continue
		end

		local Orb: Types.Orb = CreatedOrbs[OrbPart]
		if not Orb then
			continue
		end

		table.insert(Orbs, Orb)
	end

	return Orbs
end

function OrbClass:shouldRender()
	if RunService:IsClient() then
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

return OrbClass :: Types.OrbModule
