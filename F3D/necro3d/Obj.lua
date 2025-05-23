--- @class R3DObj
local F3DObj = {}
local F3DUtility = require "F3D.necro3d.Utility"

local FileIO = require "system.game.FileIO"
local Utilities = require "system.utils.Utilities"

local arrayFind = Utilities.arrayFind
local clearTable = Utilities.clearTable
local splitString = F3DUtility.splitString
local tonumber = tonumber

--- @class R3D.Obj.Group
--- @field name string?
--- @field vList R3D.Obj.Vector[]
--- @field vtList R3D.Obj.TextureCoordinate[]
--- @field vnList R3D.Obj.Vector[]
--- @field fList R3D.Obj.Face[]

--- @alias R3D.Obj.Face { v: number, vt: number, vn: number }[]

--- @class R3D.Obj.TextureCoordinate
--- @field u number
--- @field v number
--- @field w number

--- @class R3D.Obj.Vector
--- @field x number
--- @field y number
--- @field z number

--- @alias R3D.Obj R3D.Obj.Group[]

local function toNumberOr0(e)
	return tonumber(e) or 0
end

--- @param str string
--- @return R3D.Obj
function F3DObj.loadFromString(str)
	local bSharp = ("#"):byte()

	local gList = {}

	--- @type string?
	local gName
	--- @type R3D.Obj.Vector[]?
	local vList
	--- @type R3D.Obj.TextureCoordinate[]?
	local vtList
	--- @type R3D.Obj.Vector[]?
	local vnList
	--- @type R3D.Obj.Face[]?
	local fList

	--- @type string[]
	local li = {}
	---  @type string[]?
	local lif
	print "======================"
	for _, line in ipairs(splitString(str, "\n")) do
		if line:byte() == bSharp then
			goto continue
		end

		clearTable(li)
		splitString(line, " ", li)
		local k = li[1]
		if k == "g" then
			if vList and vtList and vnList and fList then
				-- gName
			end

			vList = nil
			vtList = nil
			vnList = nil
			fList = nil
			gName = li[2]
		elseif k == "v" then
			vList = vList or {}
			vList[#vList + 1] = {
				x = toNumberOr0(li[2]),
				y = toNumberOr0(li[3]),
				z = toNumberOr0(li[4]),
			}
		elseif k == "vt" then
			vtList = vtList or {}
			vtList[#vtList + 1] = {
				u = toNumberOr0(li[2]),
				v = toNumberOr0(li[3]),
				w = toNumberOr0(li[4]),
			}
		elseif k == "vn" then
			vnList = vnList or {}
			vnList[#vnList + 1] = {
				x = toNumberOr0(li[2]),
				y = toNumberOr0(li[3]),
				z = toNumberOr0(li[4]),
			}
		elseif k == "f" then
			fList = fList or {}
			fList[#fList + 1] = {}
			local f = fList[#fList]
			lif = lif or {}

			for i = 2, math.huge do
				local e = li[i]
				if not e then
					break
				end

				clearTable(lif)
				splitString(e, "/", lif)
				f[i - 1] = {
					v = toNumberOr0(lif[1]),
					vt = toNumberOr0(lif[2]),
					vn = toNumberOr0(lif[3]),
				}
			end
		end

		::continue::
	end

	return {
		v = vList,
		vt = vtList,
		vn = vnList,
		f = fList,
	}
end

--- @type table<string, R3D.Obj | false>
local loadFromFileCache = {}

function F3DObj.clearLoadFromFileCache()
	loadFromFileCache = {}
end

event.contentLoad.add("clearObjCache", "reset", F3DObj.clearLoadFromFileCache)

--- @param path string
--- @param maxBytes number?
--- @return R3D.Obj?
function F3DObj.loadFromFile(path, maxBytes)
	if loadFromFileCache[path] == nil then
		local str = FileIO.readFileToString(path, maxBytes)
		loadFromFileCache[path] = str and F3DObj.loadFromString(str) or false
	end

	return loadFromFileCache[path] or nil
end

-- local a = { { {
-- 	v = "1",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- } }, { {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- } }, { {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- } }, { {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- } }, { {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- } }, { {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- }, {
-- 	v = "1",
-- 	vn = "2",
-- 	vt = "1"
-- } } }
-- print(R3DObj.loadFromFile("mods/R3D/gfx/models/test/Cube.obj"))

return F3DObj
