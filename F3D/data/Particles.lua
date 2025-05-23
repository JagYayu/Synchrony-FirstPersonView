local F3DDataParticles = {}

function F3DDataParticles.markParticleAsCube(particleName)
	event.particle.add(nil, {
		key = particleName,
		sequence = 1,
	}, function(ev)
		ev.F3D_cube = true
	end)
end

for _, key in ipairs {
	"particleMoleDirt",
	"particlePuff",
	"particleSink",
	"particleSplash",
	"particleTakeDamage",
	"particleUnsink",
} do
	F3DDataParticles.markParticleAsCube(key)
end

return F3DDataParticles
