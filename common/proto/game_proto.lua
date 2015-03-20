local sparser = require "sprotoparser"

local game_proto = {}

game_proto.c2s = sparser.parse [[
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

]]

game_proto.s2c = sparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

]]

return game_proto
