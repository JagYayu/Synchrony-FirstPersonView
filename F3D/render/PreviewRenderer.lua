local F3DDraw = require "F3D.render.Draw"
local F3DRender = require "F3D.render.Render"

local drawImage = F3DDraw.image

event.objectPreview.add("drawSprite", {
	filter = "F3D_sprite",
	order = "sprite",
	sequence = 1,
}, function(ev)
	if tonumber(ev.x) and tonumber(ev.y) then
		local x, z = F3DRender.getTileCenter(ev.x, ev.y)
		drawImage(x, 0, z, ev.visual.rect[3] / 24, ev.visual.rect[4] / 24,
			ev.visual.texture, ev.visual.texRect[1], ev.visual.texRect[2], ev.visual.texRect[3], ev.visual.texRect[4],
			ev.visual.color)
	end
end)
