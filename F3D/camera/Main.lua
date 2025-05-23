local F3DCamera = require "F3D.necro3d.Camera"
local F3DMainCamera = {}
local F3DRender = require "F3D.render.Render"
local F3DUtilities = require "F3D.system.Utilities"

local Enum = require "system.utils.Enum"
local Focus = require "necro.game.character.Focus"
local RenderTimestep = require "necro.render.RenderTimestep"
local Room = require "necro.client.Room"
local Settings = require "necro.config.Settings"
local Utilities = require "system.utils.Utilities"

local CFX = F3DCamera.Field.X
local CFZ = F3DCamera.Field.Z
local getTileAtWorld = F3DRender.getTileAt
local lerp = Utilities.lerp
local pi = math.pi

F3DMainCamera.Mode = Enum.sequence {
	None = Enum.entry(0, {
		suppressOverrides = true,
		disable = true,
	}),
	Disable = Enum.entry(1, {
		disable = true,
	}),
	FirstPerson = Enum.entry(2, {
		fpv = true,
	}),
	Free = Enum.entry(4, {
		free = true,
		upload = true,
	}),
}

local camera = F3DCamera.new()
local destX = 0
local destY = 0
local destZ = 0
local destPitch = 0
local destYaw = 0
local destRoll = 0
local destFOV = math.rad(90)

local snapNextFrame = 0

_G.GroupCamera = Settings.overridable.group {
	id = "camera",
	name = "Camera",
	order = 100,
}
_G.SettingPositionAdjustFactor = Settings.overridable.percent {
	id = "camera.factor",
	name = "Position adjust factor",
	order = 101,
	default = .9,
	sliderMinimum = .5,
}
_G.SettingRotationAdjustFactor = Settings.overridable.percent {
	id = "camera.factorRotation",
	name = "Rotation adjust factor",
	order = 102,
	default = .8,
	sliderMinimum = .5,
}
_G.SettingFOV = Settings.overridable.number {
	id = "camera.fov",
	name = "Field of View",
	order = 103,
	default = math.rad(90),
	format = function(v)
		return (v * 180 / pi) .. "°"
	end,
	sliderMinimum = math.rad(30),
	sliderMaximum = math.rad(150),
	step = math.rad(15),
	smoothStep = math.rad(1),
}
_G.SettingNear = Settings.overridable.number {
	id = "camera.near",
	name = "Near plane",
	order = 104,
	default = 1e-3,
	format = function(v)
		return v .. "m"
	end,
	editAsString = true,
	visibility = Settings.Visibility.HIDDEN,
}
_G.SettingFar = Settings.overridable.number {
	id = "camera.far",
	name = "Far plane",
	order = 105,
	default = 1e3,
	format = function(v)
		return v .. "m"
	end,
	editAsString = true,
	visibility = Settings.Visibility.HIDDEN,
}

function F3DMainCamera.getCurrent()
	return camera
end

--- @return integer tx
--- @return integer ty
function F3DMainCamera.getCurrentTilePosition()
	return getTileAtWorld(camera[CFX], camera[CFZ])
end

--- Get camera destined position.
--- Use `F3DMainCamera.camera:getPosition()` to get real position of current frame.
--- @return integer
--- @return integer
--- @return integer
function F3DMainCamera.getPosition()
	return destX, destY, destZ
end

--- Get camera destined rotation.
--- Use `F3DMainCamera.camera:getPosition()` to get real position of current frame.
function F3DMainCamera.getRotation()
	return destPitch, destYaw, destRoll
end

function F3DMainCamera.getFOV()
	return destFOV
end

function F3DMainCamera.snap(frames)
	snapNextFrame = tonumber(frames) or 1
end

function F3DMainCamera.setPosition(x, y, z)
	destX = tonumber(x) or destX
	destY = tonumber(y) or destY
	destZ = tonumber(z) or destZ
end

function F3DMainCamera.setRotation(pitch, yaw, roll)
	destPitch = tonumber(pitch) or destPitch
	destYaw = tonumber(yaw) or destYaw
	destRoll = tonumber(roll) or destRoll
end

function F3DMainCamera.setFOV(fov)
	destFOV = tonumber(fov) or SettingFOV
end

local function getLerpFactor(t)
	t = 1 - (1 - t) ^ 8.1278098
	return 1 - (1 - t) ^ (RenderTimestep.getDeltaTime() * (Room.getTempoMultiplier() or 1))
end

local function notSlerp(a1, a2, t)
	local c1 = math.cos(a1)
	local s1 = math.sin(a1)
	local c2 = math.cos(a2)
	local s2 = math.sin(a2)
	local x = lerp(c1, c2, t)
	local y = lerp(s1, s2, t)
	return math.atan2(y, x)
end

event.render.add("updateCamera", {
	order = "camera",
	sequence = 100,
}, function()
	local x, y, z = camera:getPosition()
	local pitch, yaw, roll = camera:getRotation()
	local fov = camera:getFov()
	local defaultFactor = getLerpFactor(.75)

	if snapNextFrame > 0 then
		x = destX
		y = destY
		z = destZ
		pitch = destPitch
		yaw = destYaw
		roll = destRoll
		fov = destFOV

		snapNextFrame = snapNextFrame - 1
	else
		if SettingPositionAdjustFactor < 1 then
			local factor = getLerpFactor(SettingPositionAdjustFactor)
			x = lerp(x, destX, factor)
			y = lerp(y, destY, factor)
			z = lerp(z, destZ, factor)
		else
			x = destX
			y = destY
			z = destZ
		end

		if SettingRotationAdjustFactor < 1 then
			destPitch = (destPitch - pitch) % (pi) > pi and pitch - pi or destPitch
			destYaw = (destYaw - yaw) % (pi) > pi and yaw - pi or destYaw
			destRoll = (destRoll - roll) % (pi) > pi and roll - pi or destRoll

			-- TODO use Quaternion
			local factor = getLerpFactor(SettingRotationAdjustFactor)
			pitch = notSlerp(pitch, destPitch, factor)
			yaw = notSlerp(yaw, destYaw, factor)
			roll = notSlerp(roll, destRoll, factor)
		else
			pitch = destPitch
			yaw = destYaw
			roll = destRoll
		end

		fov = lerp(fov, destFOV, defaultFactor)
	end

	camera:setPosition(x, y, z)
	camera:setRotation(pitch, yaw, roll)
	camera:setFov(fov)
	camera:setNear(lerp(camera:getNear(), SettingNear, defaultFactor))
	camera:setFar(lerp(camera:getFar(), SettingFar, defaultFactor))
end)

event.focusedEntityTeleport.add("snapCamera", "snapCamera", function(ev)
	if Focus.check(ev.entity, Focus.Flag.CAMERA) then
		snapNextFrame = 2
	end
end)

event.gameStateLevel.add("snapCamera", "cameraSnap", function()
	snapNextFrame = 1
end)

---@diagnostic disable-next-line: redefined-local, unused-local
camera, destX, destY, destZ, destPitch, destYaw, destRoll, destFOV = script.persist(function()
	return camera, destX, destY, destZ, destPitch, destYaw, destRoll, destFOV
end)

return F3DMainCamera
