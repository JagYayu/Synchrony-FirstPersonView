local F3DEntity = require "F3D.system.Entity"
local F3DMainCamera = require "F3D.camera.Main"
local F3DMatrix = require "F3D.necro3d.Matrix"
local F3DSound = {}
local F3DVector = require "F3D.necro3d.Vector"

local Action = require "necro.game.system.Action"
local Audio = require "system.game.Audio"
local EntitySelector = require "system.events.EntitySelector"
local Enum = require "system.utils.Enum"
local EnumSelector = require "system.events.EnumSelector"
local Focus = require "necro.game.character.Focus"
local GameState = require "necro.client.GameState"
local Music = require "necro.audio.Music"
local Segment = require "necro.game.tile.Segment"
local Settings = require "necro.config.Settings"
local Sound = require "necro.audio.Sound"
local SoundGroups = require "necro.audio.SoundGroups"
local Utilities = require "system.utils.Utilities"

local camera = F3DMainCamera.getCurrent()
local inf = math.huge
local length3 = F3DVector.magnitude
local getPosition3D = F3DEntity.getPosition
local min = math.min
local staticMatrix = F3DMatrix.static()

do
	local presentSession, Session = pcall(require, "system.game.Session")
	if presentSession and Session.isDuplicate() then
		F3DSound.PortFilter = Sound.Port.PERSONAL
	else
		F3DSound.PortFilter = false
	end
end

F3DSound.Option = Enum.immutable {
	_2D = 0,
	_3D = 1,
	Both = 2,
}

_G.SettingGroupAudio = Settings.overridable.group {
	id = "audio",
	name = "Sound",
	order = 600,
	visibility = Settings.Visibility.HIDDEN,
}
_G.SettingAudioOption = Settings.overridable.choice {
	id = "audio.option",
	name = "Option",
	order = 1,
	choices = {
		{ name = "2D",    value = F3DSound.Option._2D },
		{ name = "3D",    value = F3DSound.Option._3D },
		{ name = "2D&3D", value = F3DSound.Option.Both },
	},
	default = F3DSound.Option._3D,
}
_G.SettingSoundDefaultZ = Settings.overridable.number {
	id = "audio.z",
	name = "Default z",
	order = 2,
	default = .5,
}
_G.SettingAudioMinimumDistance = Settings.overridable.number {
	id = "audio.minimumDistance",
	name = "Minimum distance",
	order = 3,
	default = 16,
}

function F3DSound.registerHeight(groupName, height, handlerName)
	height = tonumber(height)
	if height then
		event.F3D_soundGroupHeight.add(handlerName, groupName, function(ev)
			ev.height = height
		end)
	end
end

function F3DSound.registerHeights(groupName2HeightMap)
	for groupName, height in pairs(groupName2HeightMap) do
		F3DSound.registerHeight(groupName, height)
	end
end

function F3DSound.getHeight(groupName)
	return SoundGroups.get(groupName).F3D_height
end

local eventSoundGroupHeightFire = EnumSelector.new(event.F3D_soundGroupHeight).fire

event.soundGroupsInit.add("registerSoundHeight", "postProcess", function(ev)
	for name, data in pairs(ev.groups) do
		if type(data.F3D_height) ~= "number" then
			local ev_ = { height = SettingSoundDefaultZ }
			eventSoundGroupHeightFire(ev_, name)
			data.F3D_height = tonumber(ev_.height)
		end
	end
end)

event.soundPlay.add("applySoundHeight", {
	order = "attributes",
	sequence = 1,
}, function(ev)
	ev.F3D_height = F3DSound.getHeight(ev.group)
end)

--- @param soundData table
--- @return number x
--- @return number y
--- @return number z
function F3DSound.getRelativeSoundPosition(soundData)
	local x = tonumber(soundData.x)
	local y = tonumber(soundData.F3D_height)
	local z = tonumber(soundData.y)
	if not (x and y and z) then
		return 0, 0, 0
	end

	local cx, cy, cz = camera:getPosition()
	x, y, z = staticMatrix:reset():rotate(camera:getRotation()):multiplyVector(cx - x, cy - y, cz + z)
	return z, x, y
end

local currentWorldSounds = {}

event.tick.add("updateCurrentSounds", "sound", function()
	if not GameState.isPaused() then
		Utilities.removeIf(currentWorldSounds, function(soundData)
			local id = soundData.id
			if id == nil or Audio.isStopped(id) then
				return true
			elseif not Audio.isPaused(id) then
				Audio.setPosition(id, F3DSound.getRelativeSoundPosition(soundData))
			end
		end)
	end
end)

function F3DSound.getEffectiveSoundVolume(soundData)
	local globalVolume = Sound.getSoundVolume()

	if soundData.useHighestVolume then
		globalVolume = math.max(globalVolume, Music.getMusicVolume())
	end

	return soundData.volume * soundData.groupVolume * Sound.scaleVolume(globalVolume)
end

function F3DSound.play(soundData)
	if F3DSound.PortFilter and soundData.port ~= F3DSound.PortFilter then
		soundData.id = Audio.NULL_SOURCE

		return
	end

	local id = Audio.createStaticSource(soundData.file, Sound.isAsyncLoadingEnabled(), soundData.port)
	soundData.id = id

	local soundFilter = Sound.getFilter()
	if soundFilter and not soundData.noFilter then
		Audio.setFilter(id, soundFilter)
	end
	Audio.setVolume(id, F3DSound.getEffectiveSoundVolume(soundData))
	Audio.setPitch(id, soundData.pitch)
	Audio.setPosition(id, F3DSound.getRelativeSoundPosition(soundData))
	Audio.setMinimumDistance(id, SettingAudioMinimumDistance)
	Audio.setAttenuation(id, soundData.attenuation)
	Audio.setLoop(id, soundData.loop)
	Audio.play(id)

	currentWorldSounds[#currentWorldSounds + 1] = soundData
end

event.soundPlay.add("playSound3D", {
	order = "play",
	sequence = -1,
}, function(ev)
	if not ev.ui then
		local soundOption = ev.F3D_soundOption or SettingAudioOption
		if soundOption ~= F3DSound.Option._2D and not ev.suppressed and ev.delay <= 0 then
			F3DSound.play(ev)

			if soundOption == F3DSound.Option._3D then
				ev.suppressed = true
			end
		end
	end
end)

return F3DSound
