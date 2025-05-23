local F3DEntity = require "F3D.system.Entity"
local F3DMainCamera = require "F3D.camera.Main"
local F3DMainCameraFirstPersonMode = {}
local F3DMainCameraMode = require "F3D.camera.Mode"
local F3DUtilities = require "F3D.system.Utilities"

local Action = require "necro.game.system.Action"
local AnimationTimer = require "necro.render.AnimationTimer"
local ECS = require "system.game.Entities"
local EntitySelector = require "system.events.EntitySelector"
local Focus = require "necro.game.character.Focus"
local SettingsStorage = require "necro.config.SettingsStorage"
local SizeModifier = require "necro.game.character.SizeModifier"
local SpriteEffects = require "necro.render.level.SpriteEffects"

local hoverHeight = SpriteEffects.hoverHeight
local getCameraModeData = F3DMainCameraMode.getData
local getEntityByID = ECS.getEntityByID
local tonumber = tonumber

function F3DMainCameraFirstPersonMode.isActive()
	return not not getCameraModeData().fpv
end

local isActive = F3DMainCameraFirstPersonMode.isActive

local entityGetCameraParameterSelectorFire = EntitySelector.new(event.F3D_entityGetCameraParameter, {
	"defaults",
	"cameraPosition",
	"cameraFacing",
	"statusEffects",
	"slide",
	"hover",
}).fire

event.F3D_entityGetCameraParameter.add("defaultFOV", "defaults", function(ev)
	ev.parameters.fov = (SettingsStorage.get "mod.F3D.camera.fov" or F3DMainCamera.getFOV())
end)

event.F3D_entityGetCameraParameter.add("cameraPosition", {
	filter = "F3D_position",
	order = "cameraPosition",
}, function(ev)
	local position3D = F3DEntity.getPosition(ev.entity)
	ev.parameters.x = position3D.x
	ev.parameters.y = position3D.y + ev.entity.F3D_camera.height
	ev.parameters.z = position3D.z
end)

event.F3D_entityGetCameraParameter.add("cameraUseFacingDirection", {
	filter = { "F3D_cameraUseFacingDirection", "facingDirection" },
	order = "cameraFacing",
}, function(ev)
	ev.parameters.pitch = 0
	ev.parameters.yaw = -Action.getAngle(Action.rotateDirection(ev.entity.facingDirection.direction, ev.entity.F3D_cameraUseFacingDirection.rotation))
	ev.parameters.roll = 0
end)

event.F3D_entityGetCameraParameter.add("cameraFacing", {
	filter = { "F3D_camera", "F3D_cameraFacing" },
	order = "cameraFacing",
	sequence = 1,
}, function(ev)
	ev.parameters.pitch = 0
	ev.parameters.yaw = -Action.getAngle(ev.entity.F3D_cameraFacing.direction)
	ev.parameters.roll = 0
end)

event.F3D_entityGetCameraParameter.add("cameraDwarfism", {
	filter = { "F3D_cameraDwarfism", "gigantism" },
	order = "statusEffects",
}, function(ev)
	if SizeModifier.isTiny(ev.entity) then
		ev.parameters.y = ev.parameters.y * ev.entity.F3D_cameraDwarfism.heightMultiplier
		ev.parameters.fov = ev.parameters.fov * ev.entity.F3D_cameraDwarfism.fovMultiplier
	end
end)

event.F3D_entityGetCameraParameter.add("cameraGigantism", {
	filter = { "F3D_cameraGigantism", "gigantism" },
	order = "statusEffects",
}, function(ev)
	if SizeModifier.isGigantic(ev.entity) then
		ev.parameters.y = ev.parameters.y * ev.entity.F3D_cameraGigantism.heightMultiplier
	end
end)

event.F3D_entityGetCameraParameter.add("applyRotatedSpriteAngle", {
	filter = "F3D_cameraUseRotatedSprite",
	order = "slide",
}, function(ev)
	ev.parameters.pitch = (ev.parameters.pitch or 0) - ev.entity.rotatedSprite.angle * ev.entity.F3D_cameraUseRotatedSprite.scale
end)

event.F3D_entityGetCameraParameter.add("applyHoverEffect", {
	filter = { "F3D_camera", "F3D_cameraHoverEffect", "hoverEffect" },
	order = "hover",
	sequence = 1,
}, function(ev)
	local comp = ev.entity.hoverEffect
	if comp.active then
		ev.parameters.y = ev.parameters.y - (hoverHeight(ev.entity, comp.timeStart) - comp.offset) * ev.entity.F3D_cameraHoverEffect.scale
	end
end)

local targetEntityID = 0

event.F3D_updateCameraMode.add("firstPersonMode", "finalize", function(ev)
	targetEntityID = (ev.mode == F3DMainCameraMode.Type.FirstPerson and type(ev.entity) == "table") and tonumber(ev.entity.id) or 0
end)

function F3DMainCameraFirstPersonMode.getTarget()
	return isActive() and getEntityByID(targetEntityID)
end

--- @type Entity.ID
local grabberID = 0

event.F3D_updateCameraVisibilities.add("getGrabber", {
	order = "grabber",
	sequence = 1,
}, function(ev)
	grabberID = type(ev.grabber) == "table" and tonumber(ev.grabber.id) or 0
end)

function F3DMainCameraFirstPersonMode.getGrabber()
	return isActive() and getEntityByID(grabberID)
end

function F3DMainCameraFirstPersonMode.getCameraParameters(entity)
	if entity.F3D_camera and entity.F3D_camera.active then
		local ev = {
			entity = entity,
			parameters = {},
		}
		entityGetCameraParameterSelectorFire(ev, entity.name)
		return ev.parameters
	else
		return F3DUtilities.emptyTable
	end
end

event.F3D_adjustCamera3D.add("firstPerson", F3DMainCameraMode.Type.FirstPerson, function()
	local entity = Focus.getFirst(Focus.Type.LOCAL)
	if entity then
		local params = F3DMainCameraFirstPersonMode.getCameraParameters(entity)

		local x, y, z = F3DMainCamera.getPosition()
		x = tonumber(params.x) or x
		y = tonumber(params.y) or y
		z = tonumber(params.z) or z
		F3DMainCamera.setPosition(x, y, z)

		local pitch, yaw, roll = F3DMainCamera.getRotation()
		pitch = tonumber(params.pitch) or pitch
		yaw = tonumber(params.yaw) or yaw
		roll = tonumber(params.roll) or roll
		F3DMainCamera.setRotation(pitch, yaw, roll)

		F3DMainCamera.setFOV(params.fov)
	end
end)

return F3DMainCameraFirstPersonMode
