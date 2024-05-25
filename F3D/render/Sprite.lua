local F3DCamera = require "F3D.Camera"
local F3DSpriteRenderer = {}
local F3DViewport = require "F3D.render.Viewport"

local ECS = require "system.game.Entities"
local EntitySelector = require "system.events.EntitySelector"
local Player = require "necro.game.character.Player"
local Settings = require "necro.config.Settings"
local Utilities = require "system.utils.Utilities"

local CameraFieldMinimumCullingDistance = F3DCamera.Field.MinimumCullingDistance
local CameraFieldPositionZ = F3DCamera.Field.PositionZ
local CameraFieldPitch = F3DCamera.Field.Pitch
local TILE_SIZE = 24
local abs = math.abs
local atan2 = math.atan2
local cameraTransformVector = F3DCamera.transformVector
local floor = math.floor
local getCameraRenderOffset = F3DCamera.getRenderOffset
local pi = math.pi
local sqrt = math.sqrt
local squareDistance = Utilities.squareDistance
local viewportTransformVector = F3DViewport.transformVector

_G.SettingGroupSprite = Settings.overridable.group {
	id = "render.sprite",
	name = "Sprite renderer",
}

SettingSpriteScaleFactor = Settings.overridable.number {
	id = "render.sprite.scale",
	name = "Scale factor",
	default = .7,
	step = .5,
	smoothStep = .01,
	minimum = 0,
	sliderMaximum = 1,
}

local getSprite3DVisualSelectorFire = EntitySelector.new(event.F3D_getSprite3DVisual, {
	"sprite",
	"directional",
	"scale",
	"offset",
}).fire

event.F3D_getSprite3DVisual.add("copySprite2D", {
	filter = { "sprite", "!F3D_sprite3DIgnoreSprite" },
	order = "sprite",
}, function(ev) --- @param ev Event.F3D_getSprite3DVisual
	local visual = ev.visual
	local sprite = ev.entity.sprite

	visual.texture = sprite.texture
	visual.textureShiftX = sprite.textureShiftX
	visual.textureShiftY = sprite.textureShiftY
	visual.width = sprite.width
	visual.height = sprite.height
	visual.height = sprite.height
	visual.color = sprite.color

	local scale = sprite.scale * (ev.spriteScaleFactor or SettingSpriteScaleFactor) / TILE_SIZE
	visual.scaleX = visual.scaleX * scale * visual.width
	visual.scaleY = visual.scaleY * scale * visual.height
end)

event.F3D_getSprite3DVisual.add("directionalSpriteChange", {
	filter = { "F3D_sprite3D8DirectionalVisual", "F3D_sprite3D", "facingDirection" },
	order = "directional",
}, function(ev) --- @param ev Event.F3D_getSprite3DVisual
	local dx, dy = getCameraRenderOffset(ev.camera, ev.entity.F3D_sprite3D.x, ev.entity.F3D_sprite3D.y)
	local i = floor((atan2(dy, dx) - pi / 8) / (pi / 4))
	if i < 0 then
		i = i + 8
	end
	local data = ev.entity.F3D_sprite3D8DirectionalVisual.directions[8 - i]

	if data then
		local visual = ev.visual

		-- print(8 - i)
		visual.texture = data.texture or visual.texture
		visual.textureShiftX = data.textureShiftX or visual.textureShiftX
		visual.textureShiftY = data.textureShiftY or visual.textureShiftY
		if data.mirrorX ~= nil then
			visual.mirrorX = data.mirrorX
		end
		if data.mirrorY ~= nil then
			visual.mirrorY = data.mirrorY
		end
	end
end)

event.F3D_getSprite3DVisual.add("applyScale", {
	filter = "F3D_sprite3DScale",
	order = "scale",
}, function(ev)
	ev.visual.scaleX = ev.visual.scaleX * ev.entity.F3D_sprite3DScale.x
	ev.visual.scaleY = ev.visual.scaleY * ev.entity.F3D_sprite3DScale.y
end)

event.F3D_getSprite3DVisual.add("applyOffset", {
	filter = "F3D_sprite3DOffset",
	order = "offset",
}, function(ev) --- @param ev Event.F3D_getSprite3DVisual
	ev.visual.offsetX = ev.visual.offsetX + ev.entity.F3D_sprite3DOffset.x
	ev.visual.offsetY = ev.visual.offsetY + ev.entity.F3D_sprite3DOffset.y
end)

