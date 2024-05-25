local F3DCamera = {}
local F3DUtility = require "F3D.Utility"

local CircularBuffer = require "system.utils.CircularBuffer"
local ECS = require "system.game.Entities"
local Enum = require "system.utils.Enum"
local EnumSelector = require "system.events.EnumSelector"
local Input = require "necro.client.Input"
local LocalCoop = require "necro.client.LocalCoop"
local Object = require "necro.game.object.Object"
local ObjectSelector = require "necro.game.object.ObjectSelector"
local OrderedSelector = require "system.events.OrderedSelector"
local Player = require "necro.game.character.Player"
local Render = require "necro.render.Render"
local RenderTimestep = require "necro.render.RenderTimestep"
local Settings = require "necro.config.Settings"
local SizeModifier = require "necro.game.character.SizeModifier"
local Spectator = require "necro.game.character.Spectator"
local SystemInput = require "system.game.Input"
local Tick = require "necro.cycles.Tick"
local Utilities = require "system.utils.Utilities"

local getEntityByID = ECS.getEntityByID
local getPlayerEntity = Player.getPlayerEntity
local keyDown = SystemInput.keyDown
local lerp = Utilities.lerp
local rotateVector2 = F3DUtility.rotateVector2
local slerp = F3DUtility.slerp

local TILE_SIZE = Render.TILE_SIZE
local pi = math.pi
local tau = math.pi / 2

_G.SettingGroupCamera = Settings.overridable.group {
	id = "camera",
	name = "Camera",
	order = 10,
}

SettingCameraFieldOfView = Settings.overridable.number {
	id = "camera.fov",
	name = "Field of View",
	default = tau,
	format = function(value)
		return tostring(value / pi * 180) .. "°"
	end,
	step = 5 * pi / 180,
	smoothStep = pi * 180,
	minimum = 0,
	sliderMinimum = pi / 4,
	maximum = 2 * pi,
	sliderMaximum = pi,
}

SettingCameraZ = Settings.overridable.number {
	id = "camera.z",
	name = "Default Z",
	default = .1,
	step = .1,
	smoothStep = .01,
	sliderMinimum = 0,
	sliderMaximum = 1,
}

SettingCameraFollowCharacter = Settings.overridable.bool {
	id = "camera.followCharacter",
	name = "Follow character",
	default = true,
}

SettingCameraMoveFactor = Settings.overridable.percent {
	id = "camera.moveFactor",
	name = "Move factor",
	default = .2,
}

SettingCameraRotateFactor = Settings.overridable.percent {
	id = "camera.rotateFactor",
	name = "Rotate factor",
	default = .2,
}

SettingFreeCameraSpeed = Settings.overridable.number {
	id = "camera.freeCameraSpeed",
	name = "Free camera speed",
	default = 4,
	visiblity = Settings.Visibility.HIDDEN,
}

local freeCameras = {}

SettingFreeCameras = Settings.overridable.table {
	id = "camera.freeCameras",
	name = "Free camera mode",
	default = {},
	visiblity = Settings.Visibility.HIDDEN,
	setter = function(value)
		freeCameras = {}
		for _, localPlayerIndex in ipairs(value) do
			freeCameras[localPlayerIndex] = true
		end
	end,
}

--- @enum F3D.Camera.Mode
F3DCamera.Mode = Enum.sequence {
	None = 0,
	Fixed = 1,
	TrackLocalPlayer = 2,
	Free = 3,
}

--- @enum F3D.Camera.Field
F3DCamera.Field = Enum.sequence {
	PlayerID = Enum.entry(0, { default = 0 }),
	Mode = Enum.entry(1, { default = F3DCamera.Mode.None }),
	PositionX = Enum.entry(2, { default = 0 }),
	PositionY = Enum.entry(3, { default = 0 }),
	PositionZ = Enum.entry(4, { default = .5 }),
	DirectionX = Enum.entry(5, { default = 1 }),
	DirectionY = Enum.entry(6, { default = 0 }),
	PlaneX = Enum.entry(7, { default = 0 }),
	PlaneY = Enum.entry(10, { default = 1 }),
	Pitch = Enum.entry(11, { default = 0 }),
	ViewSquareDistance = Enum.entry(12, { default = 20 ^ 2 }),
	FocusEntityID = Enum.entry(13, { default = 0 }),
	FieldOfView = Enum.entry(14, { default = tau }),
	MinimumCullingDistance = Enum.entry(15, { default = .1 }),
}

