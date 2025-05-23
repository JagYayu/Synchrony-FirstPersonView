local F3DEntity = require "F3D.system.Entity"
local F3DUIRenderer = {}
local F3DMainCameraFirstPersonMode = require "F3D.camera.FirstPersonMode"
local F3DUtilities = require "F3D.system.Utilities"

local Character = require "necro.game.character.Character"
local Color = require "system.utils.Color"
local ECS = require "system.game.Entities"
local EntitySelector = require "system.events.EntitySelector"
local Enum = require "system.utils.Enum"
local Focus = require "necro.game.character.Focus"
local GFX = require "system.gfx.GFX"
local HUD = require "necro.render.hud.HUD"
local HUDLayout = require "necro.render.hud.HUDLayout"
local ObjectPreview = require "necro.render.level.ObjectPreview"
local ObjectRenderer = require "necro.render.level.ObjectRenderer"
local Player = require "necro.game.character.Player"
local Render = require "necro.render.Render"
local RenderTimestep = require "necro.render.RenderTimestep"
local Room = require "necro.client.Room"
local Settings = require "necro.config.Settings"
local UI = require "necro.render.UI"
local Utilities = require "system.utils.Utilities"

local getObjectVisual = ObjectRenderer.getObjectVisual

local bufferID = Render.Buffer.extend("F3D_CameraUI", Enum.entry(18.5, { transform = Render.Transform.UI }))
table.sort(Render.Buffer.valueList)
F3DUIRenderer.Buffer_CameraUI = bufferID
local buffer = Render.getBuffer(bufferID)

event.render.add("drawGrabber", {
	order = "objects",
	sequence = 200,
}, function()
	local entity = F3DMainCameraFirstPersonMode.getGrabber()
	if entity then
		-- AnimationTimer.play(entity.id, "F3D_grabberJumpscare")

		local visual = getObjectVisual(entity)
		local w, h = GFX.getSize()
		local s = math.max(w, h)
		visual.rect[1] = 0
		visual.rect[2] = -s / 2
		visual.rect[3] = s
		visual.rect[4] = s
		visual.color = visual.color
		buffer.draw(visual)
	end
end)

_G.SettingEntityPreview = Settings.overridable.bool {
	id = "render.entityPreview",
	name = "Focused entity previews",
	default = true,
	visibility = Settings.Visibility.ADVANCED,
}

F3DUIRenderer.HUDLayout_Element_EntityPreview = HUDLayout.register {
	name = "F3D_EntityPreview",
	parent = HUDLayout.Element.PLAYER_LIST,
	placement = HUDLayout.Alignment.BOTTOM_LEFT,
	origin = HUDLayout.Alignment.BOTTOM_LEFT,
	slotAlign = HUDLayout.Alignment.BOTTOM_CENTER,
	slotSize = { Render.TILE_SIZE * 2, Render.TILE_SIZE * 2 },
	margins = { Render.TILE_SIZE / 2, Render.TILE_SIZE / 2, Render.TILE_SIZE / 2, Render.TILE_SIZE / 2 },
}

local renderEntityPreviewSelectorFire = EntitySelector.new(event.F3D_renderEntityPreview, {
	"object",
	"shadow",
	"attachments",
	"equipments",
}).fire

event.F3D_renderEntityPreview.add("sprite", {
	filter = { "rowOrder", "sprite" },
	order = "object",
}, function(ev)
	local visual = ObjectRenderer.getObjectVisual(ev.scaledEntity)

	ev.offset[1] = ev.centerX - visual.rect[1] - visual.rect[3] * .5
	ev.offset[2] = ev.centerY - visual.rect[2] - visual.rect[4] * .5

	visual.rect[1] = visual.rect[1] + ev.offset[1] + ev.dx * ev.df
	visual.rect[2] = visual.rect[2] + ev.offset[2] + (ev.dy - ev.position3D.y) * ev.df

	Render.getBuffer(Render.Buffer.UI_HUD).draw {
		angle = visual.angle,
		origin = visual.origin,
		rect = visual.rect,
		texRect = visual.texRect,
		texture = visual.texture,
		z = visual.z,
	}

	ev.objectVisual = visual
end)

