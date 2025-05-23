local F3DTileSchema = require "F3D.data.TileSchema"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

local t = "mods/F3D/gfx/level/wall_border.png"
f("LevelBorder", function(tile)
	F3DTileSchema.wall(tile, { {
		F3D_texture = t,
		F3D_sprites = F3DTileSchema.collectWallSprites(t, 1, 8),
		F3D_frames = F3DTileSchema.makeFrames(8),
	} })
end)
