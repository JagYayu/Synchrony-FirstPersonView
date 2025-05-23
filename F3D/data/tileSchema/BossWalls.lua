local F3DTileSchema = require "F3D.data.TileSchema"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

f("BossWall", function(tile)
	local tex1 = "mods/F3D/gfx/level/wall_boss.png"
	local tex2 = "mods/F3D/gfx/level/wall_boss_conductor.png"
	F3DTileSchema.wall(tile, {
		{
			F3D_texture = tex1,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex1, 1, 5),
			F3D_frames = F3DTileSchema.makeFrames(5),
		},
		Conductor = {
			F3D_texture = tex2,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex1, 1, 5),
			F3D_frames = F3DTileSchema.makeFrames(5),
		},
	})
end)

f("BossWallNecrodancer", function(tile)
	local tex1 = "mods/F3D/gfx/level/wall_boss_necrodancer.png"
	F3DTileSchema.wall(tile, {
		{
			F3D_texture = tex1,
			F3D_sprites = F3DTileSchema.collectWallSprites(tex1, 1, 5),
			F3D_frames = F3DTileSchema.makeFrames(5),
		},
	})
end)

for i = 1, 4 do
	local z = .5
	local h = 2

	f("BossWallPipe" .. i, function(tile)
		F3DTileSchema.wall(tile, { {
			F3D_quads = {
				offsetX = -.5,
				offsetY = 20 / 24,
				offsetZ = -.5,
				frames = { {
					{
						x1 = 0,
						y1 = h,
						z1 = z,
						x2 = 1,
						y2 = h,
						z2 = z,
						x3 = 0,
						y3 = 0,
						z3 = z,
						x4 = 1,
						y4 = 0,
						z4 = z,
						texture = "mods/F3D/gfx/object/wall_pipe.png",
						textureShiftX = (i - 1) * 24,
						textureShiftY = 0,
						textureWidth = 24,
						textureHeight = 48,
					},
				} },
			}
		} })
	end)
end
