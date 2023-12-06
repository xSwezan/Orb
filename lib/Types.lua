local Signal = require(script.Parent.Parent.Signal)

local Types = {}

export type OrbModule = {
	new: (Icon: BillboardGui?) -> Orb,
}

export type Orb = {
	Position: Vector3,
	Velocity: Vector3,

	Bounces: boolean,

	Parent: Instance?,

	Anchored: boolean,

	Target: Vector3 | BasePart | Attachment | Player?,
	TargetRange: number,
	DestroyOnTargetReached: boolean,

	AutoMerge: boolean, -- If it should merge
	MergeRange: number, -- The range of the merging
	RequiredOrbsToMerge: number, -- How many orbs are required for it to try merging
	MergeCheckTimer: number, -- How often it tries to merge
	CanMerge: (With: Orb) -> boolean, -- Return true if Orbs can merge together

	Part: Part,

	DespawnTime: number, -- The amount of time (in seconds) until it gets destroyed

	Icon: BillboardGui?,

	DebugMode: boolean?,

	-- Events

	Merged: Signal.Signal, -- Fired before a merge is finished
	TargetReached: Signal.Signal, -- Fired when Orb is at Target
}

return Types
