local F3DDraw = require "F3D.render.Draw"
local F3DEntity = require "F3D.system.Entity"
local F3DParticleRenderer = {}
local F3DRender = require "F3D.render.Render"
local F3DSpriteAnimations = require "F3D.render.SpriteAnimations"
local F3DVector = require "F3D.necro3d.Vector"

local Action = require "necro.game.system.Action"
local AnimationTimer = require "necro.render.AnimationTimer"
local Array = require "system.utils.Array"
local Collision = require "necro.game.tile.Collision"
local Color = require "system.utils.Color"
local ECS = require "system.game.Entities"
local GFX = require "system.gfx.GFX"
local Freeze = require "necro.game.character.Freeze"
local Random = require "system.utils.Random"
local Particle = require "necro.game.system.Particle"
local ParticleRenderer = require "necro.render.level.ParticleRenderer"
local Render = require "necro.render.Render"
local SegmentVisibility = require "necro.game.vision.SegmentVisibility"
local Settings = require "necro.config.Settings"
local SettingsStorage = require "necro.config.SettingsStorage"
local StatusEffect = require "necro.game.system.StatusEffect"
local Utilities = require "system.utils.Utilities"
local Vision = require "necro.game.vision.Vision"

local TILE_SIZE = Render.TILE_SIZE
local WALL = Collision.Type.WALL
local bitOr = bit.bor
local bitLShift = bit.lshift
local clamp = Utilities.clamp
local collisionCheck = Collision.check
local cos = math.cos
local drawCube = F3DDraw.cube
local drawImage = F3DDraw.image
local getPosition3D = F3DEntity.getPosition
local getReferencedAnimationTime = AnimationTimer.getReferencedAnimationTime
local getTileCenter3D = F3DRender.getTileCenter
local floor = math.floor
local float3 = Random.float3
local getAnimationTime = AnimationTimer.getTime
local invTS = 1 / TILE_SIZE
local isRevealed = Vision.isRevealed
local isSegmentVisible = SegmentVisibility.isVisibleAt
local isStatusVisible = StatusEffect.isVisuallyActive
local lerp = Utilities.lerp
local min = math.min
local noise3 = Random.noise3
local opacity = Color.opacity
local particleSelectorFire = event.particle.fire
local rand = math.random
local sin = math.sin
local tau = math.pi * 2
local tileCenter = Render.tileCenter

event.render.add("renderConfusionParticles", "particles", function()
	local time = getAnimationTime()

	for entity in ECS.entitiesWithComponents {
		"F3D_sprite",
		"particleRingConfusion",
		"confusable",
		"visibility",
		"sprite",
		"rowOrder"
	} do
		if entity.visibility.fullyVisible and entity.sprite.visible
			and isStatusVisible(entity.confusable, entity.particleRingConfusion.blinkPeriod)
		then
			local position3D = getPosition3D(entity)
			local px = position3D.x
			local py = position3D.y + entity.sprite.height * entity.F3D_sprite.scaleY * invTS
			local pz = position3D.z

			local count = entity.particleRingConfusion.particleCount
			local period = entity.particleRingConfusion.rotationPeriod
			local t = entity.particleRingConfusion.texture
			local imageW, imageH = GFX.getImageSize(entity.particleRingConfusion.texture)
			local w = imageW * invTS
			local h = imageH * invTS
			local r = entity.particleRingConfusion.radiusX * invTS

			for i = 1, count do
				local angle = (time / period + i / count) * tau
				local x = px + cos(angle) * r
				local z = pz + sin(angle) * r

				drawImage(x, py, z, w, h,
					t, 0, 0, imageW, imageH,
					nil, F3DRender.ZOrder.Effect)
			end
		end
	end
end)

