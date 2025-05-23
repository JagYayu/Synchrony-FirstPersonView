local F3DCameraVisibility = require "F3D.camera.Visibility"
local F3DEntity = require "F3D.system.Entity"
local F3DDraw = require "F3D.render.Draw"
local F3DMainCamera = require "F3D.camera.Main"
local F3DPlayerRenderer = {}
local F3DRender = require "F3D.render.Render"
local F3DRenderVisibility = require "F3D.camera.Visibility"
local F3DVector = require "F3D.necro3d.Vector"

local Beatmap = require "necro.audio.Beatmap"
local Camera = require "necro.render.Camera"
local ChatBadge = require "necro.client.ChatBadge"
local Collision = require "necro.game.tile.Collision"
local Color = require "system.utils.Color"
local Config = require "necro.config.Config"
local ECS = require "system.game.Entities"
local Flyaway = require "necro.game.system.Flyaway"
local Focus = require "necro.game.character.Focus"
local GFX = require "system.gfx.GFX"
local InstantReplay = require "necro.client.replay.InstantReplay"
local Inventory = require "necro.game.item.Inventory"
local Localization = require "system.i18n.Localization"
local Menu = require "necro.menu.Menu"
local PriceTag = require "necro.game.item.PriceTag"
local Render = require "necro.render.Render"
local ReplayPlayer = require "necro.client.replay.ReplayPlayer"
local Player = require "necro.game.character.Player"
local PlayerList = require "necro.client.PlayerList"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local SinglePlayer = require "necro.client.SinglePlayer"
local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local TextLabelRenderer = require "necro.render.level.TextLabelRenderer"
local Tick = require "necro.cycles.Tick"
local UI = require "necro.render.UI"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local checkEntityCameraVisibility = F3DCameraVisibility.checkEntity

function F3DPlayerRenderer.isPlayerNameRenderingEnabled()
	if not Config.multiplayer or SettingsStorage.get "video.playerNameRenderDistance" < 0 then
		return false
	elseif ReplayPlayer.isActive() then
		return Player.getCount() > 1
	else
		return not SinglePlayer.isActive()
	end
end

function F3DPlayerRenderer.renderPlayerName(entity, range)
	local visible = not range
	if range and entity and entity.controllable and entity.position and entity.visibility and entity.visibility.visible
		and (not entity.playerNameVisibility or entity.playerNameVisibility.visible)
		and (not Focus.check(entity, Focus.Flag.LOCALLY_KNOWN_PLAYER_NAME))
		and checkEntityCameraVisibility(entity)
	then
		local _, distance = Focus.getNearestWithDistance(entity.position.x, entity.position.y, Focus.Flag.TEXT_LABEL)
		visible = distance <= range
	end

	if visible then
		local position3D = F3DEntity.getPosition(entity)
		local badge = ChatBadge.getBadgeForPlayer(entity.controllable.playerID)

		F3DDraw.text(position3D.x, position3D.y + 1, position3D.z, {
			alignX = 0.5,
			alignY = 1,
			outlineThickness = 1,
			uppercase = false,
			font = UI.Font.SMALL,
			text = PlayerList.getName(entity.controllable.playerID) or "",
			fillColor = badge and ChatBadge.getColor(badge) or Color.WHITE,
			shadowColor = Color.TRANSPARENT,
			outlineColor = Color.BLACK,
		}, UI.Font.SMALL, F3DRender.ZOrder.TextLabel)
	end
end

event.render.add("renderPlayerNames", "playerNames", function(ev)
	if F3DPlayerRenderer.isPlayerNameRenderingEnabled() then
		local range = SettingsStorage.get "video.playerNameRenderDistance" ^ 2

		for _, entity in ipairs(Player.getPlayerEntities()) do
			F3DPlayerRenderer.renderPlayerName(entity, range)
		end
	end
end)

return F3DPlayerRenderer
