local F3DParticleRenderer = {}

local Action = require "necro.game.system.Action"
local Array = require "system.utils.Array"
local Collision = require "necro.game.tile.Collision"
local Color = require "system.utils.Color"
local GFX = require "system.gfx.GFX"
local Random = require "system.utils.Random"
local Particle = require "necro.game.system.Particle"
local StatusEffect = require "necro.game.system.StatusEffect"
local Utilities = require "system.utils.Utilities"

local collisionCheck = Collision.check
local cos = math.cos
local float3 = Random.float3
local lerp = Utilities.lerp
local rand = math.random
local sin = math.sin

local drawArgsConfusion = {
	rect = {},
	texRect = {},
}

local function drawConfusionRingParticles(camera, draw, entity, args)

end

event.F3D_drawSprite3D.add("renderConfusionParticles", {
	filter = { "F3D_sprite3D", "confusable", "particleRingConfusion", "visibility" },
	order = "particles",
}, function(ev) --- @param ev Event.F3D_drawSprite3D
	if not ev.drawArgs then
		return
	end

	local ring = ev.entity.particleRingConfusion

	drawArgsConfusion.texture = ring.texture

	local sprite3D = ev.entity.F3D_sprite3D

	local entity = ev.entity
	if entity.visibility.fullyVisible and (entity.sprite and entity.sprite.visible)
		and StatusEffect.isVisuallyActive(entity.confusable, ring.blinkPeriod)
	then
		local centerX = ev.drawArgs.rect[1] + ev.drawArgs.rect[3] / 2
		local centerY = ev.drawArgs.rect[3] + ev.drawArgs.rect[4] / 2
		--sprite3D.x + ring.offsetX + (sprite3D.width + sprite3D.mirrorOffsetX * sprite3D.mirrorX) * 0.5
		--sprite3D.y + ring.offsetY - (sprite3D.height * 0.5 + sprite3D.originY) * (sprite3D.scale - 1)
		local objectZ = ev.drawArgs.z
		local zOff = entity.rowOrder.z + 7

		for i = 1, ring.particleCount do
			local angle = (time / ring.rotationPeriod + i / ring.particleCount) * tau
			local x = centerX + cos(angle) * ring.radiusX
			local y = centerY + sin(angle) * ring.radiusY

			drawArgsConfusion.rect[1] = x
			drawArgsConfusion.rect[2] = y
			drawArgsConfusion.z = y + zOff

			draw(drawArgsConfusion)
		end
	end
end)

local particleState = {}
local PX = 0
local PY = 1
local PZ = 2
local VX = 3
local VY = 4
local VZ = 5