--- @class F3D.SpriteVisual
--- @field texture string
--- @field textureShiftX number
--- @field textureShiftY number
--- @field width number
--- @field height number
--- @field scaleX number
--- @field scaleY number
--- @field offsetX number
--- @field offsetY number
--- @field mirrorX boolean
--- @field mirrorY boolean
--- @field color Color
local spriteVisualsCache = {}
--- @class Event.F3D_getSprite3DVisual
--- @field camera F3D.Camera
--- @field entity Entity
--- @field visual F3D.SpriteVisual
--- @field spriteScaleFactor number?
local getSpriteVisualEv = {}
function F3DSpriteRenderer.getSpriteVisual(camera, entity)
	spriteVisualsCache.texture = ""
	spriteVisualsCache.textureShiftX = 0
	spriteVisualsCache.textureShiftY = 0
	spriteVisualsCache.width = 0
	spriteVisualsCache.height = 0
	spriteVisualsCache.scaleX = 1
	spriteVisualsCache.scaleY = 1
	spriteVisualsCache.offsetX = 0
	spriteVisualsCache.offsetY = 0
	spriteVisualsCache.mirrorX = false
	spriteVisualsCache.mirrorY = false
	spriteVisualsCache.color = -1

	getSpriteVisualEv.camera = camera
	getSpriteVisualEv.entity = entity
	getSpriteVisualEv.visual = spriteVisualsCache

	getSprite3DVisualSelectorFire(getSpriteVisualEv, entity.name)
	return spriteVisualsCache
end

local getSpriteVisual = F3DSpriteRenderer.getSpriteVisual

--- @class F3D.DrawSpriteArgs : VertexBuffer.DrawArgs
--- @field F3D_visual F3D.SpriteVisual
--- @field tx number
--- @field ty number
local drawSpriteArgs = {
	F3D_visual = spriteVisualsCache,
	rect = {},
	texRect = {},
}
local drawSpriteArgsRect = drawSpriteArgs.rect
local drawSpriteArgsTexRect = drawSpriteArgs.texRect

--- @param camera any
--- @param rect F3D.Viewport.Rect
--- @param entity Entity
--- @return F3D.DrawSpriteArgs? args
function F3DSpriteRenderer.getSpriteDrawArgs(camera, rect, entity)
	local sprite3D = entity.F3D_sprite3D
	if not sprite3D then
		return
	end

	local dx, dy = getCameraRenderOffset(camera, sprite3D.x, sprite3D.y)
	local px, py, tx, ty = viewportTransformVector(camera, rect, dx, dy)
	if not px then
		return
	end

	local visual = getSpriteVisual(camera, entity)

	drawSpriteArgs.color = visual.color
	drawSpriteArgs.texture = visual.texture
	drawSpriteArgs.z = sprite3D.zOrder - sqrt(squareDistance(dx, dy))

	local size = abs(rect[4] / ty)
	local width = size * visual.scaleX
	local height = size * visual.scaleY

	drawSpriteArgsRect[1] = px
		+ visual.offsetX * rect[3] / 2
		- width / 2
	drawSpriteArgsRect[2] = py
		+ visual.offsetY * rect[4] / ty
		- sprite3D.z * rect[4] / ty / TILE_SIZE
		- height
	drawSpriteArgsRect[3] = width
	drawSpriteArgsRect[4] = height

	if visual.mirrorX then
		drawSpriteArgsRect[1] = drawSpriteArgsRect[1] + drawSpriteArgsRect[3]
		drawSpriteArgsRect[3] = -drawSpriteArgsRect[3]
	end
	if visual.mirrorY then
		drawSpriteArgsRect[2] = drawSpriteArgsRect[2] + drawSpriteArgsRect[4]
		drawSpriteArgsRect[2] = -drawSpriteArgsRect[4]
	end

	drawSpriteArgsTexRect[1] = visual.textureShiftX
	drawSpriteArgsTexRect[2] = visual.textureShiftY
	drawSpriteArgsTexRect[3] = visual.width
	drawSpriteArgsTexRect[4] = visual.height




	drawSpriteArgs.F3D_tx = tx
	drawSpriteArgs.F3D_ty = ty
	drawSpriteArgs.F3D_visual = visual

	return drawSpriteArgs
