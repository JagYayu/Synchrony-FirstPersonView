local F3DQuadsFrames = require "F3D.data.QuadsFrames"
local F3DRender = require "F3D.render.Render"

local Utilities = require "system.utils.Utilities"

local function extractFakewallFrames(heights)
	local frames = {}
	for i, th in ipairs(heights) do
		local h = th / 24
		local tx = (i - 1) * 24
		frames[i] = {
			{
				x1 = 0,
				y1 = h,
				z1 = 1,
				x2 = 1,
				y2 = h,
				z2 = 1,
				x3 = 0,
				y3 = h,
				z3 = 0,
				x4 = 1,
				y4 = h,
				z4 = 0,
				textureShiftX = tx,
				textureShiftY = 0,
				textureWidth = 24,
				textureHeight = 24,
			},
			{
				x1 = 1,
				y1 = h,
				z1 = 0,
				x2 = 1,
				y2 = h,
				z2 = 1,
				x3 = 1,
				y3 = 0,
				z3 = 0,
				x4 = 1,
				y4 = 0,
				z4 = 1,
				textureShiftX = tx,
				textureShiftY = 24,
				textureWidth = 24,
				textureHeight = th,
			},
			{
				x1 = 1,
				y1 = h,
				z1 = 1,
				x2 = 0,
				y2 = h,
				z2 = 1,
				x3 = 1,
				y3 = 0,
				z3 = 1,
				x4 = 0,
				y4 = 0,
				z4 = 1,
				textureShiftX = tx,
				textureShiftY = 24,
				textureWidth = 24,
				textureHeight = th,
			},
			{
				x1 = 0,
				y1 = h,
				z1 = 1,
				x2 = 0,
				y2 = h,
				z2 = 0,
				x3 = 0,
				y3 = 0,
				z3 = 1,
				x4 = 0,
				y4 = 0,
				z4 = 0,
				textureShiftX = tx,
				textureShiftY = 24,
				textureWidth = 24,
				textureHeight = th,
			},
			{
				x1 = 0,
				y1 = h,
				z1 = 0,
				x2 = 1,
				y2 = h,
				z2 = 0,
				x3 = 0,
				y3 = 0,
				z3 = 0,
				x4 = 1,
				y4 = 0,
				z4 = 0,
				textureShiftX = tx,
				textureShiftY = 24,
				textureWidth = 24,
				textureHeight = th,
			},
			{
				x1 = 0,
				y1 = 0,
				z1 = 1,
				x2 = 1,
				y2 = 0,
				z2 = 1,
				x3 = 0,
				y3 = 0,
				z3 = 0,
				x4 = 1,
				y4 = 0,
				z4 = 0,
				textureShiftX = tx,
				textureShiftY = 0,
				textureWidth = 24,
				textureHeight = 24,
				zOrder = F3DRender.ZOrder.Floor,
			},
		}
	end
	return frames
end
event.entitySchemaLoadNamedEntity.add(nil, "Fakewall", function(ev)
	ev.entity.F3D_quads = {
		offsetX = -.5,
		offsetZ = -.5,
		texture = "mods/F3D/gfx/object/fake_wall.png",
		frames = extractFakewallFrames { 24, 21, 35 },
	}
	ev.entity.F3D_quadsApplyWallColor = {}
	ev.entity.F3D_quadsFrameCopySpriteSheetX = {}
end)
event.entitySchemaLoadNamedEntity.add(nil, "Fakewall2", function(ev)
	ev.entity.F3D_quads = {
		offsetX = -.5,
		offsetZ = -.5,
		texture = "mods/F3D/gfx/object/fake_wall_shop.png",
		frames = extractFakewallFrames { 24, 21, 27, 30, 35 },
	}
	ev.entity.F3D_quadsApplyWallColor = {}
	ev.entity.F3D_quadsFrameCopySpriteSheetX = {}
end)

