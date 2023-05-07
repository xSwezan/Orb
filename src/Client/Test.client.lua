local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Orb = require(ReplicatedStorage.Orb)

local Player = Players.LocalPlayer
local Character = Player.CharacterAdded:Wait()

local TARGET = Character:WaitForChild("HumanoidRootPart")

task.wait(5)

-- for i = 1,25 do
while true do
	local Coin = Orb.new()
	Coin.Parent = workspace:WaitForChild("Orbs")
	Coin.Position = Vector3.new(0, 5, 0)
	Coin.Velocity = Vector3.new(math.random(-20, 20), 50, math.random(-20, 20))
	Coin.Value = 10
	-- Coin.RequiredOrbsToMerge = math.huge

	local Time = 0.25

	task.delay(Time, function()
		-- Coin.CanMerge = function(With)
		-- 	return true
		-- end

		Coin.Merged:Connect(function(With)
			Coin.Value += With.Value
			-- Coin.Velocity += Vector3.new(0,40,0)
		end)

		Coin.TargetReached:Connect(function()
			Player:SetAttribute("Coins", (Player:GetAttribute("Coins") or 0) + Coin.Value)
		end)

		Coin.TargetRange = 10
		Coin.Target = TARGET
	end)

	task.wait()
end
