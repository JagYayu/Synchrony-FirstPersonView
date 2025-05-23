local F3DMainCamera = require "F3D.camera.Main"
local F3DMainCameraMode = require "F3D.camera.Mode"
local F3DMultiplayerCameras = {}

local GameClient = require "necro.client.GameClient"
local GameDLC = require "necro.game.data.resource.GameDLC"
local Netplay = require "necro.network.Netplay"
local PlayerList = require "necro.client.PlayerList"
local ServerPlayerList = require "necro.server.ServerPlayerList"
local ServerRooms = require "necro.server.ServerRooms"
local ServerSocket = require "necro.server.ServerSocket"
local Settings = require "necro.config.Settings"
local SinglePlayer = require "necro.client.SinglePlayer"

local bitAnd = bit.band
local bitOr = bit.bor
local tonumber = tonumber

local flagRemoteReceive = 0b01
local flagRemoteSend = 0b10

F3DMultiplayerCameras.MessageType = Netplay.MessageType.extend "F3D_Camera"

--- @type table<Player.ID, F3D.Camera> | false
PlayerCameras = {}

SettingRemote = Settings.overridable.choice {
	id = "camera.remote",
	name = "Share cameras in multiplayer",
	choices = {
		{
			name = "Enable",
			desc = "Your camera is visible to other players and you can see others.",
			value = bitOr(flagRemoteReceive, flagRemoteSend),
		},
		{
			name = "Receive only",
			desc = "Your camera isn't visible to other players, but you can see others.",
			value = flagRemoteReceive,
		},
		{
			name = "Send only",
			desc = "Your camera is visible to other players, but you can't see others.",
			value = flagRemoteSend,
		},
		{
			name = "Disable",
			value = 0,
		},
	},
	default = bitOr(flagRemoteReceive, flagRemoteSend),
	visibility = GameDLC.isSynchronyLoaded() and Settings.Visibility.ADVANCED or Settings.Visibility.HIDDEN,
}
SettingPreview = Settings.overridable.bool {
	id = "camera.preview",
	name = "Show cameras in multiplayer",
	default = true,
	visibility = Settings.Visibility.HIDDEN,
}

--- If local user receive other player cameras' data.
--- @return boolean
function F3DMultiplayerCameras.remoteReceive()
	return bitAnd(tonumber(SettingRemote) or 0, flagRemoteReceive) ~= 0
end

--- If local user send camera data to others.
--- @return boolean
function F3DMultiplayerCameras.remoteSend()
	return bitAnd(tonumber(SettingRemote) or 0, flagRemoteSend) ~= 0
end

function F3DMultiplayerCameras.getAll()
	return PlayerCameras or nil
end

function F3DMultiplayerCameras.get(playerID)
	if PlayerCameras then
		return PlayerCameras[playerID] or false
	else
		return nil
	end
end

local pendingOutgoingData

--- Send local camera data to others.
function F3DMultiplayerCameras.upload()
	if type(pendingOutgoingData) == "table" then
		GameClient.sendUnreliable(F3DMultiplayerCameras.MessageType, pendingOutgoingData)
	end
end

event.render.add("updateMultiplayerCameras", {
	order = "camera",
	sequence = 200,
}, function()
	if SinglePlayer.isActive() then
		PlayerCameras = PlayerCameras or {}

		if F3DMainCameraMode.getData().upload and F3DMultiplayerCameras.remoteSend() then
			F3DMultiplayerCameras.upload()
		end
	else
		PlayerCameras = false
	end
end)

event.serverMessage.add("camera", F3DMultiplayerCameras.MessageType, function(ev)
	local roomID = ServerPlayerList.getRoomID(ev.playerID)
	if ServerRooms.isValidRoom(roomID) and type(ev.message) == "table" and type(ev.message[1]) == "string" then
		ev.message[0] = ev.playerID
		ServerSocket.sendUnreliable(F3DMultiplayerCameras.MessageType, ev.message,
			ServerRooms.playersInRoomExcept(roomID, ev.playerID))
	end
end)

event.clientMessage.add("camera", F3DMultiplayerCameras.MessageType, function(msg)
	if 1 then
		return
	end

	local playerID = msg[0]
	local command = msg[1]
	local mode = msg[2]
	local index = msg[3]
	local x = msg[4]
	local y = msg[5]

	if type(playerID) == "number" and type(index) == "number"
		and type(command) == "string" and #command <= maxPreviewSize
		and enableRemotePreview
	then
		local state = remotePreviews[playerID]

		if not state then
			state = {}
			remotePreviews[playerID] = state
		end

		if state.index and state.index >= index then
			-- Unreliable channel: ignore duplicate/outdated preview states
			return
		end

		mode = previewModeMapping[mode] or mode

		state.command = serialization.deserialize(command)
		state.mode = mode
		state.index = index

		editorPreview.setActivePlayer(playerID)
		editorPreview.clear()
		if type(state.command) == "table" then
			editorPreview.setMode(mode)
			editorPreview.playerName(x, y, playerList.getName(playerID))
			pcall(editorCommand.preview, state.command)
		end
		editorPreview.setActivePlayer()
	end
end)

return F3DMultiplayerCameras