event.render.add("renderBarrierParticles", "particles", function()
	local time = getAnimationTime()

	for entity in ECS.entitiesWithComponents {
		"particleBarrier",
		"barrier",
		"visibility"
	} do
		if entity.visibility.fullyVisible and entity.sprite.visible
			and isStatusVisible(entity.barrier, entity.particleBarrier.blinkPeriod)
		then
			local data = entity.particleBarrier

			local frameX = floor(time / data.animationPeriod % 1 * data.numFrames)

			local position3D = getPosition3D(entity)
			local x = position3D.x
			local y = position3D.y
			local z = position3D.z

			drawImage(x, y, z, data.width * invTS, data.height * invTS,
				data.frontTexture, data.width * frameX, 0, data.width, data.height, nil,
				F3DRender.ZOrder.Effect + .001)

			drawImage(x, y, z, data.width * invTS, data.height * invTS,
				data.backTexture, data.width * frameX, 0, data.width, data.height, nil,
				F3DRender.ZOrder.EffectBack)
		end
	end
end)

event.render.add("renderFreezeParticles", "particles", function()
	for entity in ECS.entitiesWithComponents {
		"particleFreeze",
		"freezable",
		"visibility",
		"rowOrder"
	} do
		local data = Freeze.Type.data[entity.freezable.type]

		if not data.blinkPeriod then
			data = entity.particleFreeze
		end

		if isStatusVisible(entity.freezable, data.blinkPeriod) and entity.visibility.visible and data.texture then
			local position3D = F3DEntity.getPosition(entity)
			local frameY = data.silhouette and entity.silhouette and entity.silhouette.active and 1 or 0
			drawImage(position3D.x, position3D.y, position3D.z, data.width * invTS, data.height * invTS,
				data.texture, 0, data.height * frameY, data.width, data.height, nil, F3DRender.ZOrder.Effect)
		end
	end
end)

function F3DParticleRenderer.renderModeDirt(data, tx, ty, dx, dz, factor)
	if isRevealed(tx, ty) and isSegmentVisible(tx, ty) then
		local x, z = getTileCenter3D(tx, ty)
		local h = data.height * invTS
		drawImage(x + dx, -h / 2, z + dz, data.width * invTS, h,
			data.texture, ((tx + ty) % 2) * data.width, 0, data.width, data.height,
			factor == 0 and -1 or opacity(min(1, 1.6 * (1 - factor))))
	end
end

local renderMoleDirt = F3DParticleRenderer.renderModeDirt

event.render.add("renderMoleDirtParticles", "particles", function()
	for entity in ECS.entitiesWithComponents {
		"gameObject",
		"particleMoleDirt",
		"position",
	} do
		if entity.gameObject.tangible then
			local dx, dz = 0, 0
			if entity.F3D_spriteVibrate and entity.spriteVibrate.active then
				dx, dz = F3DSpriteAnimations.spriteVibrateOffsets(entity.id, entity.F3D_spriteVibrate)
			end
			renderMoleDirt(entity.particleMoleDirt, entity.position.x, entity.position.y, dx, dz, 0)
		end
	end
end)

event.render.add("renderJumpDirtParticles", "particles", function()
	for entity in ECS.entitiesWithComponents {
		"moveSwipe",
		"visibility",
		"previousPosition"
	} do
		local data = entity.moveSwipe
		local factor = getAnimationTime(entity.id, "jumpDirt") / data.duration

		if entity.visibility.fullyVisible and factor < 1 then
			local x, z = getTileCenter3D(entity.previousPosition.x, entity.previousPosition.y)
			local h = data.height * invTS
			drawImage(x, -h / 2, z, data.width * invTS, h,
				data.texture, data.width * floor(factor * data.numFrames), 0, data.width, data.height)
		end
	end
end)

local particleStates = {}

function F3DParticleRenderer.getParticleStates()
	return particleStates
end

