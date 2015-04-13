local sparser = require "sprotoparser"

local game_proto = {}

local types = [[

.package {
	type 0 : integer
	session 1 : integer
}

.general {
	name 0 : string
	race 1 : string
	class 2 : string
	map 3 : string
}

.position {
	x 0 : integer
	y 1 : integer
	z 2 : integer
	o 3 : integer
}

.movement {
	mode 0 : integer
	pos 1 : position
}

.attribute {
	hp 0 : integer
	level 1 : integer
	exp 2 : integer
}

.character_agent {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute
	movement 3 : movement
}

.character {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute
	movement 3 : movement
}

.attribute_overview {
	level 0 : integer
}

.character_overview {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute_overview
}

.attribute_aoi {
	hp 0 : integer
	level 1 : integer
}

.character_aoi {
	id 0 : integer
	general 1 : general
	attribute 2 : attribute_aoi
	movement 3 : movement
}

]]

local c2s = [[
character_list 0 {
	response {
		character 0 : *character_overview(id)
	}
}

character_create 1 {
	request {
		character 0 : general
	}

	response {
		character 0 : character_overview
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
