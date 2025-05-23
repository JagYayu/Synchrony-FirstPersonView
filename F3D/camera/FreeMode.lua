local F3DMatrix = require "F3D.necro3d.Matrix"
local F3DMainCamera = require "F3D.camera.Main"
local F3DMainCameraFreeMode = {}
local F3DMainCameraMode = require "F3D.camera.Mode"
local F3DUtilities = require "F3D.system.Utilities"
local F3DVector = require "F3D.necro3d.Vector"

local Action = require "necro.game.system.Action"
local AnimationTimer = require "necro.render.AnimationTimer"
local Camera = require "necro.render.Camera"
local Config = require "necro.config.Config"
local Controls = require "necro.config.Controls"
local CustomActions = require "necro.game.data.CustomActions"
local ECS = require "system.game.Entities"
local GameInput = require "necro.client.Input"
local GameMod = require "necro.game.data.resource.GameMod"
local GFX = require "system.gfx.GFX"
local Input = require "system.game.Input"
local Move = require "necro.game.system.Move"
local MoveAnimations = require "necro.render.level.MoveAnimations"
local Player = require "necro.game.character.Player"
local Render = require "necro.render.Render"
local RenderTimestep = require "necro.render.RenderTimestep"
local Room = require "necro.client.Room"
local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local SpriteEffects = require "necro.render.level.SpriteEffects"
local Tick = require "necro.cycles.Tick"
local Turn = require "necro.cycles.Turn"
local Utilities = require "system.utils.Utilities"

local allTweenFlags = Move.Flag.mask(Move.Flag.TWEEN, Move.Flag.TWEEN_QUARTIC, Move.Flag.TWEEN_SLIDE, Move.Flag.TWEEN_MULTI_HOP)
local forwardVector = F3DVector.forward
local getCameraModeData = F3DMainCameraMode.getData
local getDeltaTime = RenderTimestep.getDeltaTime
local getTempoMultiplier = Room.getTempoMultiplier
local lerp = Utilities.lerp
local rotateDirection = Action.rotateDirection
local setPosition = F3DMainCamera.setPosition
local setRotation = F3DMainCamera.setRotation
local slideFlags = Move.Flag.mask(Move.Flag.TWEEN, Move.Flag.TWEEN_SLIDE)
local staticMatrix = F3DMatrix.static

function F3DMainCameraFreeMode.isActive()
	return getCameraModeData().free
end

local isActive = F3DMainCameraFreeMode.isActive

_G.GroupFreeCamera = Settings.overridable.group {
	id = "camera.free",
	name = "Free mode",
	order = 110,
}
_G.SettingMoveSpeed = Settings.overridable.number {
	id = "camera.free.moveSpeed",
	name = "Move speed",
	order = 111,
	default = 4,
	format = function(v)
		return (v) .. "u/s"
	end,
	sliderMinimum = 0,
	sliderMaximum = 10,
	smoothStep = .1,
	step = 1,
}
_G.SettingLookSpeed = Settings.overridable.number {
	id = "camera.free.lookSpeed",
	name = "Look speed",
	order = 112,
	default = math.rad(90),
	format = function(v)
		return (v * 180 / math.pi) .. "°/s"
	end,
	minimum = 0,
	sliderMaximum = math.rad(360),
	step = math.rad(15),
}
_G.SettingX = Settings.user.number {
	id = "camera.free.x",
	name = "X",
	order = 113.1,
	default = 0,
	editAsString = true,
}
_G.SettingY = Settings.user.number {
	id = "camera.free.y",
	name = "Y",
	order = 113.2,
	default = 0,
	editAsString = true,
}
_G.SettingZ = Settings.user.number {
	id = "camera.free.z",
	name = "Z",
	order = 113.3,
	default = 0,
	editAsString = true,
}
local function format(v)
	return v .. "°"
end
_G.SettingPitch = Settings.user.number {
	id = "camera.free.pitch",
	name = "Pitch",
	order = 113.4,
	default = 0,
	format = format,
	step = 15,
	editAsString = true,
}
_G.SettingYaw = Settings.user.number {
	id = "camera.free.yaw",
	name = "Yaw",
	order = 113.5,
	default = 0,
	format = format,
	step = 15,
	editAsString = true,
}
_G.SettingRoll = Settings.user.number {
	id = "camera.free.roll",
	name = "Roll",
	order = 113.6,
	default = 0,
	format = format,
	step = 15,
	editAsString = true,
	visibility = Settings.Visibility.HIDDEN,
}
_G.SettingApply = Settings.user.action {
	id = "camera.free.apply",
	action = function()
		if F3DMainCameraMode.get() == F3DMainCameraMode.Type.Free then
			F3DMainCamera.setPosition(_G.SettingX, _G.SettingY, _G.SettingZ)
			local f = math.pi / 180
			F3DMainCamera.setRotation(_G.SettingPitch * f, _G.SettingYaw * f, _G.SettingRoll * f)
		end
	end,
}