local updateStatefulParticles
local drawFreeParticles
do
	local PX = 0
	local PY = 1
	local PZ = 2
	local VX = 3
	local VY = 4
	local VZ = 5
	local SIZE = 6

	F3DParticleRenderer.PX = PX
	F3DParticleRenderer.PY = PY
	F3DParticleRenderer.PZ = PZ
	F3DParticleRenderer.VX = VX
	F3DParticleRenderer.VY = VY
	F3DParticleRenderer.VZ = VZ
	F3DParticleRenderer.SIZE = SIZE

	local function generateInitialParticlesState(ev, directions, dirMulti)
		local state = Array.new(Array.Type.FLOAT, ev.particleCount * #directions * SIZE + 1)
		local velXY = ev.velocity
		local velZ = ev.velocityZ or 0
		local spreadX = ev.spreadX or ev.spread
		local spreadY = ev.spreadY or ev.spread
		local spreadZ = ev.spreadZ or ev.spread

		for dirIndex, direction in ipairs(directions) do
			local dirX, dirY = Action.getMovementOffset(direction)
			local x, y = tileCenter(ev.x + dirMulti * dirX, ev.y + dirMulti * dirY)
			local dirOffset = (dirIndex - 1) * ev.particleCount * SIZE + 1

			for partIndex = 1, ev.particleCount do
				local dx = (rand() * 2 - 1) * spreadX
				local dy = (rand() * 2 - 1) * spreadY
				local dz = (rand() - 0.5) * spreadZ
				local offset = dirOffset + (partIndex - 1) * SIZE

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

	local function initStatefulParticles(ev, directionCallback, dirMult)
		ev.stateKey = ev.stateKey or ("%s;%d;%d"):format(ev.type, ev.id, ev.turnID)

		local state = particleStates[ev.stateKey]

		if not state then
			state = generateInitialParticlesState(ev, directionCallback(ev), dirMult)
			particleStates[ev.stateKey] = state
		end
	end

	function F3DParticleRenderer.initStatefulParticles(ev, directionCallback, multiplier)
		return initStatefulParticles(ev, directionCallback or ParticleRenderer.Direction.NONE, multiplier or 0)
	end

	updateStatefulParticles = function(ev, state)
		local id, turnID = ev.id, ev.turnID
		local deltaTime = ev.time - state[0]

		state[0] = ev.time

		local remainingParticles = (state.size - 1) / SIZE
		local delay = ev.minDelay

		for i = 1, state.size - 1, SIZE do
			delay = lerp(ev.maxDelay, delay, float3(id, turnID, i) ^ (1 / remainingParticles))

			if delay > ev.time then
				ev.remainingParticles = remainingParticles

				break
			end

			remainingParticles = remainingParticles - 1
			state[i + VZ] = state[i + VZ] - ev.gravity * min(.03333333333333333, deltaTime)
			state[i + PZ] = state[i + PZ] + state[i + VZ] * deltaTime

			if state[i + PZ] < 0 then
				state[i + PZ] = 0
				state[i + VX] = state[i + VX] * ev.bounciness
				state[i + VY] = state[i + VY] * ev.bounciness
				state[i + VZ] = state[i + VZ] * -ev.bounciness
			end

			state[i + PX] = state[i + PX] + state[i + VX] * deltaTime

			if collisionCheck(floor(state[i + PX] * invTS + .5), floor(state[i + PY] * invTS + .5), WALL) then
				state[i + PX] = state[i + PX] - state[i + VX] * deltaTime
				state[i + VX] = state[i + VX] * -ev.bounciness
			end

			state[i + PY] = state[i + PY] + state[i + VY] * deltaTime

			if collisionCheck(floor(state[i + PX] * invTS + .5), floor(state[i + PY] * invTS + .5), WALL) then
				state[i + PY] = state[i + PY] - state[i + VY] * deltaTime
				state[i + VY] = state[i + VY] * -ev.bounciness
			end
		end
	end

	drawFreeParticles = function(p)
		local state = particleStates[p.stateKey]
		if not state then
			return
		end

		local cube = p.F3D_cube

		local baseOpacity = clamp(0, p.baseOpacity or 1, 1)
		local delay = p.minDelay
		local fadeDelay = p.fadeDelay
		local fadeRandom = p.fadeRandom
		local fadeTimeInv = 1 / p.fadeTime
		local id = p.id
		local maxSize = p.maxSize
		local minOpacity = p.minOpacity
		local texture = p.texture
		local textureW, textureH = GFX.getImageSize(texture)
		local time = p.time
		local turnID = p.turnID

		for i = 1, state.size - 1, SIZE do
			local x = (state[i + PX]) * invTS
			local y = (state[i + PZ]) * invTS
			local z = (-state[i + PY] - 6) * invTS

			local col
			do
				local a = baseOpacity * (1 - (time - delay - fadeDelay) * fadeTimeInv)
				if fadeRandom then
					a = a - float3(id, turnID, i + 3) * fadeRandom
				end
				a = clamp(0, a, 1)
				if minOpacity then
					a = a * lerp(minOpacity, 1, float3(id, turnID, i + 2))
				end
				col = bitOr(0xFFFFFF, bitLShift(a * 255, 24))
			end

			local w, h
			if maxSize then
				w = noise3(id, turnID, i + 1, maxSize) + 1
				h = w
			else
				w = textureW
				h = textureH
			end
			w = w * invTS * .7
			h = h * invTS * .7
			local hw = w * .5
			local hh = h * .5

			if cube then
				drawCube(x - hw, y, z - hh, w, h, w, texture, 0, 0, textureW, textureH, col)
			else
				drawImage(x - hw, y, z - hh, w, h, texture, 0, 0, textureW, textureH, col)
			end
		end
	end
end

function F3DParticleRenderer.processParticleSystem(params)
	params.time = getReferencedAnimationTime(params.id, params.turnID, "particle")
	params.factor = params.time / params.duration

	if params.factor > 1 then
		local state = particleStates[params.stateKey]

		if state then
			Array.release(state)

			particleStates[params.stateKey] = nil
		end

		return true
	end

	if not isSegmentVisible(params.x, params.y) then
		return true
	end

	particleSelectorFire(params, params.type)

	local state = particleStates[params.stateKey]

	if state then
		updateStatefulParticles(params, state)
	end
end

event.render.add("updateParticles3D", {
	order = "particles",
	sequence = 1,
}, function()
	Utilities.removeIf(Particle.getAll(), F3DParticleRenderer.processParticleSystem)
end)

event.render.add("renderFreeParticles", {
	order = "particles",
	sequence = 2,
}, function()
	for _, p in ipairs(Particle.getAll()) do
		drawFreeParticles(p)
	end
end)

event.particle.add("particleMoleDirt", "particleMoleDirt", function(ev)
	return renderMoleDirt(ev, ev.x, ev.y, 0, 0, ev.factor)
end)

do
	local init = F3DParticleRenderer.initStatefulParticles
	event.particle.add("particleSplash", "particleSplash", function(ev)
		return init(ev, ParticleRenderer.Direction.LIT_FLOOR, 0.5)
	end)
	event.particle.add("particleDig", "particleDig", function(ev)
		return init(ev, ParticleRenderer.Direction.EVENT, -0.5)
	end)
	event.particle.add("particleSink", "particleSink", function(ev)
		return init(ev, ParticleRenderer.Direction.NONE, 0)
	end)
	event.particle.add("particleUnsink", "particleUnsink", function(ev)
		return init(ev, ParticleRenderer.Direction.NONE, 0)
	end)
	event.particle.add("particleTakeDamage", "particleTakeDamage", function(ev)
		return init(ev, ParticleRenderer.Direction.EVENT, -0.5)
	end)
	event.particle.add("particleDismount", "particleDismount", function(ev)
		return init(ev, ParticleRenderer.Direction.EVENT, 0)
	end)
	event.particle.add("particleShieldBreak", "particleShieldBreak", function(ev)
		return init(ev, ParticleRenderer.Direction.EVENT, 0)
	end)
	event.particle.add("particleBeheading", "particleBeheading", function(ev)
		return init(ev, ParticleRenderer.Direction.EVENT, 0)
	end)
	event.particle.add("particleSpawn", "particleSpawn", function(ev)
		return init(ev, ParticleRenderer.Direction.NONE, 0)
	end)
	event.particle.add("particleMove", "particleMove", function(ev)
		return init(ev, ParticleRenderer.Direction.NONE, 0)
	end)
	event.particle.add("particleUnstasis", "particleUnstasis", function(ev)
		return init(ev, ParticleRenderer.Direction.NONE, 0)
	end)
end

return F3DParticleRenderer
