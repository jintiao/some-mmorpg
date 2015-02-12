local sparser = require "sprotoparser"

local game_proto = {}

game_proto.c2s = sparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}


]]

game_proto.s2c = sparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}
]]

return game_proto
