local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Orb = require(ReplicatedStorage.Orb)

if true then
	return
end

task.wait(5)

for i = 1, 200 do
	-- while true do
	local Coin = Orb.new()
	Coin.Parent = workspace:WaitForChild("Orbs")
	Coin.Position = Vector3.new(0, 5, 0)
	Coin.Velocity = Vector3.new(math.random(-20, 20), 50, math.random(-20, 20))
	-- Coin.Velocity = Vector3.new(10 + math.random() * 5,50,10 + math.random() * 5)
	Coin.Value = 10
	Coin.Type = "Normal"

	if (i % 2) == 1 then
		Coin.Icon = ReplicatedStorage.RainbowCoin:Clone()
		Coin.Type = "Rainbow"
	end

	-- Coin.RequiredOrbsToMerge = 1

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Active = true
	billboardGui.ClipsDescendants = true
	billboardGui.LightInfluence = 1
	billboardGui.Size = UDim2.fromOffset(200, 50)
	billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local value = Instance.new("TextLabel")
	value.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	value.Text = Coin.Value
	value.TextColor3 = Color3.fromRGB(255, 255, 255)
	value.TextSize = 30
	value.TextWrapped = true
	value.AnchorPoint = Vector2.new(0.5, 0.5)
	value.AutomaticSize = Enum.AutomaticSize.XY
	value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	value.BackgroundTransparency = 1
	value.Position = UDim2.fromScale(0.5, 0.5)
	value.Parent = billboardGui

	billboardGui.Parent = Coin.Part

	Coin.CanMerge = function(With)
		return (With.Type == Coin.Type)
	end

	Coin.Merged:Connect(function(With)
		local NewValue = (Coin.Value + With.Value)
		-- print(`{Coin.Value} + {With.Value} = {NewValue}`)

		Coin.Value = NewValue

		value.Text = NewValue
		-- Coin.Velocity += Vector3.new(0,40,0)
	end)

	Coin.TargetReached:Connect(function()
		-- print(Coin.Value)
		local Sound: Sound = SoundService.CoinCollect:Clone()
		Sound.Parent = workspace.TARGET
		Sound:Play()
		Debris:AddItem(Sound, Sound.TimeLength)

		Coin.Target:SetAttribute(Coin.Type, (Coin.Target:GetAttribute(Coin.Type) or 0) + Coin.Value)
	end)

	task.delay(0.25, function()
		Coin.TargetRange = 5
		Coin.Target = workspace.TARGET
	end)

	-- task.wait(.05)
	task.wait()
end
