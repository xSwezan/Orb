local icon = Instance.new("BillboardGui")
icon.Active = true
icon.ClipsDescendants = true
icon.MaxDistance = 500
icon.Size = UDim2.fromScale(2, 2)
icon.StudsOffset = Vector3.new(0, 1, 0)
icon.ResetOnSpawn = false

local imageLabel = Instance.new("ImageLabel")
imageLabel.Image = "rbxassetid://13050262392"
imageLabel.ScaleType = Enum.ScaleType.Fit
imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
imageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
imageLabel.BackgroundTransparency = 1
imageLabel.BorderSizePixel = 0
imageLabel.Position = UDim2.fromScale(0.5, 0.5)
imageLabel.Size = UDim2.fromScale(0.45, 0.45)
imageLabel.ZIndex = 2
imageLabel.Parent = icon

local imageLabel1 = Instance.new("ImageLabel")
imageLabel1.Image = "rbxassetid://13362036343"
imageLabel1.ScaleType = Enum.ScaleType.Fit
imageLabel1.AnchorPoint = Vector2.new(0.5, 0.5)
imageLabel1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
imageLabel1.BackgroundTransparency = 1
imageLabel1.BorderSizePixel = 0
imageLabel1.Position = UDim2.fromScale(0.5, 0.5)
imageLabel1.Size = UDim2.fromScale(1, 1)
imageLabel1.Parent = icon

return icon
