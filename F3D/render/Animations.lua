local F3DAnimations = {}
local F3DCharacter = require "F3D.system.Entity"
local F3DRender = require "F3D.render.Render"

local AnimationTimer = require "necro.render.AnimationTimer"
local ECS = require "system.game.Entities"
local EntitySelector = require "system.events.EntitySelector"
local MoveAnimations = require "necro.render.level.MoveAnimations"
local Render = require "necro.render.Render"
local Tile = require "necro.game.tile.Tile"
local VertexAnimation = require "system.gfx.VertexAnimation"

local animateHop = MoveAnimations.animateHop
local firstHopFraction = .8
local getAnimationFactor = AnimationTimer.getFactor
local getPosition3D = F3DCharacter.getPosition
local invTileSize = 1 / Render.TILE_SIZE
local isTileSolid = Tile.isSolid
local max = math.max
local random = math.random
local tileOrigin = Render.tileRenderingOrigin
local vertexAnimationTween = VertexAnimation.tween

function F3DAnimations.animateHopWithID(x1, y1, x2, y2, duration, factor, bounce, maxHeight, exponent)
	if factor >= 1 then
		return x2, y2, 0, 0
	end

	local x, y, z = animateHop(x1, y1, x2, y2, factor, bounce, maxHeight, exponent)
	local animID = vertexAnimationTween(x2 - x1, y2 - y1, duration, factor, bounce, maxHeight, exponent)
	return x, y, z, animID
end

local animateHopWithID = F3DAnimations.animateHopWithID

function F3DAnimations.animateMultiHop(x1, y1, x2, y2, factor, tween)
	local prevX, prevY = tileOrigin(tween.midpointX, tween.midpointY)
	local secondHopHeight = 12

	if prevX == x1 and prevY == y1 then
		prevX, prevY = x2, y2
		secondHopHeight = 10
	end

	if factor < firstHopFraction then
		return animateHopWithID(x1, y1, prevX, prevY,
			tween.duration, factor, tween.bounciness, tween.maxHeight, tween.exponent)
	else
		return animateHopWithID(prevX, prevY, x2, y2,
			tween.duration, factor - firstHopFraction, 0, secondHopHeight, 1)
	end
end

local animateMultiHop = F3DAnimations.animateMultiHop

local updatePositionSelectorFire = EntitySelector.new(event.F3D_updatePosition, {
	"offsets",
	"vibrate",
}).fire

event.F3D_updatePosition.add("offsets", {
	filter = "F3D_positionOffsets",
	order = "offsets",
}, function(ev)
	local p = ev.position3D
	local c = ev.entity.F3D_positionOffsets
	p.x = p.x + c.x
	p.y = p.y + c.y
	p.z = p.z + c.z
end)

event.F3D_updatePosition.add("offsetsIfInsideWall", {
	filter = "F3D_positionOffsetsIfInsideWall",
	order = "offsets",
}, function(ev)
	if isTileSolid(ev.position.x, ev.position.y) then
		local p = ev.position3D
		local c = ev.entity.F3D_positionOffsetsIfInsideWall
		p.x = p.x + c.x
		p.y = p.y + c.y
		p.z = p.z + c.z
	end
end)

event.F3D_updatePosition.add("vibrate", {
	filter = { "F3D_objectVibrate", "spriteVibrate" },
	order = "vibrate",
}, function(ev)
	if ev.entity.spriteVibrate.active then
		local p = ev.position3D
		local c = ev.entity.F3D_objectVibrate
		p.x = p.x + (random(c.x * 1024) - .5) / 1024
		p.z = p.z + (random(c.z * 1024) - .5) / 1024
	end
end)

do
	local ev = {}

	--- @param entity Entity
	function F3DAnimations.updatePosition(entity)
		local x, y = tileOrigin(entity.position.x, entity.position.y)
		local z = 0

		local tween = entity.tween
		if tween and tween.turnID >= 0 then
			local factor = max(0, getAnimationFactor(entity.id, "tween", tween.duration))
			local sx, sy = tileOrigin(tween.sourceX, tween.sourceY)

			if tween.multiPart then
				x, y, z, entity.spriteExtrapolatable.animID = animateMultiHop(sx, sy, x, y, factor, tween)
			else
				x, y, z, entity.spriteExtrapolatable.animID = animateHopWithID(sx, sy, x, y,
					tween.duration, factor, tween.bounciness, tween.maxHeight, tween.exponent)
			end
		end

		local position3D = getPosition3D(entity)
		position3D.x = invTileSize * (x + 12)
		position3D.y = invTileSize * z
		position3D.z = invTileSize * (-y - 24)

		ev.entity = entity
		ev.position = entity.position
		ev.position3D = getPosition3D(entity)
		ev.spriteExtrapolatable = entity.spriteExtrapolatable
		ev.tween = entity.tween
		updatePositionSelectorFire(ev, entity.name)
	end
end

local updatePosition = F3DAnimations.updatePosition

event.render.add("updatePositions", {
	order = "moveAnimations",
	sequence = 1,
}, function()
	for entity in ECS.entitiesWithComponents {
		"F3D_position",
		"position",
		"!spriteStaticPosition",
	} do
		if not entity.visibility or entity.visibility.visible then
			updatePosition(entity)
		end
	end
end)

event.objectSpawn.add("updateStaticPosition", {
	filter = { "F3D_position", "spriteStaticPosition" },
	order = "spriteStatic",
	sequence = 1,
}, function(ev)
	updatePosition(ev.entity)
end)

event.objectMove.add("updateStaticPosition", {
	filter = { "F3D_position", "spriteStaticPosition" },
	order = "sprite",
}, function(ev)
	updatePosition(ev.entity)
end)

return F3DAnimations
