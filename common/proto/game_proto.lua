local sparser = require "sprotoparser"

local game_proto = {}

local types = [[

.package {
	type 0 : integer
	session 1 : integer
}

.appearance {
	name 1 : string
	race 2 : string
	class 3 : string
}

.overview {
	id 0 : integer
	appearance 1 : appearance
	map 2 : string
	level 3 : integer
}

.position {
	x 0 : integer
	y 1 : integer
	z 2 : integer
	o 3 : integer
}

.detail {
	pos 0 : position
	exp 1 : integer
}

.character {
	overview 0 : overview
	detail 1 : detail
}

]]

local c2s = [[
character_list 0 {
	response {
		character 0 : *overview(id)
	}
}

character_create 1 {
	request {
		character 0 : appearance
	}

	response {
		character 0 : overview
		errno 1 : integer
	}
}

character_pick 2 {
	request {
		id 0 : integer
	}

	response {
		character 0 : character
		errno 1 : integer
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
