local F3DCharacter = {}

local Action = require "necro.game.system.Action"
local Collision = require "necro.game.tile.Collision"
local CustomActions = require "necro.game.data.CustomActions"
local EntitySelector = require "system.events.EntitySelector"
local Input = require "necro.client.Input"
local Move = require "necro.game.system.Move"
local Player = require "necro.game.character.Player"
local Settings = require "necro.config.Settings"

local rotateDirection = Action.rotateDirection

local entityRotateFacingSelectorFire = EntitySelector.new(event.F3D_entityRotateFacing, {
	"facing",
	"camera",
}).fire

event.F3D_entityRotateFacing.add("cameraFacing", {
	filter = "F3D_facing",
	order = "facing",
}, function(ev)
	local direction = ev.direction
	if not direction then
		direction = ev.entity.F3D_facing.direction
		for _ = 1, ev.entity.F3D_facing.rotationMultiplier do
			direction = rotateDirection(direction, ev.rotation)
		end
	end
	ev.direction = direction
	ev.entity.F3D_facing.direction = direction
end)

F3DCharacter.SystemActionRotateFacing, F3DCharacter.systemActionRotateFacing = CustomActions.registerSystemAction {
	id = "rotateFacing",
	callback = function(playerID, args)
		local entity = Player.getPlayerEntity(playerID)
		if entity and type(args) == "table" and type(args.rotation) then
			--- @class Event.F3D_entityRotateFacing
			--- @field entity Entity
			--- @field rotation Action.Rotation
			--- @field direction Action.Direction
			local ev = {
				entity = entity,
				rotation = args.rotation,
			}

			entityRotateFacingSelectorFire(ev, entity.name)
		end
	end,
}

do
	local function enableIf(playerID)
		return not Input.isBlocked() and Player.getPlayerEntity(playerID)
	end

	local function rotateCallback(rotation)
		return function(playerID)
			F3DCharacter.systemActionRotateFacing(playerID, { rotation = rotation })
		end
	end

	--- @diagnostic disable-next-line: missing-fields
	F3DCharacter.HotkeyFacingRotateLeft, F3DCharacter.hotkeyFacingRotateLeft = CustomActions.registerHotkey {
		id = "hotkeyFacingRotateLeft",
		name = "Facing rotate left",
		keyBinding = "Q",
		perPlayerBinding = true,
		callback = rotateCallback(Action.Rotation.CCW_45),
		enableIf = enableIf,
	}

	--- @diagnostic disable-next-line: missing-fields
	F3DCharacter.HotkeyFacingRotateRight, F3DCharacter.hotkeyFacingRotateRight = CustomActions.registerHotkey {
		id = "hotkeyFacingRotateRight",
		name = "Facing rotate right",
		keyBinding = "E",
		perPlayerBinding = true,
		callback = rotateCallback(Action.Rotation.CW_45),
		enableIf = enableIf,
	}
end

event.F3D_getListenerSoundRelativePosition.add("cameraFacingRotate", {
	filter = "F3D_facing",
	order = "rotate",
}, function(ev)
	ev.dx, ev.dy = Action.rotate(ev.dx, ev.dy, (3 - ev.entity.F3D_facing.direction) % 8 + 1)
end)

event.objectF3D_adjustCamera.add("cameraFacingAngle", {
	filter = "F3D_facing",
	order = "direction",
}, function(ev)
	ev.angle = Action.getAngle(ev.entity.F3D_facing.direction)
end)

event.objectCheckAbility.add("applyFacingRemap", {
	filter = "F3D_facing",
	order = "speculate",
}, function(ev)
	if ev.client and Action.isDirection(ev.action) then
		ev.action = (ev.action + ev.entity.F3D_facing.direction - 4) % 8 + 1
	end
end)

return F3DCharacter
