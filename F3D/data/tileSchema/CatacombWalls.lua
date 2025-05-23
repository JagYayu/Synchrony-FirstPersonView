local F3DTileSchema = require "F3D.data.TileSchema"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

f("CatacombWall", function(tile)
	local tex1 = "mods/F3D/gfx/level/wall_catacomb_z1.png"
	local tex4 = "mods/F3D/gfx/level/wall_catacomb_z4.png"
	local tex5 = "mods/F3D/gfx/level/wall_catacomb_z5.png"
	F3DTileSchema.wall(tile, {
		{
			F3D_texture = tex1,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex1, 1, 2),
			F3D_frames = { 1, 1 },
		},
		Zone4 = {
			F3D_texture = tex4,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex4, 1, 2),
		},
		Zone5 = {
			F3D_texture = tex5,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex5, 1, 4),
			F3D_frames = { 1, 1, 1, 1 },
		},
	})
end)

f("CatacombWallCracked", function(tile)
	local tex1 = "mods/F3D/gfx/level/wall_catacomb_crack_z1.png"
	local tex4 = "mods/F3D/gfx/level/wall_catacomb_crack_z4.png"
	local tex5 = "mods/F3D/gfx/level/wall_catacomb_crack_z5.png"
	F3DTileSchema.wall(tile, {
		{
			F3D_texture = tex1,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex1),
			F3D_frames = 1,
		},
		Zone4 = {
			F3D_texture = tex4,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex4),
		},
		Zone5 = {
			F3D_texture = tex5,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex5),
		},
	})
end)
