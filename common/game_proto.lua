local sparser = require "sprotoparser"

local game_proto = {}

game_proto.c2s = sparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

.character {
	id 0 : integer
	name 1 : string
	race 2 : integer
	class 3 : integer
}

character_list 0 {
	response {
		character 0 : *character
	}
}

character_create 1 {
	request {
		character 0 : character
	}

	response {
		character 0 : character
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
