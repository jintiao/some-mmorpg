local sparser = require "sprotoparser"

local game_proto = {}

local types = [[

.package {
	type 0 : integer
	session 1 : integer
}

.appearance {
	id 0 : integer
	name 1 : string
	race 2 : string
	class 3 : string
}

.position {
	x 0 : integer
	y 1 : integer
	z 2 : integer
	o 3 : integer
}

]]

local c2s = [[
character_list 0 {
	response {
		character 0 : *appearance(id)
	}
}

character_create 1 {
	request {
		character 0 : appearance
	}

	response {
		character 0 : appearance
		errno 1 : integer
	}
}

character_pick 2 {
	request {
		id 0 : integer
	}
}

map_move 3 {
	request {
		pos 0 : position
		dir 1 : integer
	}
}

]]

local s2c = [[
map_enter 0 {
	request {
		map 0 : string
		pos 1 : position
	}
}

aoi_move 1 {
	request {
		character 0 : integer
		pos 1 : position
		dir 2 : integer
		speed 3 : integer
	}
}

]]

game_proto.types = sparser.parse (types)
game_proto.c2s = sparser.parse (types .. c2s)
game_proto.s2c = sparser.parse (types .. s2c)

return game_proto
