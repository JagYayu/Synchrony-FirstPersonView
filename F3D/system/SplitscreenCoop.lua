local F3DSplitscreenCoop = {}

local Config = require "necro.config.Config"
local Input = require "system.game.Input"
local LocalCoop = require "necro.client.LocalCoop"
local MultiInstance = require "necro.client.MultiInstance"
local SplitScreen = require "necro.client.split.SplitScreen"
local Utilities = require "system.utils.Utilities"

local maxSplits = Config.multiplayer and Config.osDesktop and 3 or 1

local MessageType = MultiInstance.MessageType.extend "F3D_CoopPlayerAction"
F3DSplitscreenCoop.MultiInstanceMessage_CoopPlayerAction = MessageType

if Config.splitScreen then
	F3DSplitscreenCoop.Available = false

	return F3DSplitscreenCoop
else
	F3DSplitscreenCoop.Available = true
end

event.tick.add("forwardToSplitscreen", {
	order = "multiInstance", sequence = 1,
}, function()
	local rawEvents = Input.rawEvents() or {}
	local rawText = Input.text() or {}
	if rawEvents[1] or rawText[1] then
		SplitScreen.send({
			type = MultiInstance.MessageType.KEY_EVENTS,
			events = rawEvents[1] and rawEvents,
			text = rawText[1] and rawText
		}, 1)
	end
end)

CoopPlayer2SplitIndex = {}

event.localCoopPlayerAdded.add("addSplitscreenCoopPlayer", {
	order = "autoBind",
	sequence = 5e7,
}, function(ev)
	LocalCoop.removePlayer(ev.playerID, function(playerID)
		local splitID
		for i = 1, maxSplits do
			splitID = SplitScreen.open(i)
			if splitID ~= false then
				splitID = i
				break
			end
		end

		if splitID then
			CoopPlayer2SplitIndex[ev.playerID] = splitID
		end
	end)
end)

event.localCoopPlayerRemoved.add("removeSplitscreenCoopPlayer", "cache", function(ev)
	-- local i = CoopPlayer2SplitIndex[ev.playerID]
	-- if i then
	-- 	SplitScreen.close(i)
	--
	-- 	CoopPlayer2SplitIndex[ev.playerID] = nil
	-- end
end)

event.menu.add("splitscreenCoop", {
	key = "localCoop",
	sequence = 1,
}, function(ev)
	-- print(ev)
end)

event.renderPlayerList.add("removeLocalCoopPlayers", "filter", function(ev)
	Utilities.removeIf(ev.list, LocalCoop.isCoopPlayer)
end)

return F3DSplitscreenCoop
