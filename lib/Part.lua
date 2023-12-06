local Orb = Instance.new("Part")
Orb.Size = Vector3.new(.5, .5, .5)
Orb.Transparency = 1
Orb.CollisionGroup = "Orb"

local Root = Instance.new("Attachment")
Root.Parent = Orb

local AlignPosition = Instance.new("AlignPosition")
AlignPosition.Enabled = false
AlignPosition.MaxForce = 1e+05
AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
AlignPosition.Position = Vector3.new(3.5, .426, 21.1)
AlignPosition.Responsiveness = 30
AlignPosition.Parent = Orb
AlignPosition.Attachment0 = Root

return Orb
