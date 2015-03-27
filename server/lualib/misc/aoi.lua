local quadtree = require "misc.quadtree"
local print_r = require "print_r"

local aoi = {}

local object = {}
local qtree

local STATE_STILL = 1
local STATE_MOVING = 2

function aoi.init (bbox)
	qtree = quadtree.new (bbox.left, bbox.top, bbox.right, bbox.bottom)
end

function aoi.insert (id, pos, radius)
	if object[id] then return false end
	
	local ok = qtree:insert (id, pos.x, pos.z)
	if ok == false then return false end

	local result = {}
	qtree:query (id, pos.x - radius, pos.z - radius, pos.x + radius, pos.z + radius, result)

	object[id] = { pos = pos, list = result }
	
	return ok, result
end

return aoi