local FieldPlayerID = F3DCamera.Field.PlayerID
local FieldMode = F3DCamera.Field.Mode
local FieldPositionX = F3DCamera.Field.PositionX
local FieldPositionY = F3DCamera.Field.PositionY
local FieldPositionZ = F3DCamera.Field.PositionZ
local FieldDirectionX = F3DCamera.Field.DirectionX
local FieldDirectionY = F3DCamera.Field.DirectionY
local FieldPlaneX = F3DCamera.Field.PlaneX
local FieldPlaneY = F3DCamera.Field.PlaneY
local FieldPitch = F3DCamera.Field.Pitch
local FieldViewSquareDistance = F3DCamera.Field.ViewSquareDistance
local FieldFocusEntityID = F3DCamera.Field.FocusEntityID
local FieldFieldOfView = F3DCamera.Field.FieldOfView
local FieldMinimumCullingDistance = F3DCamera.Field.MinimumCullingDistance

--- @class F3D.Camera : { [F3D.Camera.Field]: any }
--- @field [0] Player.ID @PlayerID
--- @field [1] F3D.Camera.Mode @Mode
--- @field [2] number @PositionX
--- @field [3] number @PositionY
--- @field [4] number @PositionZ
--- @field [5] number @DirectionX
--- @field [6] number @DirectionY
--- @field [7] number @PlaneX
--- @field [10] number @PlaneY
--- @field [11] number @Pitch
--- @field [12] number @ViewSquareDistance
--- @field [13] Entity.ID @FocusEntityID
--- @field [14] number @FieldOfView
--- @field [15] number @MinimumCullingDistance

--- @type table<Player.ID, F3D.Camera>
local cameras = {}

cameras = script.persist(function()
	return cameras
end)

function F3DCamera.initialize(playerID)
	local camera = {}

	for _, fieldValue in ipairs(F3DCamera.Field.valueList) do
		local data = F3DCamera.Field.data[fieldValue]
		if data then
			if type(data.default) == "function" then
				camera[fieldValue] = data.default(playerID)
			elseif data.default ~= nil then
				camera[fieldValue] = data.default
			else
				error("Failed to initialize camera: missing default value!", 2)
			end
		end
	end

	cameras[playerID] = camera
end

event.localCoopPlayerAdded.add("addCamera3D", "cache", function(ev)
	if type(cameras[ev.playerID]) ~= "table" then
		F3DCamera.initialize(ev.playerID)
	end
end)

local cameraRemoveSelectorFire = OrderedSelector.new(event.F3D_cameraRemove, {
	"buffer",
}).fire

event.localCoopPlayerRemoved.add("removeCamera3D", "cache", function(ev)
	if cameras[ev.playerID] then
		cameraRemoveSelectorFire {
			camera = cameras[ev.playerID],
			playerID = ev.playerID,
		}

		cameras[ev.playerID] = nil
	end
end)

function F3DCamera.initializeAll()
	cameras = {}

	for _, playerID in ipairs(LocalCoop.getLocalPlayerIDs()) do
		F3DCamera.initialize(playerID)
	end
end

_G.SettingInitAll = Settings.overridable.action {
	id = "camera.initAll",
	name = "Initialize all",
	action = F3DCamera.initializeAll,
}

function F3DCamera.tryInitialize()
	local function checkValidation(data)
		for _, value in ipairs(F3DCamera.Field.valueList) do
			if type(data[value]) ~= (F3DCamera.Field.data[value].type or "number") then
				return false
			end
		end

		return true
	end

	for _, playerID in ipairs(LocalCoop.getLocalPlayerIDs()) do
		if type(cameras[playerID]) ~= "table" or not checkValidation(cameras[playerID]) then
			F3DCamera.initialize(playerID)
		end
	end
end

event.periodicCheck.add("initCameras3D", "init", F3DCamera.tryInitialize)
event.contentLoad.add("initCameras3D", "dlc", F3DCamera.tryInitialize)

function F3DCamera.getAll()
	return cameras
end

--- Get camera by player id.
--- Note parameter should be local coop player id, it returns `nil` otherwise.
--- @param playerID Player.ID
--- @return F3D.Camera? camera
function F3DCamera.get(playerID)
	return cameras[playerID]
end

