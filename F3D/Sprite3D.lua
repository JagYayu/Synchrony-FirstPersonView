local F3DSprite3D = {}

local Action = require "necro.game.system.Action"
local AnimationTimer = require "necro.render.AnimationTimer"
local ECS = require "system.game.Entities"
local FreezeFrame = require "necro.render.FreezeFrame"
local Move = require "necro.game.system.Move"
local MoveAnimations = require "necro.render.level.MoveAnimations"
local Render = require "necro.render.Render"
local Settings = require "necro.config.Settings"
local Turn = require "necro.cycles.Turn"
local Utilities = require "system.utils.Utilities"
local VertexAnimation = require "system.gfx.VertexAnimation"

local animateHop = MoveAnimations.animateHop
local firstHopFraction = 0.8
local getAnimationFactor = AnimationTimer.getFactor
local max = math.max
local tileOrigin = Render.tileRenderingOrigin
local vertexAnimationTween = VertexAnimation.tween

_G.SettingGroupSprite3D = Settings.overridable.group {
	id = "sprite3d",
	name = "Sprite 3D",
	order = 50,
}

SettingSprite3DHoverFactor = Settings.overridable.number {
	id = "sprite3d.hover",
	name = "Hover factor",
	default = .5,
	minimum = 0,
	sliderMaximum = 1,
	step = .1,
}

SettingSprite3DHopZFactor = Settings.overridable.number {
	id = "sprite3d.hopZ",
	name = "Hop z factor",
	default = 1,
	minimum = 0,
	sliderMaximum = 2,
	step = .1,
}

local function animateHopWithID(x1, y1, x2, y2, duration, factor, bounce, maxHeight, exponent)
	if factor >= 1 then
		return x2, y2, 0, 0
	end

	local x, y, z = animateHop(x1, y1, x2, y2, factor, bounce, maxHeight, exponent)
	local animID = vertexAnimationTween(x2 - x1, y2 - y1, duration, factor, bounce, maxHeight, exponent)
	return x, y, z, animID
end

local function animateMultiHop(x1, y1, x2, y2, factor, tween)
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

local function updateSprite3DPosition(entity)
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

	entity.F3D_sprite3D.x = x
	entity.F3D_sprite3D.y = y
	entity.F3D_sprite3D.z = z * SettingSprite3DHopZFactor
end

event.render.add("moveAnimations3D", {
	order = "moveAnimations",
	sequence = 1,
}, function()
	for entity in ECS.entitiesWithComponents({
		"F3D_sprite3D",
		"position",
		"!spriteStaticPosition",
	}) do
		updateSprite3DPosition(entity)
	end
end)

event.objectSpawn.add("updateStaticPosition", {
	filter = { "F3D_sprite3D", "spriteStaticPosition" },
	order = "spriteStatic",
	sequence = 1,
}, function(ev)
	updateSprite3DPosition(ev.entity)
end)

event.objectMove.add("updateStaticPosition", {
	filter = { "F3D_sprite3D", "spriteStaticPosition" },
	order = "sprite",
}, function(ev)
	updateSprite3DPosition(ev.entity)
end)

local hoverEffectHeights

function F3DSprite3D.getHoverEffectHeights()
	return hoverEffectHeights
end

event.renderEffects.add("sprite3DHoverEffectPre", {
	order = "hover",
	sequence = -1,
}, function()
	hoverEffectHeights = {}

	for entity in ECS.entitiesWithComponents {
		"F3D_sprite3D",
		"hoverEffect",
		"visibility",
		"sprite",
	} do
		if entity.visibility.visible and entity.sprite.visible and entity.hoverEffect.active then
			hoverEffectHeights[#hoverEffectHeights + 1] = {
				entity.id,
				entity.sprite.y,
			}
		end
	end
end)

event.renderEffects.add("sprite3DHoverEffectPost", {
	order = "hover",
	sequence = 1,
}, function()
	local factor = SettingSprite3DHoverFactor

	for _, entry in ipairs(hoverEffectHeights) do
		local entity = ECS.getEntityByID(entry[1])
		if entity then
			local offset = entity.sprite.y - entry[2]
			if offset ~= 0 then
				entity.F3D_sprite3D.z = entity.F3D_sprite3D.z - offset * factor
			end
		end
	end
end)

return F3DSprite3D
