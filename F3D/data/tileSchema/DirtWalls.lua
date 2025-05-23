local F3DTileSchema = require "F3D.data.TileSchema"

local function f(n, fn)
	event.F3D_tileSchemaBuildNamed.add(n, n, fn)
end

f("DirtWall", function(tile)
	local t1 = "mods/F3D/gfx/level/wall_dirt_z1.png"
	local t2 = "mods/F3D/gfx/level/wall_dirt_z2.png"
	local t3c = "mods/F3D/gfx/level/wall_dirt_z3c.png"
	local t3h = "mods/F3D/gfx/level/wall_dirt_z3h.png"
	local t4 = "mods/F3D/gfx/level/wall_dirt_z4.png"
	local t5 = "mods/F3D/gfx/level/wall_dirt_z5.png"
	F3DTileSchema.wall(tile, {
		{
			F3D_texture = t1,
			F3D_sprites = F3DTileSchema.collectWallSprites(t1, 1, 16),
			F3D_frames = F3DTileSchema.makeFrames(16, { 14, 14 })
		},
		Zone2 = {
			F3D_texture = t2,
			F3D_sprites = F3DTileSchema.collectWallSprites(t2, 1, 8),
			F3D_frames = F3DTileSchema.makeFrames(8),
		},
		Zone3Cold = {
			F3D_texture = t3c,
			F3D_sprites = F3DTileSchema.collectWallSprites(t3c, 1, 8),
			F3D_frames = F3DTileSchema.makeFrames(8),
		},
		Zone3Hot = {
			F3D_texture = t3h,
			F3D_sprites = F3DTileSchema.collectWallSprites(t3h, 1, 8),
			F3D_frames = F3DTileSchema.makeFrames(8),
		},
		Zone4 = {
			F3D_texture = t4,
			F3D_sprites = F3DTileSchema.collectWallSprites(t3h, 1, 8),
			F3D_frames = F3DTileSchema.makeFrames(8, { 14 }),
		},
		Zone5 = {
			F3D_texture = t5,
			F3D_sprites = F3DTileSchema.collectWallSprites(t5, 1, 13),
			F3D_frames = F3DTileSchema.makeFrames(13, { 7, 7, 7, 7 }),
		},
	})
end)

f("DirtWallCracked", function(tile)
	local t1 = "mods/F3D/gfx/level/wall_dirt_crack_z1.png"
	local t2 = "mods/F3D/gfx/level/wall_dirt_crack_z2.png"
	local t3c = "mods/F3D/gfx/level/wall_dirt_crack_z3c.png"
	local t3h = "mods/F3D/gfx/level/wall_dirt_crack_z3h.png"
	local t4 = "mods/F3D/gfx/level/wall_dirt_crack_z4.png"
	local t5 = "mods/F3D/gfx/level/wall_dirt_crack_z5.png"
	F3DTileSchema.wall(tile, {
		{
			F3D_texture = t1,
			F3D_sprites = F3DTileSchema.collectWallSprites(t1),
			F3D_frames = 1,
		},
		Zone2 = {
			F3D_texture = t2,
			F3D_sprites = F3DTileSchema.collectWallSprites(t2),
		},
		Zone3Cold = {
			F3D_texture = t3c,
			F3D_sprites = F3DTileSchema.collectWallSprites(t3c),
		},
		Zone3Hot = {
			F3D_texture = t3h,
			F3D_sprites = F3DTileSchema.collectWallSprites(t3h),
		},
		Zone4 = {
			F3D_texture = t4,
			F3D_sprites = F3DTileSchema.collectWallSprites(t4),
		},
		Zone5 = {
			F3D_texture = t5,
			F3D_sprites = F3DTileSchema.collectWallSprites(t5),
		},
	})
end)

local function fn(tile)
	local t1 = "mods/F3D/gfx/level/wall_dirt_diamond_z1.png"
	local t2 = "mods/F3D/gfx/level/wall_dirt_diamond_z2.png"
	local t3c = "mods/F3D/gfx/level/wall_dirt_diamond_z3c.png"
	local t3h = "mods/F3D/gfx/level/wall_dirt_diamond_z3h.png"
	local t4 = "mods/F3D/gfx/level/wall_dirt_diamond_z4.png"
	local t5 = "mods/F3D/gfx/level/wall_dirt_diamond_z5.png"
	local anim = {
		duration = .1 / 3,
		maxInterval = 4.5,
		minInterval = 3.5,
		frames = {
			{ 5, 9 },
			{ 6, 10 },
			{ 7, 11 },
			{ 8, 12 },
		},
	}
	local def = {
		{
			F3D_texture = t1,
			F3D_sprites = F3DTileSchema.collectWallSprites(t1, 4, 3),
			F3D_wall = { 1, 1, 1, 1 },
			F3D_frames = F3DTileSchema.makeFrames(4),
			F3D_randomAnimation = anim,
		},
		Zone2 = {
			F3D_texture = t2,
			F3D_sprites = F3DTileSchema.collectWallSprites(t2, 4, 3),
			F3D_wall = { 1, 1, 1, 1 },
			F3D_frames = F3DTileSchema.makeFrames(4),
			F3D_randomAnimation = anim,
		},
		Zone3Cold = {
			F3D_texture = t3c,
			F3D_sprites = F3DTileSchema.collectWallSprites(t3c, 4, 3),
			F3D_wall = { 1, 1, 1, 1 },
			F3D_frames = F3DTileSchema.makeFrames(4),
			F3D_randomAnimation = anim,
		},
		Zone3Hot = {
			F3D_texture = t3h,
			F3D_sprites = F3DTileSchema.collectWallSprites(t3h, 4, 3),
			F3D_wall = { 1, 1, 1, 1 },
			F3D_frames = F3DTileSchema.makeFrames(4),
			F3D_randomAnimation = anim,
		},
		Zone4 = {
			F3D_texture = t4,
			F3D_sprites = F3DTileSchema.collectWallSprites(t4, 4, 3),
			F3D_wall = { 1, 1, 1, 1 },
			F3D_frames = F3DTileSchema.makeFrames(4),
			F3D_randomAnimation = anim,
		},
		Zone5 = {
			F3D_texture = t5,
			F3D_sprites = F3DTileSchema.collectWallSprites(t5, 4, 3),
			F3D_wall = { 1, 1, 1, 1 },
			F3D_frames = F3DTileSchema.makeFrames(4),
			F3D_randomAnimation = anim,
		},
	}
	F3DTileSchema.wall(tile, def)
end
f("DirtWallWithDiamonds", fn)
f("DirtWallWithGold", fn)
