local quadtree = require "misc.quadtree"
local print_r = require "print_r"

local aoi = {}

local object = {}
local qtree

local STATE_STILL = 1
local STATE_MOVING = 2

function aoi.init (bbox)
	qtree = quadtree.new (bbox.left, bbox.top, bbox.right, bbox.bottom)
	print ("aoi.init")
	print_r (qtree)
end

function aoi.insert (id, pos)
	if object[id] then return false end
	
	local ok, list = qtree:insert (id, pos.x, pos.z)
	if not ok then return false end

	object[id] = { pos = pos, list = list, state = STATE_STILL }
	
	print ("aoi.insert")
	print_r (qtree)

	return ok, list
end

return aoi