local function generateInitialParticlesState(ev, directions, dirMult)
	local state = Array.new(Array.Type.FLOAT, ev.particleCount * #directions * 6 + 1)
	local velXY = ev.velocity
	local velZ = ev.velocityZ or 0
	local spreadX = ev.spreadX or ev.spread
	local spreadY = ev.spreadY or ev.spread
	local spreadZ = ev.spreadZ or ev.spread

	for dirIndex, direction in ipairs(directions) do
		local dirX, dirY = Action.getMovementOffset(direction)
		local x, y = tileCenter(ev.x + dirMult * dirX, ev.y + dirMult * dirY)
		local dirOffset = (dirIndex - 1) * ev.particleCount * 6 + 1

		for partIndex = 1, ev.particleCount do
			local dx = (rand() * 2 - 1) * spreadX
			local dy = (rand() * 2 - 1) * spreadY
			local dz = (rand() - 0.5) * spreadZ
			local offset = dirOffset + (partIndex - 1) * 6

			state[offset + PX] = x + dx
			state[offset + PY] = y + dy + ev.offsetY
			state[offset + PZ] = dz + ev.offsetZ
			state[offset + VX] = ev.explosiveness * dx + velXY * dirX
			state[offset + VY] = ev.explosiveness * dy + velXY * dirY
			state[offset + VZ] = ev.explosiveness * dz + velZ
		end
	end

	return state
end

local function updateAndRenderStatefulParticles(ev, state)
	local id, turnID = ev.id, ev.turnID
	local deltaTime = ev.time - state[0]

	state[0] = ev.time

	local remainingParticles = (state.size - 1) / 6
	local delay = ev.minDelay
	local baseOpacity = clamp(0, ev.baseOpacity or 1, 1)

	if not ev.drawArgs then
		local imageWidth, imageHeight = GFX.getImageSize(ev.texture)

		ev.drawArgs = {
			anim = 0,
			texture = ev.texture,
			rect = {
				0,
				0,
				ev.size or imageWidth,
				ev.size or imageHeight
			},
			texRect = {
				0,
				0,
				imageWidth,
				imageHeight
			},
			color = ev.color or color.WHITE
		}
	end

	local drawArgs = ev.drawArgs
	local offsetX = -(ev.size or drawArgs.texRect[3]) * (ev.alignX or 0.5)
	local offsetY = ev.alignY and -(ev.size or drawArgs.texRect[4]) * ev.alignY or 0
	local draw = buffer.draw

	for i = 1, state.size - 1, 6 do
		delay = lerp(ev.maxDelay, delay, float3(id, turnID, i) ^ (1 / remainingParticles))

		if delay > ev.time then
			ev.remainingParticles = remainingParticles

			break
		end

		remainingParticles = remainingParticles - 1
		state[i + VZ] = state[i + VZ] - ev.gravity * min(0.03333333333333333, deltaTime)
		state[i + PZ] = state[i + PZ] + state[i + VZ] * deltaTime

		if state[i + PZ] < 0 then
			state[i + PZ] = 0
			state[i + VX] = state[i + VX] * ev.bounciness
			state[i + VY] = state[i + VY] * ev.bounciness
			state[i + VZ] = state[i + VZ] * -ev.bounciness
		end

		state[i + PX] = state[i + PX] + state[i + VX] * deltaTime

		if collisionCheck(floor(state[i + PX] / 24 + 0.5), floor(state[i + PY] / 24 + 0.5), WALL) then
			state[i + PX] = state[i + PX] - state[i + VX] * deltaTime
			state[i + VX] = state[i + VX] * -ev.bounciness
		end

		state[i + PY] = state[i + PY] + state[i + VY] * deltaTime

		if collisionCheck(floor(state[i + PX] / 24 + 0.5), floor(state[i + PY] / 24 + 0.5), WALL) then
			state[i + PY] = state[i + PY] - state[i + VY] * deltaTime
			state[i + VY] = state[i + VY] * -ev.bounciness
		end

		local alpha = baseOpacity * (1 - (ev.time - delay - ev.fadeDelay) / ev.fadeTime)

		if ev.fadeRandom then
			alpha = alpha - float3(id, turnID, i + 3) * ev.fadeRandom
		end

		alpha = clamp(0, alpha, 1)

		if ev.minOpacity then
			alpha = alpha * lerp(ev.minOpacity, 1, float3(id, turnID, i + 2))
		end

		drawArgs.color = bitOr(bitAnd(drawArgs.color, 16777215), bitLShift(alpha * 255, 24))
		drawArgs.z = state[i + PY] - 24
		drawArgs.rect[1] = offsetX + state[i + PX]
		drawArgs.rect[2] = offsetY + state[i + PY] - state[i + PZ]
		drawArgs.anim = transientLinearFreezable(state[i + VX], state[i + VY] - state[i + VZ], 0.3)

		if ev.maxSize then
			local size = noise3(id, turnID, i + 1, ev.maxSize) + 1

			drawArgs.rect[3] = size
			drawArgs.rect[4] = size
		end

		draw(drawArgs)
	end
end


event.F3D_renderViewport.add("renderFreeParticles", "particles", function()
	for _, p in ipairs(Particle.getAll()) do
	end
end)