--- @param camera F3D.Camera
--- @param x integer
--- @param y integer
--- @return number dx
--- @return number dy
function F3DCamera.getPositionOffset(camera, x, y)
	return x - camera[FieldPositionX] + .5, y - camera[FieldPositionY] + .5
end

--- @param camera F3D.Camera
--- @param x integer
--- @param y integer
--- @return number dx
--- @return number dy
function F3DCamera.getRenderOffset(camera, x, y)
	return x / TILE_SIZE - camera[FieldPositionX] + 1, y / TILE_SIZE - camera[FieldPositionY] + 1.5
end

--- @param camera F3D.Camera
--- @param x number
--- @param y number
--- @return number tx
--- @return number ty
function F3DCamera.transformVector(camera, x, y)
	local inverseMatrix = (1 / (camera[FieldPlaneX] * camera[FieldDirectionY] - camera[FieldPlaneY] * camera[FieldDirectionX]))
	return inverseMatrix * (camera[FieldDirectionY] * x - camera[FieldDirectionX] * y),
		inverseMatrix * (camera[FieldPlaneX] * y - camera[FieldPlaneY] * x)
end

function F3DCamera.getFreeCameras()
	return freeCameras
end

local updateCameraSelectorFire = OrderedSelector.new(event.F3D_updateCamera, {
	"default",
	"spectate",
	"finalize",
}).fire

event.F3D_updateCamera.add("focusSpectator", "spectate", function(ev)
	if ev.mode == F3DCamera.Mode.TrackLocalPlayer then
		ev.camera[FieldFocusEntityID] = Spectator.getTargetPlayerID()
	end
end)

function F3DCamera.updateCamera(camera)
	local ev = {
		camera = camera,
		mode = F3DCamera.Mode.None,
	}

	updateCameraSelectorFire(ev)
	camera[FieldMode] = ev.mode or camera[FieldMode]
end

local adjustCameraSelectorKey = {
	"position",
	"direction",
	"fieldOfView",
	"pitch",
}

local adjustCameraSelectorFire = EnumSelector.new(event.adjustCamera, adjustCameraSelectorKey, F3DCamera.Mode).fire

for _, cameraMode in ipairs {
	F3DCamera.Mode.Fixed,
	F3DCamera.Mode.TrackLocalPlayer,
} do
	event.adjustCamera.add("defaultPositionZ" .. cameraMode, {
		key = cameraMode,
		sequence = 0,
	}, function(ev) --- @param ev Event.ObjectF3D_adjustCamera
		ev.positionZ = SettingCameraZ
		ev.fieldOfView = SettingCameraFieldOfView
		ev.pitch = 0
	end)
end

local objectAdjustCameraSelectorFire = ObjectSelector.new("F3D_adjustCamera", adjustCameraSelectorKey).fire

event.objectF3D_adjustCamera.add("position", {
	filter = "position",
	order = "position",
	sequence = 1,
}, function(ev) --- @param ev Event.ObjectF3D_adjustCamera
	ev.positionX = ev.entity.position.x + 0.5
	ev.positionY = ev.entity.position.y + 0.5
	ev.positionZ = nil
end)

event.objectF3D_adjustCamera.add("sprite3D", {
	filter = "F3D_sprite3D",
	order = "position",
	sequence = 1,
}, function(ev) --- @param ev Event.ObjectF3D_adjustCamera
	if SettingCameraFollowCharacter then
		ev.positionX = ev.entity.F3D_sprite3D.x / TILE_SIZE + 1.0
		ev.positionY = ev.entity.F3D_sprite3D.y / TILE_SIZE + 1.5
		ev.positionZ = ev.entity.F3D_sprite3D.z / TILE_SIZE
	end
end)

event.objectF3D_adjustCamera.add("height", {
	filter = "F3D_camera",
	order = "position",
	sequence = 2,
}, function(ev) --- @param ev Event.ObjectF3D_adjustCamera
	ev.positionZ = (ev.positionZ or 0) + ev.entity.F3D_camera.height
end)

