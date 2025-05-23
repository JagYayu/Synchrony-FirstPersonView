local F3DRender = require "F3D.render.Render"
local F3DTileSchema = {}

local EnumSelector = require "system.events.EnumSelector"
local GFX = require "system.gfx.GFX"
local Utilities = require "system.utils.Utilities"

--- A wall sprite has 3 faces: top, front, left
--- @param texture string
--- @param wallsX integer?
--- @param wallsY integer?
--- @return { top: { x: number, y: number, width: number, height: number }, front: { x: number, y: number, width: number, height: number }, left: { x: number, y: number, width: number, height: number } }[]
function F3DTileSchema.collectWallSprites(texture, wallsX, wallsY)
	wallsX = wallsX or 1
	wallsY = wallsY or 1
	local sprites = {}
	local w, h = GFX.getImageSize(texture)
	local sw = w / wallsX / 3
	local sh = h / wallsY
	for y = 1, wallsY do
		for x = 1, wallsX * 3, 3 do
			sprites[#sprites + 1] = {
				top = {
					x = sw * (x - 1),
					y = sh * (y - 1),
					width = sw,
					height = sh,
				},
				front = {
					x = sw * x,
					y = sh * (y - 1),
					width = sw,
					height = sh,
				},
				left = {
					x = sw * (x + 1),
					y = sh * (y - 1),
					width = sw,
					height = sh,
				}
			}
		end
	end
	return sprites
end

local collectWallSprites = F3DTileSchema.collectWallSprites

function F3DTileSchema.makeFrames(count, specify)
	local frames = Utilities.newTable(count, 0)
	for i = 1, count do
		frames[i] = 1
	end
	return specify and Utilities.mergeTables(frames, specify) or frames
end

function F3DTileSchema.wall(tile, definitions)
	if type(tile) == "table" then
		tile.F3D_wall = true
		tile.F3D_wallFaceCuller = true
		tile.F3D_wallFaceCulling = true
		local default = definitions[1]
		Utilities.mergeTables(tile, default)
		tile.tilesets = tile.tilesets or {}
		for key, definition in pairs(definitions) do
			if definition ~= default then
				tile.tilesets[key] = Utilities.mergeTables(tile.tilesets[key] or {}, definition)
			end
		end
	end
end

local tileSchemaBuildNamedSelectorFire = EnumSelector.new(event.F3D_tileSchemaBuildNamed).fire

event.tileSchemaBuild.add("walls", "modify", function(tiles)
	for name, tile in pairs(tiles) do
		tileSchemaBuildNamedSelectorFire(tile, name)
	end

	do -- StoneWall
		local t1 = "mods/F3D/gfx/level/wall_stone_z1.png"
		local t2 = "mods/F3D/gfx/level/wall_stone_z2.png"
		local t3c = "mods/F3D/gfx/level/wall_stone_z3c.png"
		local t3h = "mods/F3D/gfx/level/wall_stone_z3h.png"
		local t4 = "mods/F3D/gfx/level/wall_stone_z4.png"
		local t5 = "mods/F3D/gfx/level/wall_stone_z5.png"
		F3DTileSchema.wall(tiles.StoneWall, {
			{
				F3D_texture = t1,
				F3D_sprites = collectWallSprites(t1),
				F3D_frames = 1,
			},
			Zone2 = {
				F3D_texture = t2,
				F3D_sprites = collectWallSprites(t2),
			},
			Zone3Cold = {
				F3D_texture = t3c,
				F3D_sprites = collectWallSprites(t3c),
			},
			Zone3Hot = {
				F3D_texture = t3h,
				F3D_sprites = collectWallSprites(t3h),
			},
			Zone4 = {
				F3D_texture = t4,
				F3D_sprites = collectWallSprites(t4),
			},
			Zone5 = {
				F3D_texture = t5,
				F3D_sprites = collectWallSprites(t5, 1, 2),
				F3D_frames = { 1, 1, },
			},
		})
	end

	do -- StoneWallCracked
		local t1 = "mods/F3D/gfx/level/wall_stone_crack_z1.png"
		local t2 = "mods/F3D/gfx/level/wall_stone_crack_z2.png"
		local t3c = "mods/F3D/gfx/level/wall_stone_crack_z3c.png"
		local t3h = "mods/F3D/gfx/level/wall_stone_crack_z3h.png"
		local t4 = "mods/F3D/gfx/level/wall_stone_crack_z4.png"
		local t5 = "mods/F3D/gfx/level/wall_stone_crack_z5.png"
		F3DTileSchema.wall(tiles.StoneWallCracked, {
			{
				F3D_texture = t1,
				F3D_sprites = collectWallSprites(t1),
				F3D_frames = 1,
			},
			Zone2 = {
				F3D_texture = t2,
				F3D_sprites = collectWallSprites(t2),
			},
			Zone3Cold = {
				F3D_texture = t3c,
				F3D_sprites = collectWallSprites(t3c),
			},
			Zone3Hot = {
				F3D_texture = t3h,
				F3D_sprites = collectWallSprites(t3h),
			},
			Zone4 = {
				F3D_texture = t4,
				F3D_sprites = collectWallSprites(t4),
			},
			Zone5 = {
				F3D_texture = t5,
				F3D_sprites = collectWallSprites(t5),
			},
		})
	end
end)

event.tileSchemaBuild.add("generateFloors", "finalize", function(tiles)
	for _, tile in pairs(tiles) do
		if tile.isFloor then
			tile.F3D_floor = true
			tile.F3D_platformY = tile.F3D_platformY or 0
			tile.F3D_zOrder = tile.F3D_zOrder or F3DRender.ZOrder.Floor
		end
	end
end)

event.tileSchemaBuild.add("generateWalls", "finalize", function(tiles)
	for _, tile in pairs(tiles) do
		if tile.isWall then
			tile.F3D_platformY = tile.F3D_platformY or 1
			tile.F3D_zOrder = tile.F3D_zOrder or F3DRender.ZOrder.Wall
		end
	end
end)

return F3DTileSchema
