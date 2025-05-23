local F3DMainCameraController = {}

local Action = require "necro.game.system.Action"
local CurrentLevel = require "necro.game.level.CurrentLevel"
local CustomActions = require "necro.game.data.CustomActions"
local ECS = require "system.game.Entities"
local EntitySelector = require "system.events.EntitySelector"
local GameInput = require "necro.client.Input"
local Move = require "necro.game.system.Move"
local Player = require "necro.game.character.Player"

local rotateDirection = Action.rotateDirection

event.clientAddInput.add("fpvRedirectAction", {
	order = "entity",
	sequence = 1,
}, function(ev)
	if Action.isDirection(ev.action) then
		local entity = Player.getPlayerEntity(ev.playerID)
		if entity and entity.F3D_camera and entity.F3D_camera.active then
			local direction
			if entity.F3D_cameraFacing then
				direction = entity.F3D_cameraFacing.direction
			elseif entity.F3D_cameraUseFacingDirection and entity.facingDirection then
				direction = entity.facingDirection.direction
			end

			if direction then
				ev.action = (ev.action + direction - 4) % 8 + 1
			end
		end
	end
end)

local entityRotateFacingSelectorFire = EntitySelector.new(event.F3D_entityRotateFacing, {
	"cameraFacing",
}).fire

event.F3D_entityRotateFacing.add("cameraFacing", {
	filter = "F3D_cameraFacing",
	order = "cameraFacing",
}, function(ev)
	local direction = ev.entity.F3D_cameraFacing.direction
	if Action.dx(direction) == 0 and Action.dy(direction) == 0 then
		direction = ev.entity.F3D_cameraFacing.defaultDirection
	end

	for _ = 1, ((ev.entity.F3D_cameraFacing.rotationMultiplier - 1) % 8) + 1 do
		direction = rotateDirection(direction, ev.rotation)
	end

	ev.direction = direction
	ev.entity.F3D_cameraFacing.direction = direction
end)

F3DMainCameraController.SystemAction_RotateFacing, F3DMainCameraController.systemActionRotateFacing = CustomActions.registerSystemAction {
	id = "rotateFacing",
	callback = function(playerID, args)
		local entity = Player.getPlayerEntity(playerID)
		if entity and type(args) == "table" and type(args.rotation) == "number" then
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
		return not GameInput.isBlocked() and Player.getPlayerEntity(playerID)
	end

	local function getCallback(rotation)
		return function(playerID)
			F3DMainCameraController.systemActionRotateFacing(playerID, { rotation = rotation })
		end
	end

	--- @diagnostic disable-next-line: missing-fields
	F3DMainCameraController.HotkeyFacingRotateLeft, F3DMainCameraController.hotkeyFacingRotateLeft = CustomActions.registerHotkey {
		id = "hotkeyFacingRotateLeft",
		name = "Facing rotate left",
		keyBinding = "Q",
		perPlayerBinding = true,
		callback = getCallback(Action.Rotation.CCW_45),
		enableIf = enableIf,
	}

	--- @diagnostic disable-next-line: missing-fields
	F3DMainCameraController.HotkeyFacingRotateRight, F3DMainCameraController.hotkeyFacingRotateRight = CustomActions.registerHotkey {
		id = "hotkeyFacingRotateRight",
		name = "Facing rotate right",
		keyBinding = "E",
		perPlayerBinding = true,
		callback = getCallback(Action.Rotation.CW_45),
		enableIf = enableIf,
	}
end

event.gameStateLevel.add("resetCamera", "camera", function()
	if CurrentLevel.isBoss() then
		for entity in ECS.entitiesWithComponents { "F3D_cameraFacing" } do
			entity.F3D_cameraFacing.direction = entity.F3D_cameraFacing.onBossLevel
		end
	end
end)

event.objectMove.add("cameraFacingAIControl", {
	filter = { "F3D_cameraFacing", "F3D_cameraFacingAIControl", "controllable" },
	order = "facing",
	sequence = 1,
}, function(ev)
	if ev.entity.controllable.playerID == 0 and not Move.Flag.check(ev.moveType, Move.Flag.FORCED_MOVE) then
		local direction = Action.move(ev.x - ev.prevX, ev.y - ev.prevY)
		if direction ~= Action.Direction.NONE then
			ev.entity.F3D_cameraFacing.direction = Action.rotateDirection(direction, ev.entity.F3D_cameraFacingAIControl.rotation)
		end
	end
end)

event.objectMoveResult.add("cameraFacingAIControl", {
	filter = { "F3D_cameraFacing", "F3D_cameraFacingAIControl", "controllable" },
	order = "facingLate",
	sequence = 1,
}, function(ev)
	if ev.entity.controllable.playerID == 0 and ev.entity.F3D_camera.active then
		local direction = Action.move(ev.dx, ev.dy)
		if direction ~= Action.Direction.NONE then
			ev.entity.F3D_cameraFacing.direction = Action.rotateDirection(direction, ev.entity.F3D_cameraFacingAIControl.rotation)
		end
	end
end)

return F3DMainCameraController