end

local getSpriteDrawArgs = F3DSpriteRenderer.getSpriteDrawArgs

local drawSprite3DSelectorFire = EntitySelector.new(event.F3D_drawSprite3D, {
	"init",
	"sprite",
	"healthBar",
	"particles",
}).fire

--- @param ev Event.F3D_drawSprite3D
event.F3D_drawSprite3D.add("drawSprite", "sprite", function(ev)
	local drawArgs = getSpriteDrawArgs(ev.camera, ev.rect, ev.entity)
	if drawArgs then
		ev.buffer.draw(drawArgs)
		ev.drawArgs = drawArgs
	else
		ev.drawArgs = nil
	end
end)

--- @class Event.F3D_drawSprite3D
--- @field buffer VertexBuffer
--- @field camera F3D.Camera
--- @field entity Entity
--- @field rect { [1]: number, [2]: number, [3]: number, [4]: number }
--- @field sprite3D Component.F3D_sprite3D
--- @field visual F3D.SpriteVisual
--- @field drawArgs VertexBuffer.DrawArgs
local drawSpriteEv = {}

function F3DSpriteRenderer.drawSprite(buffer, camera, viewportRect, entity)
	if entity.F3D_sprite3D then
		drawSpriteEv.buffer = buffer
		drawSpriteEv.camera = camera
		drawSpriteEv.entity = entity
		drawSpriteEv.rect = viewportRect
		drawSpriteEv.sprite3D = entity.F3D_sprite3D
		drawSprite3DSelectorFire(drawSpriteEv, entity.name)
		return drawSpriteEv.visual
	end
end

local drawSprite = F3DSpriteRenderer.drawSprite

local objectVisibilitiesCache = {}

event.F3D_renderViewport.add("collectVisibleObjects", {
	order = "objects",
	sequence = -1,
}, function(ev) --- @param ev Event.F3D_renderViewport
	local playerEntityID
	do
		local playerEntity = Player.getPlayerEntity(ev.playerID)
		playerEntityID = playerEntity and playerEntity.id
	end

	Utilities.clearTable(objectVisibilitiesCache)

	for entity in ECS.entitiesWithComponents { "F3D_sprite3D", "visibility" } do
		if entity.visibility.visible and entity.id ~= playerEntityID then
			objectVisibilitiesCache[entity.id] = true
		end
	end

	for entity in ECS.entitiesWithComponents { "F3D_sprite3D", "attachment" } do
		if entity.attachment.parent == playerEntityID then
			objectVisibilitiesCache[entity.id] = nil
		end
	end

	ev.objectVisibilities = objectVisibilitiesCache
end)

event.F3D_renderViewport.add("renderSprite3Ds", {
	order = "objects",
	sequence = 10,
}, function(ev)
	for entity in ECS.entitiesWithComponents { "F3D_sprite3D" } do
		if objectVisibilitiesCache[entity.id] then
			objectVisibilitiesCache[entity.id] = drawSprite(ev.buffer, ev.camera, ev.rect, entity)
		end
	end
end)

event.render.add("attachmentCopySpritePosition", "spriteDependencies", function()
	for entity in ECS.entitiesWithComponents {
		"F3D_sprite3D",
		"attachment",
		"attachmentCopySpritePosition",
	} do
		local target = ECS.getEntityByID(entity.attachment.parent)

		if target and target.F3D_sprite3D then
			entity.F3D_sprite3D.x = target.F3D_sprite3D.x + entity.attachmentCopySpritePosition.offsetX
			entity.F3D_sprite3D.y = target.F3D_sprite3D.y + entity.attachmentCopySpritePosition.offsetY
			entity.F3D_sprite3D.z = target.F3D_sprite3D.z + entity.attachmentCopySpritePosition.offsetZ
		end
	end
end)

event.render.add("clearSpriteRendererCache", "endLegacyGraphics", function()
	--- @diagnostic disable-next-line: missing-fields
	spriteVisualsCache = {}
	--- @diagnostic disable-next-line: missing-fields
	getSpriteVisualEv = {}
	--- @diagnostic disable-next-line: missing-fields
	drawSpriteEv = {}
end)

return F3DSpriteRenderer
