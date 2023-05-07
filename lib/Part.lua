local orb = Instance.new("Part")
orb.Size = Vector3.new(0.5, 0.5, 0.5)
orb.Transparency = 1

local root = Instance.new("Attachment")
root.Parent = orb

local alignPosition = Instance.new("AlignPosition")
alignPosition.Enabled = false
alignPosition.MaxForce = 1e+05
alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
alignPosition.Position = Vector3.new(3.5, 0.426, 21.1)
alignPosition.Responsiveness = 30
alignPosition.Parent = orb
alignPosition.Attachment0 = root

return orb
