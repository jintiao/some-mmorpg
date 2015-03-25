local quadtree = require "misc.quadtree"
local print_r = require "print_r"

local aoi = {}

local object = {}
local tree

function aoi.init (bbox)
	tree = quadtree.new (bbox.left, bbox.top, bbox.right, bbox.bottom)
	print ("aoi.init")
	print_r (tree)
end

function aoi.insert (id, pos)
	if object[id] then return end
	
	tree:insert (id, pos.x, pos.z)
	print ("aoi.insert")
	print_r (tree)
end

return aoi
