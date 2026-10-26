--!strict
-- Skeleton of the rigged Stagehand mesh (made by art/stagehand/rig_stagehand.py), rebuilt in code so the rig lives
-- in git as an asset id plus this table. Values were copied from the bones Studio's 3D importer created.
-- If the mesh is re-rigged and re-imported, copy the new bone CFrames in here.

-- { name, parent, x, y, z, rx, ry, rz }: position and CFrame.fromOrientation angles relative to the parent.
-- "Body" is the skinned MeshPart itself.
local BONES: { { any } } = {
	{ "Root", "Body", 0, -4.5, -0.412, 0, -3.14159, 0 },
	{ "Hips", "Root", 0, 3.3, 0.1, 0.04542, 0, 0 },
	{ "Spine", "Hips", 0, 1.1011, 0, -0.00378, 0, 0 },
	{ "Chest", "Spine", 0, 1.201, 0, -0.13512, 0, 0 },
	{ "Neck", "Chest", 0, 1.607, 0, 0.19315, 0, 0 },
	{ "Head", "Neck", 0, 0.5025, 0, -1.55427, 3.14159, 3.14159 },
	{ "UpperArm.L", "Chest", -1, 0.7561, -0.0296, 0.16123, -2.91355, -2.93087 },
	{ "LowerArm.L", "UpperArm.L", 0, 1.4857, 0, 0.72847, -0.10642, -0.13697 },
	{ "Hand.L", "LowerArm.L", 0, 1.4229, 0, -0.29979, 0.13538, -0.13332 },
	{ "UpperArm.R", "Chest", 1, 0.7561, -0.0296, 0.16123, 2.91355, 2.93087 },
	{ "LowerArm.R", "UpperArm.R", 0, 1.4857, 0, 0.72847, 0.10642, 0.13697 },
	{ "Hand.R", "LowerArm.R", 0, 1.4229, 0, -0.29979, -0.13538, 0.13332 },
	{ "UpperLeg.L", "Hips", -0.5, 0.0018, 0.04, -0.19549, -3.04506, -3.03958 },
	{ "LowerLeg.L", "UpperLeg.L", 0, 1.5002, 0, -0.50669, 0.16251, -0.13766 },
	{ "Foot.L", "LowerLeg.L", 0, 1.3008, 0, 1.44975, -0.02926, -0.01168 },
	{ "UpperLeg.R", "Hips", 0.5, 0.0018, 0.04, -0.19549, 3.04506, 3.03958 },
	{ "LowerLeg.R", "UpperLeg.R", 0, 1.5002, 0, -0.50669, -0.16251, 0.13766 },
	{ "Foot.R", "LowerLeg.R", 0, 1.3008, 0, 1.44975, 0.02926, 0.01168 },
}

local StagehandRig = {}

function StagehandRig.addBones(body: MeshPart)
	local byName: { [string]: Instance } = { Body = body }
	for _, data in BONES do
		local bone = Instance.new("Bone")
		bone.Name = data[1]
		bone.CFrame = CFrame.new(data[3], data[4], data[5]) * CFrame.fromOrientation(data[6], data[7], data[8])
		bone.Parent = byName[data[2]]
		byName[data[1]] = bone
	end
end

return StagehandRig
