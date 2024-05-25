local F3DAudio = {}
local F3DUtility = require "F3D.Utility"

local Audio = require "system.game.Audio"
local EntitySelector = require "system.events.EntitySelector"
local Focus = require "necro.game.character.Focus"
local Music = require "necro.audio.Music"
local Segment = require "necro.game.tile.Segment"
local Settings = require "necro.config.Settings"
local Sound = require "necro.audio.Sound"

local inf = math.huge
local length3 = F3DUtility.length3
local min = math.min

F3DAudio.PortFilter = false
do
	local presentSession, Session = pcall(require, "system.game.Session")
	if presentSession and Session.isDuplicate() then
		F3DAudio.PortFilter = Sound.Port.PERSONAL
	end
end

_G.SettingGroupAudio = Settings.overridable.group {
	id = "audio",
	name = "Audio",
	order = 30,
}

SettingAudioDefaultZ = Settings.overridable.number {
	id = "audio.z",
	name = "Default z",
	default = 0,
}

SettingAudioMinimumDistance = Settings.overridable.number {
	id = "audio.minimumDistance",
	name = "Minimum distance",
	default = 16,
	visibility = Settings.Visibility.HIDDEN,
}

SettingAudioOption = Settings.overridable.choice {
	id = "audio.option",
	name = "Option",
	default = 1,
	choices = {
		{
			name = "2D Space",
			value = 0,
		},
		{
			name = "3D Space",
			value = 1,
		},
		{
			name = "Both 2D & 3D Spaces",
			value = 2,
		},
	},
}

local listeners = {}

function F3DAudio.getListeners()
	return listeners
end

local getListenerPositionSelectorFire = EntitySelector.new(event.F3D_getListenerPosition, {
	"position",
	"item",
}).fire

event.F3D_getListenerPosition.add("position", {
	filter = "position",
	order = "position",
}, function(ev)
	ev.x = ev.entity.position.x
	ev.y = ev.entity.position.y
end)

function F3DAudio.getListenerPosition(entity)
	local ev = {
		entity = entity,
		x = 0,
		y = 0,
		z = 0,
	}
	getListenerPositionSelectorFire(ev, entity.name)
	return ev.x, ev.y, ev.z
end

function F3DAudio.updateListeners()
	local newListeners = {}
	for _, entity in ipairs(Focus.getAll(Focus.Flag.SOUND_LISTENER)) do
		if entity then
			local x, y, z = F3DAudio.getListenerPosition(entity)
			newListeners[#newListeners + 1] = {
				entity = entity,
				segment = Segment.getSegmentIDAt(entity.position.x, entity.position.y),
				x = x,
				y = y,
				z = z,
			}
		end
	end

	if newListeners[1] then
		listeners = newListeners
	end
end

event.focusedEntityTeleport.add("updateListeners", "updateListeners", F3DAudio.updateListeners)
event.tick.add("updateSounds", {
	order = "sound",
	sequence = -1,
}, F3DAudio.updateListeners)

local getListenerSoundRelativePositionSelectorFire = EntitySelector.new(event.F3D_getListenerSoundRelativePosition, {
	"rotate",
}).fire

function F3DAudio.getRelativeSoundPosition(soundData)
	local x, y = soundData.x, soundData.y
	if not x or not y then
		return 0, 0, 0
	end

	local activeListeners = {}
	for _, listener in ipairs(listeners) do
		if Segment.contains(listener.segment, x, y) or soundData.crossSegment then
			activeListeners[#activeListeners + 1] = listener
		end
	end
	if not activeListeners[1] then
		return
	end

	local function get(listener)
		local ev = {
			entity = listener.entity,
			dx = soundData.x - listener.x,
			dy = soundData.y - listener.y,
			dz = (soundData.F3D_z or SettingAudioDefaultZ) - listener.z,
		}
		getListenerSoundRelativePositionSelectorFire(ev, listener.entity.name)
		return ev.dx, ev.dy, ev.dz
	end

	local rx = 0
	local ry = 0
	local rz = 0

	if activeListeners[2] then
		local minDist = inf
		for _, listener in ipairs(activeListeners) do
			local dx, dy, dz = get(listener)
			minDist = min(minDist, length3(dx, dy, dz))
			rx = rx + dx
			ry = ry + dy
			rz = rz + dz
		end

		local length = length3(rx, ry, rz)
		local factor = length > 1e-4 and minDist / length or 0
		rx = rx * factor
		ry = ry * factor
		rz = rz * factor
	elseif activeListeners[1] then
		rx, ry, rz = get(activeListeners[1])
	end

	return rx, ry, rz
end

function F3DAudio.getEffectiveSoundVolume(soundData)
	local globalVolume = Sound.getSoundVolume()

	if soundData.useHighestVolume then
		globalVolume = math.max(globalVolume, Music.getMusicVolume())
	end

	return soundData.volume * soundData.groupVolume * Sound.scaleVolume(globalVolume)
end

function F3DAudio.play(soundData)
	if F3DAudio.PortFilter and soundData.port ~= F3DAudio.PortFilter then
		soundData.id = Audio.NULL_SOURCE

		return
	end

	local x, y, z = F3DAudio.getRelativeSoundPosition(soundData)
	if not x then
		soundData.id = Audio.NULL_SOURCE

		return
	end

	local id = Audio.createStaticSource(soundData.file, Sound.isAsyncLoadingEnabled(), soundData.port)

	soundData.id = id

	Audio.setVolume(id, F3DAudio.getEffectiveSoundVolume(soundData))
	Audio.setPitch(id, soundData.pitch)
	Audio.setPosition(id, x, y, z)
	Audio.setMinimumDistance(id, SettingAudioMinimumDistance)
	Audio.setAttenuation(id, soundData.attenuation)
	Audio.setLoop(id, soundData.loop)

	local soundFilter = Sound.getFilter()
	if soundFilter and not soundData.noFilter then
		Audio.setFilter(id, soundFilter)
	end

	Audio.play(soundData.id)
end

event.soundPlay.add("playSound3D", {
	order = "play",
	sequence = -1,
}, function(ev)
	local soundOption = ev.F3D_soundOption or SettingAudioOption
	if soundOption ~= 0 and not ev.suppressed and ev.delay <= 0 then
		F3DAudio.play(ev)

		if soundOption == 1 then
			ev.suppressed = true
		end
	end
end)

listeners = script.persist(function()
	return listeners
end)

return F3DAudio
