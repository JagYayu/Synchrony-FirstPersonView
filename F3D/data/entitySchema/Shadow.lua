event.entitySchemaLoadEntity.add("shadow", {
	order = "overrides",
	sequence = 1,
}, function(ev)
	if ev.entity.F3D_shadow == nil and ev.entity.shadow then
		do
			local isLarge = ev.entity.shadow.texture == "ext/entities/TEMP_shadow_large.png"
			ev.entity.F3D_shadow = {
				texture = isLarge and "mods/F3D/gfx/object/shadow_large.png" or nil,
			}
		end

		if ev.entity.itemCommon then
			ev.entity.F3D_shadow.texture = "mods/F3D/gfx/object/shadow_small.png"
		end
	end
end)

local function shadowTexture(n, v)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		if ev.entity.F3D_shadow then
			ev.entity.F3D_shadow.texture = v
		end
	end)
end

shadowTexture("Fakewall", "mods/F3D/gfx/object/shadow_square.png")
shadowTexture("Fakewall2", "mods/F3D/gfx/object/shadow_square.png")
shadowTexture("Frankensteinway", "mods/F3D/gfx/object/shadow_frankensteinway.png")
shadowTexture("LuteDragon", "mods/F3D/gfx/object/shadow_lute_dragon.png")

local function shadowSize(n, v)
	event.entitySchemaLoadNamedEntity.add(nil, n, function(ev)
		if ev.entity.F3D_shadow then
			ev.entity.F3D_shadow.size = v
		end
	end)
end
shadowSize("Frankensteinway", 2)
shadowSize("LuteDragon", 3)