event.F3D_renderEntityPreview.add("shadow", {
	filter = "shadow",
	order = "shadow",
}, function(ev)
	local visual = ObjectRenderer.getShadowVisual(ev.scaledEntity)

	visual.rect[1] = visual.rect[1] + ev.offset[1] + ev.dx * ev.df
	visual.rect[2] = visual.rect[2] + ev.offset[2] + ev.dy * ev.df

	Render.getBuffer(Render.Buffer.UI_HUD).draw {
		angle = visual.angle,
		origin = visual.origin,
		rect = visual.rect,
		texRect = visual.texRect,
		texture = visual.texture,
		z = visual.z,
	}

	ev.shadowVisual = visual
end)

event.F3D_renderEntityPreview.add("attachment", {
	filter = "characterWithAttachment",
	order = "attachments",
}, function(ev)
	local entity = ECS.getEntityByID(ev.entity.characterWithAttachment.attachmentID)
	if entity then
		local visual = ObjectRenderer.getObjectVisual(F3DUtilities.scaleEntityWrapper(entity, 4))

		visual.rect[1] = visual.rect[1] + ev.offset[1] + ev.dx * ev.df
		visual.rect[2] = visual.rect[2] + ev.offset[2] + (ev.dy - ev.position3D.y) * ev.df

		Render.getBuffer(Render.Buffer.UI_HUD).draw {
			angle = visual.angle,
			origin = visual.origin,
			rect = visual.rect,
			texRect = visual.texRect,
			texture = visual.texture,
			z = visual.z,
		}

		ev.attachmentVisual = visual
	end
end)

do
	local entityPreviewPositions = {}

	event.focusedEntityTeleport.add("clearPlayerPreviewPosition", "snapCamera", function(ev)
		entityPreviewPositions[ev.entity.id] = nil
	end)

	event.render.add("clearPlayerPreviewPositions", "hud", function()
		for id in pairs(entityPreviewPositions) do
			local entity = ECS.getEntityByID(id)
			if not (entity and Character.isAlive(entity)) then
				entityPreviewPositions[id] = nil
			end
		end
	end)

	event.focusedEntitiesChanged.add("clearPlayerPreviewPositions", "perspective", function()
		local focusedEntityIDSet = {}
		for _, entity in ipairs(Focus.getAll(Focus.Flag.CAMERA)) do
			focusedEntityIDSet[entity.id] = true
		end
		for id in pairs(entityPreviewPositions) do
			if not focusedEntityIDSet[id] then
				entityPreviewPositions[id] = nil
			end
		end
	end)

	function F3DUIRenderer.drawEntityPreview(entity)
		local position
		if not entityPreviewPositions[entity.id] then
			local position3D = F3DEntity.getPosition(entity)
			position = { position3D.x, position3D.z }
			entityPreviewPositions[entity.id] = position
		else
			position = entityPreviewPositions[entity.id]
			position[1] = tonumber(position[1]) or 0
			position[2] = tonumber(position[2]) or 0
		end

		local position3D = F3DEntity.getPosition(entity)

		local t = 1 - 1e-9 ^ (RenderTimestep.getDeltaTime() * (Room.getTempoMultiplier() or 1))
		position[1] = Utilities.lerp(position[1], position3D.x, t)
		position[2] = Utilities.lerp(position[2], position3D.z, t)

		local rect = HUD.getSlotRect { element = F3DUIRenderer.HUDLayout_Element_EntityPreview }
		renderEntityPreviewSelectorFire({
			centerX = rect[1] + rect[3] * .5,
			centerY = rect[2] + rect[4] * .5,
			df = HUD.getScaleFactor() * Render.TILE_SIZE * 2,
			dx = (position3D.x - position[1]),
			dy = (position[2] - position3D.z),
			entity = entity,
			offset = { 0, 0 },
			position3D = position3D,
			scaledEntity = F3DUtilities.scaleEntityWrapper(entity, 4),
		}, entity.name)
	end
end

event.renderPlayerHUD.add("previewPlayerEntity", {
	filter = { "F3D_position", "gameObject", "sprite" },
	order = "initLayout",
	sequence = 1,
}, function(entity)
	if SettingEntityPreview and entity.gameObject.tangible and entity.sprite.visible then
		F3DUIRenderer.drawEntityPreview(entity)
	end
end)

return F3DUIRenderer