local function getLerpFactor(t)
	return (1 - (1 - t) ^ (getDeltaTime() * (getTempoMultiplier() or 1) * 60))
end

function F3DMainCameraFreeMode.getMoveLerpFactor()
	return getLerpFactor(F3DUtilities.getSettingSafe "mod.F3D.camera.factor")
end

function F3DMainCameraFreeMode.getRotationLerpFactor()
	return getLerpFactor(F3DUtilities.getSettingSafe "mod.F3D.camera.factorRotation")
end

local function freeCameraEnableIf()
	return not GameInput.isBlocked() and isActive()
end

if Config.osDesktop then
	local prevMouse

	F3DMainCameraFreeMode.HotKey_MouseControl = F3DUtilities.registerHotKeyDown {
		id = "mainCamera0",
		name = "Free camera mouse control",
		keyBinding = "Mouse_2",
		callback = function()
			local mouseX, mouseY = Input.mouseX(), Input.mouseY()
			if prevMouse then
				local pitch, yaw, roll = F3DMainCamera.getRotation()
				local w, h = GFX.getSize()
				local f = SettingsStorage.get "mod.F3D.camera.free.moveSpeed" / math.min(w, h)

				local prevMouseX, prevMousseY = unpack(prevMouse, 1, 2)
				setRotation(pitch + (mouseY - prevMousseY) * f, yaw - (mouseX - prevMouseX) * f, roll)
			end
			prevMouse = { mouseX, mouseY }
			return true
		end,
		enableIf = freeCameraEnableIf,
	}

	event.tick.add("clearPrevMouse", {
		order = "customHotkeys",
		sequence = 1,
	}, function()
		local key = Controls.getMiscKeyBind(F3DMainCameraFreeMode.HotKey_MouseControl)
		if Input.keyRelease(key) then
			prevMouse = nil
		end
	end)
else
	F3DMainCameraFreeMode.HotKey_MouseControl = false
end

local function lookDist()
	return SettingsStorage.get "mod.F3D.camera.free.lookSpeed" * getDeltaTime()
end
local function moveSpeed()
	return SettingsStorage.get "mod.F3D.camera.free.moveSpeed" * getDeltaTime()
end

for i, entry in ipairs {
	{
		"move forward",
		"W",
		function(x, y, z, pitch, yaw, roll)
			local dx, dy, dz = staticMatrix():reset():rotateY(yaw)(forwardVector())
			local speed = moveSpeed()
			setPosition(x + dx * speed, y + dy * speed, z + dz * speed)
		end,
	},
	{
		"move left",
		"A",
		function(x, y, z, pitch, yaw, roll)
			local dx, dy, dz = staticMatrix():reset():rotateY(yaw + math.pi / 2)(forwardVector())
			local speed = moveSpeed()
			setPosition(x + dx * speed, y + dy * speed, z + dz * speed)
		end,
	},
	{
		"move down",
		"S",
		function(x, y, z, pitch, yaw, roll)
			local dx, dy, dz = staticMatrix():reset():rotateY(yaw)(forwardVector())
			local speed = moveSpeed()
			setPosition(x - dx * speed, y - dy * speed, z - dz * speed)
		end,
	},
	{
		"move right",
		"D",
		function(x, y, z, pitch, yaw, roll)
			local dx, dy, dz = staticMatrix():reset():rotateY(yaw + math.pi / 2)(forwardVector())
			local speed = moveSpeed()
			setPosition(x - dx * speed, y - dy * speed, z - dz * speed)
		end,
	},
	{
		"move up",
		"Space",
		function(x, y, z, pitch, yaw, roll)
			setPosition(x, y + moveSpeed(), z)
		end,
	},
	{
		"move down",
		"LShift",
		function(x, y, z, pitch, yaw, roll)
			setPosition(x, y - moveSpeed(), z)
		end,
	},
	{
		"look left",
		"Q",
		function(x, y, z, pitch, yaw, roll)
			setRotation(pitch, yaw + lookDist(), roll)
		end,
	},
	{
		"look right",
		"E",
		function(x, y, z, pitch, yaw, roll)
			setRotation(pitch, yaw - lookDist(), roll)
		end,
	},
	{
		"look up",
		"R",
		function(x, y, z, pitch, yaw, roll)
			setRotation(pitch - lookDist(), yaw, roll)
		end,
	},
	{
		"look down",
		"F",
		function(x, y, z, pitch, yaw, roll)
			setRotation(pitch + lookDist(), yaw, roll)
		end,
	},
} do
	F3DUtilities.registerHotKeyDown {
		id = "mainCamera" .. i,
		name = "Free camera " .. entry[1],
		keyBinding = entry[2],
		callback = function()
			local x, y, z = F3DMainCamera.getPosition()
			local pitch, yaw, roll = F3DMainCamera.getRotation()
			entry[3](x, y, z, pitch, yaw, roll)
			return true
		end,
		enableIf = freeCameraEnableIf,
		F3D_callbackSequence = -1,
	}
end

return F3DMainCameraFreeMode