local function getCameraAdjustData(camera)
	local entity = getEntityByID(camera[FieldFocusEntityID])
	if not (entity and entity.F3D_camera and entity.F3D_camera.active) then
		entity = Player.getPlayerEntity(camera[FieldPlayerID])
		if not (entity and entity.F3D_camera and entity.F3D_camera.active) then
			entity = nil
		end
	end

	--- @class Event.F3D_adjustCamera : F3D.Camera.AdjustData
	--- @field camera F3D.Camera
	--- @field entity? Entity
	--- @field suppressed? boolean
	local ev = {
		camera = camera,
		entity = entity,
	}

	adjustCameraSelectorFire(camera, camera[FieldMode])

	if ev.entity and not ev.suppressed then
		--- @class Event.ObjectF3D_adjustCamera : Event.F3D_adjustCamera
		--- @field entity Entity
		objectAdjustCameraSelectorFire(ev, ev.entity)

		if not ev.suppressed then
			return ev
		end
	end
end

local function updateCameraPlane(camera)
	local x, y = rotateVector2(camera[FieldDirectionX], camera[FieldDirectionY], tau)
	camera[FieldPlaneX] = x * camera[FieldFieldOfView] / (tau)
	camera[FieldPlaneY] = y * camera[FieldFieldOfView] / (tau)
end

--- @class F3D.Camera.AdjustData
--- @field moveFactor? number
--- @field rotateFactor? number
--- @field positionX? number
--- @field positionY? number
--- @field positionZ? number
--- @field fieldOfView? number
--- @field pitch? number
--- @field angle? number

--- @param camera F3D.Camera
function F3DCamera.adjustCamera(camera)
	local data = getCameraAdjustData(camera)
	if not data then
		return
	end

	local moveFactor = data.moveFactor or SettingCameraMoveFactor ^ (1 - RenderTimestep.getDeltaTime())
	local rotateFactor = data.rotateFactor or SettingCameraRotateFactor ^ (1 - RenderTimestep.getDeltaTime())

	if data.positionX then
		camera[FieldPositionX] = lerp(camera[FieldPositionX], data.positionX, moveFactor)
	end
	if data.positionY then
		camera[FieldPositionY] = lerp(camera[FieldPositionY], data.positionY, moveFactor)
	end
	if data.positionZ then
		camera[FieldPositionZ] = lerp(camera[FieldPositionZ], data.positionZ, moveFactor)
	end
	if data.fieldOfView then
		camera[FieldFieldOfView] = lerp(camera[FieldFieldOfView], data.fieldOfView, moveFactor)
	end
	if data.pitch then
		camera[FieldPitch] = lerp(camera[FieldPitch], data.pitch, moveFactor)
	end

	if data.angle then
		local dx, dy = F3DUtility.angleToVector2(data.angle)
		camera[FieldDirectionX], camera[FieldDirectionY] = slerp(camera[FieldDirectionX], camera[FieldDirectionY],
			dx, dy, rotateFactor)
	end

	updateCameraPlane(camera)
end

function F3DCamera.adjustCameras()
	local playerIDs = Utilities.sort(Utilities.getKeyList(cameras))

	for localPlayerIndex, playerID in ipairs(playerIDs) do
		if not freeCameras[localPlayerIndex] then
			F3DCamera.adjustCamera(cameras[playerID])
		end
	end
end

event.render.add("adjustCameras", {
	order = "camera",
	sequence = 10,
}, F3DCamera.adjustCameras)

