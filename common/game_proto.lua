local sparser = require "sprotoparser"

local game_proto = {}

game_proto.c2s = sparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

character_list 0 {
	request {
	}

	response {
		character 0 : *integer
	}
}

character_create 1 {
	request {
		name 0 : string
		race 1 : integer
		class 2 : integer
	}

	response {
		errno 0 : integer
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
