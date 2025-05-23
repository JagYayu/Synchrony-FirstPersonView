local F3DMainCameraMode = {}
local F3DUtilities = require "F3D.system.Utilities"

local Character = require "necro.game.character.Character"
local Enum = require "system.utils.Enum"
local EnumSelector = require "system.events.EnumSelector"
local Focus = require "necro.game.character.Focus"
local OrderedSelector = require "system.events.OrderedSelector"
local Player = require "necro.game.character.Player"
local Settings = require "necro.config.Settings"
local Spectator = require "necro.game.character.Spectator"

local emptyTable = F3DUtilities.emptyTable

F3DMainCameraMode.Type = Enum.sequence {
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
	Free = Enum.entry(3, {
		free = true,
		upload = true,
	}),
}
local cameraModeData = F3DMainCameraMode.Type.data

F3DMainCameraMode.Tag_UpdateCameraMode = Settings.Tag.extend "F3D_UpdateCameraMode"

_G.SettingModeOverride = Settings.overridable.enum {
	id = "camera.mode",
	name = "Camera mode override",
	order = 108,
	default = F3DMainCameraMode.Type.None,
	enum = F3DMainCameraMode.Type,
	visibility = Settings.Visibility.HIDDEN,
	tag = F3DMainCameraMode.Tag_UpdateCameraMode,
	cheat = true,
}

event.taggedSettingChanged.add("updateCameraMode", F3DMainCameraMode.Tag_UpdateCameraMode, function()
	F3DMainCameraMode.update()
end)

local currentMode = F3DMainCameraMode.Type.None

function F3DMainCameraMode.get()
	return currentMode
end

function F3DMainCameraMode.getData(mode)
	return cameraModeData[mode or currentMode] or emptyTable
end

local updateCameraModeSelectorFire = OrderedSelector.new(event.F3D_updateCameraMode, {
	"spectator",
	"focusedEntity",
	"spectating",
	"overrides",
	"finalize",
}).fire

event.F3D_updateCameraMode.add("focusedEntity", "focusedEntity", function(ev)
	local entities = Focus.getAll(Focus.Flag.CAMERA)
	if #entities == 1 and Character.isAlive(entities[1]) then
		ev.entity = entities[1]
		ev.mode = F3DMainCameraMode.Type.FirstPerson
	else
		ev.entity = nil
	end
end)

event.F3D_updateCameraMode.add("spectating", "spectating", function(ev)
	if Spectator.isActive() then
		if Spectator.getTargetPlayerID() then
			ev.mode = F3DMainCameraMode.Type.FirstPerson
		else
			ev.mode = F3DMainCameraMode.Type.Free
		end
	else
		ev.mode = F3DMainCameraMode.Type.FirstPerson
	end
end)

event.F3D_updateCameraMode.add("overrides", "overrides", function(ev)
	if tonumber(SettingModeOverride) ~= F3DMainCameraMode.Type.None then
		ev.mode = SettingModeOverride
	end
end)

function F3DMainCameraMode.update(mode)
	local ev = {
		mode = tonumber(mode) or F3DMainCameraMode.Type.None,
	}
	updateCameraModeSelectorFire(ev)
	---	@diagnostic disable-next-line: cast-local-type
	currentMode = (tonumber(ev.mode) ~= F3DMainCameraMode.Type.None) and ev.mode or currentMode
end

event.updateVisuals.add("updateCameraMode", "hud", function()
	F3DMainCameraMode.update()
end)

local adjustCamera3DSelectorFire = EnumSelector.new(event.F3D_adjustCamera3D, F3DMainCameraMode.Type).fire

event.render.add("adjustCamera", {
	order = "camera",
	sequence = 10,
}, function()
	adjustCamera3DSelectorFire({ mode = currentMode }, currentMode)
end)

return F3DMainCameraMode
