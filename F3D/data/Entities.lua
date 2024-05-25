local Action = require "necro.game.system.Action"

event.entitySchemaLoadEntity.add("addCameraFacing", {
	order = "overrides",
	sequence = 10,
}, function(ev)
	if ev.entity.controllable then
		ev.entity.F3D_camera = {}
		ev.entity.F3D_cameraDwarfism = {}
		ev.entity.F3D_cameraGigantism = {}
		ev.entity.F3D_facing = {}

		local ignoreActions = ev.entity.actionFilter and ev.entity.actionFilter.ignoreActions
		if ignoreActions and (
				not ignoreActions[Action.Direction.UP_RIGHT]
				or not ignoreActions[Action.Direction.UP_LEFT]
				or not ignoreActions[Action.Direction.DOWN_LEFT]
				or not ignoreActions[Action.Direction.DOWN_RIGHT])
		then
			ev.entity.F3D_facing.rotationMultiplier = 1
		end
	end
end)

event.entitySchemaLoadEntity.add("addSprite3D", {
	order = "overrides",
	sequence = 100,
}, function(ev)
	if ev.entity.sprite and ev.entity.visibility then
		ev.entity.F3D_sprite3D = {}

		if ev.entity.wallLight then
			ev.entity.F3D_sprite3DOffset = { y = -1 }
		elseif ev.entity.item then
			ev.entity.F3D_sprite3DScale = { x = 2 / 3, y = 2 / 3 }
		elseif ev.entity.trap then
			ev.entity.F3D_sprite3DOffset = { y = .2 }
		end
	end
end)

event.entitySchemaLoadEntity.add("addLabel3D", {
	order = "overrides",
	sequence = 200,
}, function(ev)
	if ev.entity.itemStackQuantityLabelWorld
		or ev.entity.worldLabel
		or ev.entity.sale
	then
		ev.entity.F3D_label3D = {}
	end
end)

event.entitySchemaLoadNamedEntity.add("bounceTrapRight", "BounceTrapRight", function(ev)
	ev.entity.F3D_sprite3D8DirectionalVisual = {
		directions = {
			[Action.Direction.RIGHT] = { textureShiftY = 0 },
			[Action.Direction.UP_RIGHT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 32 },
			[Action.Direction.UP] = { textureShiftY = 16, mirrorX = true },
			[Action.Direction.UP_LEFT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 16 },
			[Action.Direction.LEFT] = { textureShiftY = 32 },
			[Action.Direction.DOWN_LEFT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 0 },
			[Action.Direction.DOWN] = { textureShiftY = 16 },
			[Action.Direction.DOWN_RIGHT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 48 },
		}
	}
end)

-- event.entitySchemaLoadNamedEntity.add("bounceTrapRight", "BounceTrapRight", function(ev)
-- 	ev.entity.F3D_sprite3D8DirectionalVisual = {
-- 		directions = {
-- 			[Action.Direction.RIGHT] = { textureShiftY = 0 },
-- 			[Action.Direction.UP_RIGHT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 32 },
-- 			[Action.Direction.UP] = { textureShiftY = 16, mirrorX = true },
-- 			[Action.Direction.UP_LEFT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 16 },
-- 			[Action.Direction.LEFT] = { textureShiftY = 32 },
-- 			[Action.Direction.DOWN_LEFT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 0 },
-- 			[Action.Direction.DOWN] = { textureShiftY = 16 },
-- 			[Action.Direction.DOWN_RIGHT] = { texture = "ext/traps/diagonal_bouncetrap.png", textureShiftY = 48 },
-- 		}
-- 	}
-- end)
