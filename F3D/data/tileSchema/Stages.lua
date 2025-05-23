local F3DTileSchema = require "F3D.data.TileSchema"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

local tex1 = "mods/F3D/gfx/level/stage.png"
f("Stage1", function(tile)
	F3DTileSchema.wall(tile, { {
		F3D_texture = tex1,
		F3D_sprites = { {
			top = { x = 0, y = 0, width = 24, height = 24 },
			front = { x = 24, y = 0, width = 24, height = 24 },
			left = { x = 48, y = 0, width = 24, height = 24 },
		} },
	} })
end)
f("Stage2", function(tile)
	F3DTileSchema.wall(tile, { {
		F3D_texture = tex1,
		F3D_sprites = { {
			top = { x = 0, y = 24, width = 24, height = 24 },
			front = { x = 24, y = 24, width = 24, height = 24 },
			left = { x = 48, y = 24, width = 24, height = 24 },
		} },
	} })
end)
f("Stage3", function(tile)
	F3DTileSchema.wall(tile, { {
		F3D_texture = tex1,
		F3D_sprites = { {
			top = { x = 0, y = 48, width = 24, height = 24 },
			front = { x = 24, y = 48, width = 24, height = 24 },
			left = { x = 48, y = 48, width = 24, height = 24 },
		} },
	} })
end)

local tex2 = "mods/F3D/gfx/object/speaker.png"
local zl = .5 + 11 / 24 / 2
local zr = .5 - 11 / 24 / 2
local h = 33 / 24
local frame = {
	{
		x1 = 0,
		y1 = h,
		z1 = zl,
		x2 = 1,
		y2 = h,
		z2 = zl,
		x3 = 0,
		y3 = h,
		z3 = zr,
		x4 = 1,
		y4 = h,
		z4 = zr,
		texture = tex2,
		textureShiftX = 0,
		textureShiftY = 0,
		textureWidth = 24,
		textureHeight = 11,
	},
	{
		x1 = 0,
		y1 = h,
		z1 = zr,
		x2 = 1,
		y2 = h,
		z2 = zr,
		x3 = 0,
		y3 = 0,
		z3 = zr,
		x4 = 1,
		y4 = 0,
		z4 = zr,
		texture = tex2,
		textureShiftX = 24,
		textureShiftY = 0,
		textureWidth = 24,
		textureHeight = 33,
	},
	{
		x1 = 1,
		y1 = h,
		z1 = zr,
		x2 = 1,
		y2 = h,
		z2 = zl,
		x3 = 1,
		y3 = 0,
		z3 = zr,
		x4 = 1,
		y4 = 0,
		z4 = zl,
		texture = tex2,
		textureShiftX = 96,
		textureShiftY = 0,
		textureWidth = 11,
		textureHeight = 33,
	},
	{
		x1 = 0,
		y1 = h,
		z1 = zl,
		x2 = 1,
		y2 = h,
		z2 = zl,
		x3 = 0,
		y3 = 0,
		z3 = zl,
		x4 = 1,
		y4 = 0,
		z4 = zl,
		texture = tex2,
		textureShiftX = 24,
		textureShiftY = 0,
		textureWidth = 24,
		textureHeight = 33,
	},
	{
		x1 = 0,
		y1 = h,
		z1 = zr,
		x2 = 0,
		y2 = h,
		z2 = zl,
		x3 = 0,
		y3 = 0,
		z3 = zr,
		x4 = 0,
		y4 = 0,
		z4 = zl,
		texture = tex2,
		textureShiftX = 96,
		textureShiftY = 0,
		textureWidth = 11,
		textureHeight = 33,
	},
}
f("Speaker1", function(tile)
	F3DTileSchema.wall(tile, { {
		F3D_texture = tex1,
		F3D_sprites = { {
			top = { x = 0, y = 48, width = 24, height = 24 },
			front = { x = 24, y = 48, width = 24, height = 24 },
			left = { x = 48, y = 48, width = 24, height = 24 },
		} },
		F3D_quads = {
			offsetX = -.5,
			offsetY = 1,
			offsetZ = -.5,
			frames = { frame },
		}
	} })
end)