event.tick.add("processFreeCameraMode", "customHotkeys", function()
	if #freeCameras == 0 or Input.isBlocked() then
		return
	end

	local speed = Tick.getDeltaTime() * SettingFreeCameraSpeed
	if speed == 0 then
		return
	end

	local DirectionX = F3DCamera.Field.DirectionX
	local DirectionY = F3DCamera.Field.DirectionY
	local PlaneX = F3DCamera.Field.PlaneX
	local PlaneY = F3DCamera.Field.PlaneY
	local PositionX = F3DCamera.Field.PositionX
	local PositionY = F3DCamera.Field.PositionY
	local PositionZ = F3DCamera.Field.PositionZ
	local Pitch = F3DCamera.Field.Pitch

	local playerIDs = Utilities.sort(Utilities.getKeyList(cameras))

	for localPlayerIndex, playerID in ipairs(playerIDs) do
		local camera = freeCameras[localPlayerIndex] and F3DCamera.get(playerID)
		if not camera then
			goto continue
		end

		if keyDown "C" then
			camera[PositionZ] = camera[PositionZ] - speed
		end
		if keyDown "V" then
			camera[PositionZ] = camera[PositionZ] + speed
		end
		if keyDown "F" then
			camera[Pitch] = camera[Pitch] - speed
		end
		if keyDown "R" then
			camera[Pitch] = camera[Pitch] + speed
		end
		if keyDown "Q" then
			camera[DirectionX], camera[DirectionY] = rotateVector2(camera[DirectionX], camera[DirectionY], -speed)
			camera[PlaneX], camera[PlaneY] = rotateVector2(camera[PlaneX], camera[PlaneY], -speed)
		end
		if keyDown "E" then
			camera[DirectionX], camera[DirectionY] = rotateVector2(camera[DirectionX], camera[DirectionY], speed)
			camera[PlaneX], camera[PlaneY] = rotateVector2(camera[PlaneX], camera[PlaneY], speed)
		end
		if keyDown "W" then
			camera[PositionX] = camera[PositionX] + camera[DirectionX] * speed
			camera[PositionY] = camera[PositionY] + camera[DirectionY] * speed
		end
		if keyDown "A" then
			local dx, dy = rotateVector2(camera[DirectionX], camera[DirectionY], -tau)
			camera[PositionX] = camera[PositionX] + dx * speed
			camera[PositionY] = camera[PositionY] + dy * speed
		end
		if keyDown "S" then
			camera[PositionX] = camera[PositionX] - camera[DirectionX] * speed
			camera[PositionY] = camera[PositionY] - camera[DirectionY] * speed
		end
		if keyDown "D" then
			local dx, dy = rotateVector2(camera[DirectionX], camera[DirectionY], tau)
			camera[PositionX] = camera[PositionX] + dx * speed
			camera[PositionY] = camera[PositionY] + dy * speed
		end

		::continue::
	end
end)

function F3DCamera.snapCamera(camera)
	local data = getCameraAdjustData(camera)
	if not data then
		return
	end

	if data.positionX then
		camera[FieldPositionX] = data.positionX
	end
	if data.positionY then
		camera[FieldPositionY] = data.positionY
	end
	if data.positionZ then
		camera[FieldPositionZ] = data.positionZ
	end

	if data.pitch then
		camera[FieldPitch] = data.pitch
	end

	if data.angle then
		local dx, dy = F3DUtility.angleToVector2(data.angle)
		camera[FieldDirectionX], camera[FieldDirectionY] = slerp(camera[FieldDirectionX], camera[FieldDirectionY],
			dx, dy, 1)
	end

	updateCameraPlane(camera)
end

event.focusedEntityTeleport.add("snapCamera", "snapCamera", function(ev)
	local playerID = ev.entity.controllable and ev.entity.controllable.playerID
	if cameras[playerID] then
		F3DCamera.snapCamera(cameras[playerID])
	end
end)

function F3DCamera.snapCameras()
	for _, camera in pairs(cameras) do
		F3DCamera.snapCamera(camera)
	end
end

event.fastForwardComplete.add("snapCameras", "camera", F3DCamera.snapCameras)
event.gameStateLevel.add("snapCameras", "cameraSnap", F3DCamera.snapCameras)

event.objectGrow.add("cameraHeight", {
	filter = { "F3D_camera", "F3D_cameraGigantism" },
	order = "sprite",
}, function(ev)
	if not ev.suppressed then
		ev.entity.F3D_camera.height = ev.entity.F3D_camera.height + ev.entity.F3D_cameraGigantism.height
	end
end)

event.objectUngrow.add("cameraHeight", {
	filter = { "F3D_camera", "F3D_cameraGigantism" },
	order = "sprite",
}, function(ev)
	if not ev.suppressed then
		ev.entity.F3D_camera.height = ev.entity.F3D_camera.height - ev.entity.F3D_cameraGigantism.height
	end
end)

event.objectShrink.add("cameraHeight", {
	filter = { "F3D_camera", "F3D_cameraDwarfism" },
	order = "sprite",
}, function(ev)
	if not ev.suppressed then
		ev.entity.F3D_camera.height = ev.entity.F3D_camera.height + ev.entity.F3D_cameraDwarfism.height
	end
end)

event.objectUnshrink.add("cameraHeight", {
	filter = { "F3D_camera", "F3D_cameraDwarfism" },
	order = "sprite",
}, function(ev)
	if not ev.suppressed then
		ev.entity.F3D_camera.height = ev.entity.F3D_camera.height - ev.entity.F3D_cameraDwarfism.height
	end
end)

return F3DCamera
