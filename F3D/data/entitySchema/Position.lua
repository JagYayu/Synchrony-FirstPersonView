event.entitySchemaLoadEntity.add("positionOffsetsIfInsideWall", "overrides", function(ev)
	if ev.entity.spriteOffsetYIfInsideWall then
		ev.entity.F3D_positionOffsetsIfInsideWall = {}
	end
end)

local function spriteOffsetY(n, v)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		ev.entity.F3D_positionOffsets = ev.entity.F3D_positionOffsets or {}
		ev.entity.F3D_positionOffsets.y = (tonumber(ev.entity.F3D_positionOffsets.y) or 0) + v
	end)
end

spriteOffsetY("Fortissimole", 1)
spriteOffsetY("Gargoyle7", 1)
spriteOffsetY("MummyDancer", 1)
spriteOffsetY("Necrodancer", 1)
spriteOffsetY("SkeletonDancer", 1)
spriteOffsetY("Skeleton2Dancer", 1)
spriteOffsetY("Skeleton3Dancer", 1)
spriteOffsetY("TrapFireDecoration", 1)
spriteOffsetY("WallLightBulb", 1)
spriteOffsetY("WallMushroomLight", 1)
spriteOffsetY("WallTorch", 1)

local function spriteOffsets(n, x, y, z)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		ev.entity.F3D_positionOffsets = ev.entity.F3D_positionOffsets or {}
		ev.entity.F3D_positionOffsets.x = (tonumber(ev.entity.F3D_positionOffsets.x) or 0) + x
		ev.entity.F3D_positionOffsets.y = (tonumber(ev.entity.F3D_positionOffsets.y) or 0) + y
		ev.entity.F3D_positionOffsets.z = (tonumber(ev.entity.F3D_positionOffsets.z) or 0) + z
	end)
end
spriteOffsets("Frankensteinway", .5, 0, -.5)
spriteOffsets("LuteDragon", 1, 0, -1)

event.entitySchemaLoadNamedEntity.add(nil, "WeaponGoldenLute", function(ev)
	ev.entity.F3D_positionOffsetsIfInsideWall = {}
end)