local function extractBounceTrapFrames()
	local h1 = 1 / 12
	local h2 = 1 / 6
	local s = .5
	local ts = 12
	local frameTemplate1 = {
		{
			x1 = 0,
			y1 = h1,
			z1 = s,
			x2 = s,
			y2 = h1,
			z2 = s,
			x3 = 0,
			y3 = h1,
			z3 = 0,
			x4 = s,
			y4 = h1,
			z4 = 0,
		},
		{
			x1 = s,
			y1 = h1,
			z1 = 0,
			x2 = s,
			y2 = h1,
			z2 = s,
			x3 = s,
			y3 = 0,
			z3 = 0,
			x4 = s,
			y4 = 0,
			z4 = s,
		},
		{
			x1 = s,
			y1 = h1,
			z1 = s,
			x2 = 0,
			y2 = h1,
			z2 = s,
			x3 = s,
			y3 = 0,
			z3 = s,
			x4 = 0,
			y4 = 0,
			z4 = s,
		},
		{
			x1 = 0,
			y1 = h1,
			z1 = s,
			x2 = 0,
			y2 = h1,
			z2 = 0,
			x3 = 0,
			y3 = 0,
			z3 = s,
			x4 = 0,
			y4 = 0,
			z4 = 0,
		},
		{
			x1 = 0,
			y1 = h1,
			z1 = 0,
			x2 = s,
			y2 = h1,
			z2 = 0,
			x3 = 0,
			y3 = 0,
			z3 = 0,
			x4 = s,
			y4 = 0,
			z4 = 0,
		},
	}
	local frameTemplate2 = {
		{
			x1 = 0,
			y1 = h2,
			z1 = s,
			x2 = s,
			y2 = h2,
			z2 = s,
			x3 = 0,
			y3 = h2,
			z3 = 0,
			x4 = s,
			y4 = h2,
			z4 = 0,
		},
		{
			x1 = s,
			y1 = h2,
			z1 = 0,
			x2 = s,
			y2 = h2,
			z2 = s,
			x3 = s,
			y3 = 0,
			z3 = 0,
			x4 = s,
			y4 = 0,
			z4 = s,
		},
		{
			x1 = s,
			y1 = h2,
			z1 = s,
			x2 = 0,
			y2 = h2,
			z2 = s,
			x3 = s,
			y3 = 0,
			z3 = s,
			x4 = 0,
			y4 = 0,
			z4 = s,
		},
		{
			x1 = 0,
			y1 = h2,
			z1 = s,
			x2 = 0,
			y2 = h2,
			z2 = 0,
			x3 = 0,
			y3 = 0,
			z3 = s,
			x4 = 0,
			y4 = 0,
			z4 = 0,
		},
		{
			x1 = 0,
			y1 = h2,
			z1 = 0,
			x2 = s,
			y2 = h2,
			z2 = 0,
			x3 = 0,
			y3 = 0,
			z3 = 0,
			x4 = s,
			y4 = 0,
			z4 = 0,
		},
	}
	local frames = {
		[0] = Utilities.mergeTablesRecursive(Utilities.fastCopy(frameTemplate1), (function()
			local t = {}
			for i = 1, 5 do
				t[i] = {
					textureShiftX = 96,
					textureShiftY = 0,
					textureWidth = 1,
					textureHeight = 1,
				}
			end
			return t
		end)())
	}
	for i = 1, 8 do
		local side = {
			textureShiftX = (i - 1) * ts,
			textureShiftY = ts,
			textureWidth = ts,
			textureHeight = 2,
		}
		frames[i] = Utilities.mergeTablesRecursive(Utilities.fastCopy(frameTemplate1), {
			{
				textureShiftX = (i - 1) * ts,
				textureShiftY = 0,
				textureWidth = ts,
				textureHeight = ts,
				zOrder = math.sqrt(.0625),
			},
			side, side, side, side,
		})
		side = {
			textureShiftX = (i - 1) * ts,
			textureShiftY = ts + 2,
			textureWidth = ts,
			textureHeight = 4,
		}
		frames[8 + i] = Utilities.mergeTablesRecursive(Utilities.fastCopy(frameTemplate2), {
			{
				textureShiftX = (i - 1) * ts,
				textureShiftY = 0,
				textureWidth = ts,
				textureHeight = ts,
				zOrder = 1e-6,
			},
			side, side, side, side,
		})
	end
	return frames
end
for _, name in ipairs {
	"BounceTrapDown",
	"BounceTrapDownLeft",
	"BounceTrapDownRight",
	"BounceTrapLeft",
	"BounceTrapRight",
	"BounceTrapRotating",
	"BounceTrapRotatingCW",
	"BounceTrapUp",
	"BounceTrapUpLeft",
	"BounceTrapUpRight",
} do
	event.entitySchemaLoadNamedEntity.add(nil, name, function(ev)
		ev.entity.F3D_position = {}
		ev.entity.F3D_quads = {
			offsetX = -.25,
			offsetZ = -.25,
			texture = "mods/F3D/gfx/object/trap_bounce.png",
			frames = extractBounceTrapFrames(),
		}
		ev.entity.F3D_quadsFrameCopyFacingDirection = {}
		ev.entity.F3D_quadsFrameSpriteSheetXShifts = { mapping = { [2] = 8 } }
	end)
end

event.entitySchemaLoadNamedEntity.add(nil, "Firepig", function(ev)
	ev.entity.F3D_position = {}
	ev.entity.F3D_quads = {
		offsetX = -.25,
		offsetZ = -.25,
		texture = "mods/F3D/gfx/object/trap_bounce.png",
		frames = extractBounceTrapFrames(),
	}
	ev.entity.F3D_quadsFrameCopyFacingDirection = {}
	ev.entity.F3D_quadsFrameSpriteSheetXShifts = {}
	F3DQuadsFrames.firePig()
end)
