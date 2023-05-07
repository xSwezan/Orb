return function(Value: Vector3 | BasePart | Attachment): Vector3
	local Type = typeof(Value)

	if Type == "Instance" then
		if Value:IsA("BasePart") then
			return Value.CFrame.Position
		elseif Value:IsA("Attachment") then
			return Value.WorldCFrame.Position
		end
	elseif Type == "Vector3" then
		return Type
	end
end
